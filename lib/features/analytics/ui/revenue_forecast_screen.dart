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

class RevenueForecastScreen extends StatelessWidget {
  const RevenueForecastScreen({super.key});

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
      appBar: AppBar(title: const Text('Revenue Forecast')),
      body: StreamBuilder<List<RequestModel>>(
        stream: _allRequests(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading forecast...');
          }
          final data = snap.data ?? const [];
          if (data.isEmpty) {
            return const EmptyState(
              icon: Icons.trending_up_rounded,
              title: 'No forecast yet',
              message: 'Add requests to estimate revenue.',
            );
          }

          final out = data.where((r) => !r.inScope).toList();
          final totalExtra = out.fold<int>(
            0,
            (sum, r) => sum + (r.estimatedCost ?? 0),
          );
          final averageMonthly = (totalExtra / 3).round();
          final projected = averageMonthly * 6;

          return Responsive.centeredContent(
            context,
            child: ListView(
              padding: EdgeInsets.only(
                bottom: Responsive.bottomSafeSpace(context, extra: 24),
              ),
              children: [
                Text('Forecast', style: AppText.h2(context)),
                const SizedBox(height: 12),
                _ForecastRow(
                  label: 'Last 90 days (extra)',
                  value: Formatters.currency(totalExtra),
                ),
                _ForecastRow(
                  label: 'Avg monthly',
                  value: Formatters.currency(averageMonthly),
                ),
                _ForecastRow(
                  label: 'Projected 6 months',
                  value: Formatters.currency(projected),
                ),
                const SizedBox(height: 12),
                Text(
                  'This forecast is a simple projection based on the last 90 days of '
                  'out-of-scope requests. Add more data for better accuracy.',
                  style: AppText.bodyMuted(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ForecastRow extends StatelessWidget {
  final String label;
  final String value;

  const _ForecastRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body(context))),
          Text(value, style: AppText.title(context)),
        ],
      ),
    );
  }
}
