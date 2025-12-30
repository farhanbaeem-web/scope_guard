import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';

class BillingInvoicesScreen extends StatelessWidget {
  const BillingInvoicesScreen({super.key});

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
      appBar: AppBar(title: const Text('Invoices')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading invoices...');
          }
          if (snap.hasError) {
            return const ErrorState(message: 'Unable to load invoices.');
          }
          final data = snap.data?.data() ?? {};
          final invoices = (data['invoices'] as List<dynamic>? ?? [])
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

          if (invoices.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'No invoices yet',
              message: 'Invoices will appear once billing is active.',
            );
          }

          return ListView.builder(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: Responsive.bottomSafeSpace(context, extra: 24),
              top: 12,
            ),
            itemCount: invoices.length,
            itemBuilder: (context, i) {
              final inv = invoices[i];
              return ListTile(
                title: Text((inv['month'] ?? '').toString()),
                subtitle: Text((inv['status'] ?? '').toString()),
                trailing: Text(
                  (inv['amount'] ?? '').toString(),
                  style: AppText.title(context),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
