import 'dart:async';

import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../data/request_model.dart';
import '../logic/requests_service.dart';
import 'widgets/request_tile.dart';

class RequestsHubScreen extends StatefulWidget {
  const RequestsHubScreen({super.key});

  @override
  State<RequestsHubScreen> createState() => _RequestsHubScreenState();
}

class _RequestsHubScreenState extends State<RequestsHubScreen> {
  String _query = '';
  bool _onlyWithCost = false;
  _HubSort _sort = _HubSort.newest;
  late final TextEditingController _queryController;
  late final ScrollController _listController;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
    _listController = ScrollController();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<bool> _confirmDeleteRequest() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete request?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Aggregates out-of-scope requests across all clients (MVP-safe).
  Stream<List<_HubItem>> _hubStream() async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      yield const [];
      return;
    }

    final db = FirebaseFirestore.instance;
    final clientsRef = db
        .collection('users')
        .doc(user.uid)
        .collection('clients');

    await for (final clientsSnap in clientsRef.snapshots()) {
      final clientDocs = clientsSnap.docs;
      if (clientDocs.isEmpty) {
        yield const [];
        continue;
      }

      final streams = clientDocs.map((c) {
        final clientId = c.id;
        final clientName = (c.data()['name'] ?? 'Client').toString();

        return RequestsService.instance.watchRequests(clientId).map((reqs) {
          return reqs
              .where((r) => !r.inScope)
              .map(
                (r) => _HubItem(
                  clientId: clientId,
                  clientName: clientName,
                  request: r,
                ),
              )
              .toList();
        });
      }).toList();

      yield* StreamZip(streams).map((groups) {
        final merged = <_HubItem>[];
        for (final g in groups) {
          merged.addAll(g);
        }
        merged.sort(
          (a, b) => b.request.createdAt.compareTo(a.request.createdAt),
        );
        return merged;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<_HubItem>>(
      stream: _hubStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingState(message: 'Loading requests...');
        }
        if (snap.hasError) {
          return const ErrorState(
            message: 'Unable to load requests right now.',
          );
        }

        final items = snap.data ?? [];

        final filtered = items.where((it) {
          final r = it.request;

          if (_onlyWithCost && (r.estimatedCost ?? 0) <= 0) return false;

          final q = _query.trim().toLowerCase();
          if (q.isEmpty) return true;

          return r.title.toLowerCase().contains(q) ||
              r.description.toLowerCase().contains(q) ||
              it.clientName.toLowerCase().contains(q);
        }).toList();

        final totalExtra = filtered.fold<int>(
          0,
          (sum, it) => sum + (it.request.estimatedCost ?? 0),
        );

        final sorted = [...filtered];
        sorted.sort((a, b) {
          switch (_sort) {
            case _HubSort.newest:
              return b.request.createdAt.compareTo(a.request.createdAt);
            case _HubSort.oldest:
              return a.request.createdAt.compareTo(b.request.createdAt);
            case _HubSort.highestCost:
              return (b.request.estimatedCost ?? 0)
                  .compareTo(a.request.estimatedCost ?? 0);
            case _HubSort.clientName:
              return a.clientName
                  .toLowerCase()
                  .compareTo(b.clientName.toLowerCase());
          }
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 720;
                final title = Text('Requests Hub', style: AppText.h2(context));
                final actions = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.push('/requests/templates'),
                      icon: const Icon(Icons.article_rounded),
                      label: const Text('Templates'),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<_HubSort>(
                        value: _sort,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _sort = value);
                        },
                        items: _HubSort.values
                            .map(
                              (sort) => DropdownMenuItem(
                                value: sort,
                                child: Text(sort.label),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    if (filtered.isNotEmpty)
                      Text(
                        'Potential revenue: ${Formatters.currency(totalExtra)}',
                        style: AppText.subtitle(context),
                      ),
                  ],
                );

                return isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          title,
                          const SizedBox(height: 8),
                          actions,
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: title),
                          actions,
                        ],
                      );
              },
            ).animate().fadeIn(duration: 220.ms).slideY(begin: .03, end: 0),

            SizedBox(height: Responsive.gap(context, 1)),

            _HubStats(
              count: sorted.length,
              totalExtra: totalExtra,
            ).animate().fadeIn(delay: 60.ms).slideY(begin: .03, end: 0),

            SizedBox(height: Responsive.gap(context, 1)),

            _Filters(
              controller: _queryController,
              query: _query,
              onQuery: (v) => setState(() => _query = v),
              onlyWithCost: _onlyWithCost,
              onOnlyWithCost: (v) => setState(() => _onlyWithCost = v),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: .03, end: 0),

            if (_query.isNotEmpty || _onlyWithCost) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _query = '';
                      _onlyWithCost = false;
                      _queryController.clear();
                    });
                  },
                  icon: const Icon(Icons.filter_alt_off_rounded),
                  label: const Text('Clear filters'),
                ),
              ),
            ],

            SizedBox(height: Responsive.gap(context, 1)),

            Expanded(
                child: filtered.isEmpty
                  ? const EmptyState(
                      icon: Icons.assignment_late_rounded,
                      title: 'No out-of-scope requests',
                      message:
                          'When you mark requests as out-of-scope, they will appear here.',
                    )
                  : RefreshIndicator(
                      onRefresh: () async => setState(() {}),
                      child: Scrollbar(
                        controller: _listController,
                        child: ListView.builder(
                          controller: _listController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: sorted.length,
                          itemBuilder: (_, i) {
                            final it = sorted[i];
                            final r = it.request;

                            return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 4,
                                        bottom: 6,
                                      ),
                                      child: Text(
                                        it.clientName,
                                        style: AppText.small(context),
                                      ),
                                    ),
                                    RequestTile(
                                      request: r,
                                      onTap: () => context.push(
                                        '/clients/${it.clientId}/requests/${r.id}',
                                      ),
                                      onToggleScope: (newInScope) async {
                                        await RequestsService.instance.toggleScope(
                                          clientId: it.clientId,
                                          requestId: r.id,
                                          inScope: newInScope,
                                        );
                                      },
                                      onDelete: () async {
                                        final confirmed =
                                            await _confirmDeleteRequest();
                                        if (!confirmed) return;
                                        await RequestsService.instance
                                            .deleteRequest(
                                              clientId: it.clientId,
                                              requestId: r.id,
                                            );
                                      },
                                    ),
                                  ],
                                )
                                .animate(delay: (30 * i).ms)
                                .fadeIn()
                                .slideY(begin: .02, end: 0);
                          },
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}


class _HubItem {
  final String clientId;
  final String clientName;
  final RequestModel request;

  const _HubItem({
    required this.clientId,
    required this.clientName,
    required this.request,
  });
}

enum _HubSort {
  newest,
  oldest,
  highestCost,
  clientName,
}

extension _HubSortLabel on _HubSort {
  String get label {
    switch (this) {
      case _HubSort.newest:
        return 'Newest';
      case _HubSort.oldest:
        return 'Oldest';
      case _HubSort.highestCost:
        return 'Highest cost';
      case _HubSort.clientName:
        return 'Client name';
    }
  }
}


class _HubStats extends StatelessWidget {
  final int count;
  final int totalExtra;

  const _HubStats({required this.count, required this.totalExtra});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Responsive.radius(context)),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MiniStat(
              label: 'Out-of-scope',
              value: '$count',
              icon: Icons.warning_rounded,
              accent: AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MiniStat(
              label: 'Extra earned',
              value: Formatters.currency(totalExtra),
              icon: Icons.attach_money_rounded,
              accent: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.small(context)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppText.title(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onQuery;
  final bool onlyWithCost;
  final ValueChanged<bool> onOnlyWithCost;

  const _Filters({
    required this.controller,
    required this.query,
    required this.onQuery,
    required this.onlyWithCost,
    required this.onOnlyWithCost,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          controller: controller,
          label: 'Search by client, title, description',
          icon: Icons.search_rounded,
          onChanged: onQuery,
          showClear: query.isNotEmpty,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: onlyWithCost,
          onChanged: onOnlyWithCost,
          title: Text('Only requests with cost', style: AppText.title(context)),
          subtitle: Text(
            'Hide items that have no estimate',
            style: AppText.subtitle(context),
          ),
        ),
      ],
    );
  }
}
