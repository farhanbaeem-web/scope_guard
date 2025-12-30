import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';

class ClientActivityScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const ClientActivityScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<ClientActivityScreen> createState() => _ClientActivityScreenState();
}

class _ClientActivityScreenState extends State<ClientActivityScreen> {
  late final ScrollController _scrollController;
  bool _alertsOnly = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('activity')
        .where('clientId', isEqualTo: widget.clientId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Client Activity')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading activity...');
          }
          if (snap.hasError) {
            return const ErrorState(
              message: 'Unable to load activity right now.',
            );
          }
          final allItems = snap.data?.docs ?? const [];
          final items = _alertsOnly
              ? allItems.where((d) {
                  final type = (d.data()['type'] ?? 'info').toString();
                  return type == 'warning' || type == 'danger';
                }).toList()
              : allItems;
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.timeline_rounded,
              title: 'No activity yet',
              message: _alertsOnly
                  ? 'No alert activity for ${widget.clientName} right now.'
                  : 'Events for ${widget.clientName} will appear here as you log updates.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: Scrollbar(
              controller: _scrollController,
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: Responsive.bottomSafeSpace(context, extra: 24),
                  top: 12,
                ),
                itemCount: items.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.clientName,
                              style: AppText.h2(context),
                            ),
                          ),
                          FilterChip(
                            label: const Text('Alerts only'),
                            selected: _alertsOnly,
                            onSelected: (value) =>
                                setState(() => _alertsOnly = value),
                          ),
                        ],
                      ),
                    );
                  }
                  final data = items[i - 1].data();
                  final title = (data['title'] ?? 'Activity').toString();
                  final detail = (data['detail'] ?? '').toString();
                  final type = (data['type'] ?? 'info').toString();
                  final created = data['createdAt'] as Timestamp?;
                  final timestamp = created == null
                      ? 'Just now'
                      : Formatters.relative(created.toDate());
                  final color = type == 'danger'
                      ? AppColors.danger
                      : type == 'warning'
                          ? AppColors.warning
                          : type == 'success'
                              ? AppColors.success
                              : AppColors.info;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: AppText.title(context)),
                              const SizedBox(height: 4),
                              Text(detail, style: AppText.bodyMuted(context)),
                              const SizedBox(height: 4),
                              Text(timestamp, style: AppText.small(context)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
