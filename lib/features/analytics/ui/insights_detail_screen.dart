import 'dart:async';

import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../requests/data/request_model.dart';
import '../../requests/logic/requests_service.dart';

class InsightsDetailScreen extends StatelessWidget {
  const InsightsDetailScreen({super.key});

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
        return merged;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights Detail')),
      body: StreamBuilder<List<RequestModel>>(
        stream: _allRequests(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading insights...');
          }
          final data = snap.data ?? const [];
          if (data.isEmpty) {
            return const EmptyState(
              icon: Icons.insights_rounded,
              title: 'No insights yet',
              message: 'Add requests to unlock deeper insights.',
            );
          }

          final out = data.where((r) => !r.inScope).toList();
          final totalExtra = out.fold<int>(
            0,
            (sum, r) => sum + (r.estimatedCost ?? 0),
          );
          final ratio = data.isEmpty ? 0 : out.length / data.length;

          return Responsive.centeredContent(
            context,
            child: ListView(
              padding: EdgeInsets.only(
                bottom: Responsive.bottomSafeSpace(context, extra: 24),
              ),
              children: [
                Text('Insights', style: AppText.h2(context)),
                const SizedBox(height: 12),
                _InsightCard(
                  title: 'Out-of-scope ratio',
                  value: '${(ratio * 100).toStringAsFixed(1)}%',
                  subtitle: '${out.length} of ${data.length} requests',
                ),
                _InsightCard(
                  title: 'Total extra earned',
                  value: Formatters.currency(totalExtra),
                  subtitle: 'Across all clients',
                ),
                _InsightCard(
                  title: 'Average extra per request',
                  value: out.isEmpty
                      ? Formatters.currency(0)
                      : Formatters.currency(
                          totalExtra / out.length,
                          decimalDigits: 0,
                        ),
                  subtitle: 'Out-of-scope only',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _InsightCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.small(context)),
          const SizedBox(height: 6),
          Text(value, style: AppText.h3(context)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppText.bodyMuted(context)),
        ],
      ),
    );
  }
}
