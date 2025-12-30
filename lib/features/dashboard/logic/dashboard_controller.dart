import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardSummary {
  final int clientsCount;
  final int requestsCount;
  final int outOfScopeCount;
  final int outOfScopeTotal;

  const DashboardSummary({
    required this.clientsCount,
    required this.requestsCount,
    required this.outOfScopeCount,
    required this.outOfScopeTotal,
  });

  static const empty = DashboardSummary(
    clientsCount: 0,
    requestsCount: 0,
    outOfScopeCount: 0,
    outOfScopeTotal: 0,
  );
}

class DashboardController {
  DashboardController._();
  static final DashboardController instance = DashboardController._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('User not authenticated');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _clientsRef =>
      _db.collection('users').doc(_uid).collection('clients');

  /// Real-time summary:
  /// - Watches clients stream
  /// - Aggregates requests (client-by-client) using parallel reads
  ///
  /// Free-tier friendly.
  /// If you later need speed at scale, we can maintain summary docs per user.
  Stream<DashboardSummary> watchSummary() async* {
    await for (final clientsSnap in _clientsRef.snapshots()) {
      final clients = clientsSnap.docs;
      final clientsCount = clients.length;

      if (clients.isEmpty) {
        yield DashboardSummary.empty;
        continue;
      }

      // Fetch requests for each client in parallel (much faster than sequential).
      final futures = clients.map((c) async {
        final reqSnap = await _clientsRef
            .doc(c.id)
            .collection('requests')
            .get();

        int requestsCount = reqSnap.docs.length;
        int outOfScopeCount = 0;
        int outOfScopeTotal = 0;

        for (final r in reqSnap.docs) {
          final data = r.data();
          final inScope = (data['inScope'] as bool?) ?? true;
          if (!inScope) {
            outOfScopeCount += 1;
            final cost = data['estimatedCost'];
            if (cost is int) outOfScopeTotal += cost;
            if (cost is num) outOfScopeTotal += cost.toInt();
          }
        }

        return _Partial(
          requestsCount: requestsCount,
          outOfScopeCount: outOfScopeCount,
          outOfScopeTotal: outOfScopeTotal,
        );
      }).toList();

      final parts = await Future.wait(futures);

      final totalRequests = parts.fold<int>(
        0,
        (sum, p) => sum + p.requestsCount,
      );
      final totalOut = parts.fold<int>(0, (sum, p) => sum + p.outOfScopeCount);
      final totalOutMoney = parts.fold<int>(
        0,
        (sum, p) => sum + p.outOfScopeTotal,
      );

      yield DashboardSummary(
        clientsCount: clientsCount,
        requestsCount: totalRequests,
        outOfScopeCount: totalOut,
        outOfScopeTotal: totalOutMoney,
      );
    }
  }

  /// Recent clients stream (for dashboard list)
  Stream<QuerySnapshot<Map<String, dynamic>>> watchRecentClients({
    int limit = 6,
  }) {
    return _clientsRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }
}

class _Partial {
  final int requestsCount;
  final int outOfScopeCount;
  final int outOfScopeTotal;

  const _Partial({
    required this.requestsCount,
    required this.outOfScopeCount,
    required this.outOfScopeTotal,
  });
}
