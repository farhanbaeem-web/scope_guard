// lib/features/clients/logic/clients_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/client_model.dart';
import '../../activity/data/activity_model.dart';
import '../../activity/logic/activity_service.dart';

class ClientsService {
  ClientsService._();
  static final ClientsService instance = ClientsService._();

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
      _db.collection('users').doc(_uid).collection('clients');

  Stream<ClientModel?> watchClient(String clientId) {
    return _ref.doc(clientId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ClientModel.fromDoc(doc);
    });
  }

  /// Watch all clients (real-time)
  Stream<List<ClientModel>> watchClients() {
    return _ref
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ClientModel.fromDoc).toList());
  }

  /// Add a new client (basic)
  Future<void> addClient({
    required String name,
    required String project,
    required String contractType,
    String? notes,
    bool risky = false,
  }) async {
    final model = ClientModel(
      id: '',
      name: name.trim(),
      project: project.trim(),
      contractType: contractType.trim(),
      createdAt: DateTime.now(),
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
      risky: risky,
    );

    final doc = await _ref.add(model.toMap(serverTimestamp: true));
    await ActivityService.instance.log(
      title: 'Client created',
      detail: '${model.name} added to your workspace.',
      type: ActivityType.success,
      clientId: doc.id,
    );
  }

  /// Update basic client fields (used by edit screen later)
  Future<void> updateClient({
    required String clientId,
    String? name,
    String? project,
    String? contractType,
    String? notes,
  }) async {
    final data = <String, dynamic>{};

    if (name != null) data['name'] = name.trim();
    if (project != null) data['project'] = project.trim();
    if (contractType != null) data['contractType'] = contractType.trim();
    if (notes != null) data['notes'] = notes.trim();

    if (data.isEmpty) return;

    await _ref.doc(clientId).update(data);
    await ActivityService.instance.log(
      title: 'Client updated',
      detail: 'Client details were edited.',
      type: ActivityType.info,
      clientId: clientId,
    );
  }

  /// Mark/unmark a client as risky (premium feature)
  Future<void> setRisky({required String clientId, required bool risky}) async {
    await _ref.doc(clientId).update({'risky': risky});
    await ActivityService.instance.log(
      title: risky ? 'Risk flag added' : 'Risk flag removed',
      detail: risky ? 'Client marked as risky.' : 'Client unmarked as risky.',
      type: risky ? ActivityType.warning : ActivityType.info,
      clientId: clientId,
    );
  }

  /// Update counters (called after request changes)
  Future<void> updateCounters({
    required String clientId,
    int? totalRequests,
    int? outOfScopeCount,
  }) async {
    final data = <String, dynamic>{};

    if (totalRequests != null) data['totalRequests'] = totalRequests;
    if (outOfScopeCount != null) data['outOfScopeCount'] = outOfScopeCount;

    if (data.isEmpty) return;

    await _ref.doc(clientId).update(data);
  }

  Future<bool> hasClients() async {
    final snap = await _ref.limit(1).get();
    return snap.docs.isNotEmpty;
  }
}
