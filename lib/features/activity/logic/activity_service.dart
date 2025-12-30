import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/activity_model.dart';

class ActivityService {
  ActivityService._();
  static final ActivityService instance = ActivityService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User not authenticated');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _ref =>
      _db.collection('users').doc(_uid).collection('activity');

  Stream<List<ActivityModel>> watchActivity() {
    return _ref
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ActivityModel.fromDoc).toList());
  }

  Future<void> log({
    required String title,
    required String detail,
    ActivityType type = ActivityType.info,
    String? clientId,
    String? requestId,
  }) async {
    final model = ActivityModel(
      id: '',
      title: title,
      detail: detail,
      type: type,
      createdAt: DateTime.now(),
      clientId: clientId,
      requestId: requestId,
    );
    await _ref.add(model.toMap(serverTimestamp: true));
  }

  Future<void> delete(String id) => _ref.doc(id).delete();

  Future<void> clearAll() async {
    final snap = await _ref.get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }
}
