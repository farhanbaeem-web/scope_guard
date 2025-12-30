import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../data/request_model.dart';

class RequestDetailScreen extends StatelessWidget {
  final String clientId;
  final String requestId;

  const RequestDetailScreen({
    super.key,
    required this.clientId,
    required this.requestId,
  });

  Stream<DocumentSnapshot<Map<String, dynamic>>> _stream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('clients')
        .doc(clientId)
        .collection('requests')
        .doc(requestId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Detail'),
        actions: [
          IconButton(
            tooltip: 'Copy request ID',
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: requestId),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Request ID copied')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading request...');
          }
          if (snap.hasError) {
            return const ErrorState(message: 'Unable to load request.');
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const EmptyState(
              icon: Icons.assignment_rounded,
              title: 'Request not found',
              message: 'This request may have been removed.',
            );
          }

          final request = RequestModel.fromDoc(snap.data!);
          final status = request.approvalStatus;
          final statusColor = status == 'approved'
              ? AppColors.success
              : status == 'rejected'
                  ? AppColors.danger
                  : status == 'pending'
                      ? AppColors.warning
                      : AppColors.subtext;

          return Responsive.centeredContent(
            context,
            child: ListView(
              padding: EdgeInsets.only(
                bottom: Responsive.bottomSafeSpace(context, extra: 24),
              ),
              children: [
                Text(request.title, style: AppText.h2(context)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: AppText.chip(context).copyWith(color: statusColor),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: request.inScope
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: (request.inScope
                                  ? AppColors.success
                                  : AppColors.warning)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        request.inScope ? 'IN SCOPE' : 'OUT OF SCOPE',
                        style: AppText.chip(context).copyWith(
                          color: request.inScope
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(request.description, style: AppText.body(context)),
                const SizedBox(height: 16),
                if (request.estimatedCost != null)
                  _DetailRow(
                    label: 'Estimated cost',
                    value: Formatters.currency(request.estimatedCost!),
                  ),
                _DetailRow(
                  label: 'Created',
                  value: Formatters.dateTime(request.createdAt),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.push(
                        '/clients/$clientId/requests/$requestId/edit',
                      ),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit request'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.push(
                        '/clients/$clientId/requests/$requestId/approval',
                      ),
                      icon: const Icon(Icons.rule_rounded),
                      label: const Text('Approval'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.small(context))),
          Text(value, style: AppText.title(context)),
        ],
      ),
    );
  }
}
