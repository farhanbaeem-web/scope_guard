import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/request_model.dart';
import '../../activity/data/activity_model.dart';
import '../../activity/logic/activity_service.dart';

class RequestsService {
  RequestsService._();
  static final RequestsService instance = RequestsService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User not authenticated');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _ref(String clientId) {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('clients')
        .doc(clientId)
        .collection('requests');
  }

  /// Watch requests for a client (real-time)
  Stream<List<RequestModel>> watchRequests(String clientId) {
    return _ref(clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => RequestModel.fromDoc(d)).toList());
  }

  /// Add new request
  Future<void> addRequest({
    required String clientId,
    required String title,
    required String description,
    required bool inScope,
    int? estimatedCost,
  }) async {
    final model = RequestModel(
      id: '',
      title: title,
      description: description,
      inScope: inScope,
      approvalStatus: inScope ? 'none' : 'pending',
      estimatedCost: estimatedCost,
      createdAt: DateTime.now(),
    );

    final doc = await _ref(clientId).add(model.toMapWithServerTimestamp());
    await ActivityService.instance.log(
      title: inScope ? 'Request logged' : 'Out-of-scope request',
      detail: title.trim(),
      type: inScope ? ActivityType.info : ActivityType.warning,
      clientId: clientId,
      requestId: doc.id,
    );
  }

  /// Update request (edit screen later)
  Future<void> updateRequest({
    required String clientId,
    required String requestId,
    String? title,
    String? description,
    bool? inScope,
    int? estimatedCost,
  }) async {
    final data = <String, dynamic>{};

    if (title != null) data['title'] = title.trim();
    if (description != null) data['description'] = description.trim();
    if (inScope != null) {
      data['inScope'] = inScope;
      data['approvalStatus'] = inScope ? 'none' : 'pending';
    }
    if (estimatedCost != null) data['estimatedCost'] = estimatedCost;

    if (data.isEmpty) return;

    await _ref(clientId).doc(requestId).update(data);
    await ActivityService.instance.log(
      title: 'Request updated',
      detail: 'Request details were edited.',
      type: ActivityType.info,
      clientId: clientId,
      requestId: requestId,
    );
  }

  /// Delete request
  Future<void> deleteRequest({
    required String clientId,
    required String requestId,
  }) async {
    await _ref(clientId).doc(requestId).delete();
    await ActivityService.instance.log(
      title: 'Request deleted',
      detail: 'A request was removed.',
      type: ActivityType.danger,
      clientId: clientId,
      requestId: requestId,
    );
  }

  /// Quick toggle: mark in-scope / out-of-scope
  Future<void> toggleScope({
    required String clientId,
    required String requestId,
    required bool inScope,
  }) async {
    await _ref(clientId).doc(requestId).update({
      'inScope': inScope,
      'approvalStatus': inScope ? 'none' : 'pending',
    });
    await ActivityService.instance.log(
      title: inScope ? 'Marked in scope' : 'Marked out of scope',
      detail: inScope
          ? 'Request moved back into scope.'
          : 'Request marked for extra billing.',
      type: inScope ? ActivityType.info : ActivityType.warning,
      clientId: clientId,
      requestId: requestId,
    );
  }
}
