import 'dart:async';

import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../requests/data/request_model.dart';
import '../../requests/logic/requests_service.dart';
import 'analytics_screen.dart';

/// Streams all requests across all clients, then feeds them into the animated
/// AnalyticsScreen. Keeps the premium UI while centralizing the data plumbing.
class AnalyticsHubScreen extends StatelessWidget {
  const AnalyticsHubScreen({super.key});

  Stream<List<RequestModel>> _allRequests() async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      yield const [];
      return;
    }

    final db = FirebaseFirestore.instance;
    final clientsRef = db.collection('users').doc(user.uid).collection('clients');

    await for (final snap in clientsRef.snapshots()) {
      final docs = snap.docs;
      if (docs.isEmpty) {
        yield const [];
        continue;
      }

      final streams = docs
          .map((c) => RequestsService.instance.watchRequests(c.id))
          .toList();

      yield* StreamZip(streams).map((groups) {
        final merged = <RequestModel>[];
        for (final g in groups) {
          merged.addAll(g);
        }
        merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return merged;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RequestModel>>(
      stream: _allRequests(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingState(message: 'Loading analytics...');
        }
        if (snap.hasError) {
          return const ErrorState(
            message: 'Unable to load analytics right now.',
          );
        }

        final data = snap.data ?? const [];
        if (data.isEmpty) {
          return const EmptyState(
            icon: Icons.auto_graph_rounded,
            title: 'No data yet',
            message: 'Log a few requests to unlock analytics and trends.',
          );
        }

        return AnalyticsScreen(allRequests: data);
      },
    );
  }
}
