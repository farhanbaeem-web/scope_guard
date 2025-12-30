import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/report_model.dart';
import '../../activity/data/activity_model.dart';
import '../../activity/logic/activity_service.dart';

class ReportsService {
  ReportsService._();
  static final ReportsService instance = ReportsService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

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
        .collection('reports');
  }

  Stream<List<ReportModel>> watchReports(String clientId) {
    return _ref(clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ReportModel.fromDoc).toList());
  }

  Future<void> addReport({
    required String clientId,
    required String title,
    required int outOfScopeCount,
    required int totalExtra,
  }) async {
    final model = ReportModel(
      id: '',
      title: title,
      outOfScopeCount: outOfScopeCount,
      totalExtra: totalExtra,
      createdAt: DateTime.now(),
    );
    await _ref(clientId).add(model.toMap(serverTimestamp: true));
    await ActivityService.instance.log(
      title: 'Report generated',
      detail: title,
      type: ActivityType.success,
      clientId: clientId,
    );
  }
}
