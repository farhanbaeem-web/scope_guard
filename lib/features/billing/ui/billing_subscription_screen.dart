import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';

class BillingSubscriptionScreen extends StatelessWidget {
  const BillingSubscriptionScreen({super.key});

  Stream<DocumentSnapshot<Map<String, dynamic>>> _stream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('billing')
        .doc('meta')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading subscription...');
          }
          if (snap.hasError) {
            return const ErrorState(message: 'Unable to load subscription.');
          }
          final data = snap.data?.data() ?? {};
          final plan = (data['plan'] ?? 'Free').toString();
          final seatsUsed = (data['seatsUsed'] ?? 0).toString();
          final seatsTotal = (data['seatsTotal'] ?? 0).toString();

          return Responsive.centeredContent(
            context,
            child: ListView(
              padding: EdgeInsets.only(
                bottom: Responsive.bottomSafeSpace(context, extra: 24),
              ),
              children: [
                Text('Plan details', style: AppText.h2(context)),
                const SizedBox(height: 12),
                _Row(label: 'Current plan', value: plan),
                _Row(label: 'Seats used', value: '$seatsUsed / $seatsTotal'),
                const SizedBox(height: 12),
                Text(
                  'Manage plan upgrades and seat limits in your billing provider.',
                  style: AppText.bodyMuted(context),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.workspace_premium_rounded),
                  label: const Text('Upgrade plan'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
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
