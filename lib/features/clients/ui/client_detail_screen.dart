import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/kpi_card.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../reports/ui/report_screen.dart';
import '../../reports/logic/reports_service.dart';
import '../../reports/data/report_model.dart';
import '../../requests/data/request_model.dart';
import '../../requests/logic/requests_service.dart';
import '../../requests/ui/widgets/request_tile.dart';
import '../data/client_model.dart';
import '../logic/clients_service.dart';

class ClientDetailScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const ClientDetailScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  String _query = '';
  _Filter _filter = _Filter.all;
  late final TextEditingController _queryController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> _confirmDeleteRequest() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete request?'),
        content: const Text(
          'This will permanently remove the request.',
        ),
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ClientModel?>(
      stream: ClientsService.instance.watchClient(widget.clientId),
      builder: (context, clientSnap) {
        if (clientSnap.connectionState == ConnectionState.waiting) {
          return const LoadingState(message: 'Loading client...');
        }
        if (clientSnap.hasError) {
          return const ErrorState(message: 'Unable to load client details.');
        }

        final client = clientSnap.data;
        if (client == null) {
          return const EmptyState(
            icon: Icons.business_center_rounded,
            title: 'Client not found',
            message: 'This client may have been removed.',
          );
        }

        return StreamBuilder<List<RequestModel>>(
          stream: RequestsService.instance.watchRequests(widget.clientId),
          builder: (context, reqSnap) {
            if (reqSnap.connectionState == ConnectionState.waiting) {
              return const LoadingState(message: 'Loading requests...');
            }
            if (reqSnap.hasError) {
              return const ErrorState(
                message: 'Unable to load requests right now.',
              );
            }

            final requests = reqSnap.data ?? const [];
            final stats = _computeStats(requests);
            final filtered = _applyFilter(requests);

            return RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: Scrollbar(
                controller: _scrollController,
                child: ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: Responsive.bottomSafeSpace(context, extra: 24),
                    top: 12,
                  ),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(client.name, style: AppText.h2(context)),
                        ),
                        IconButton(
                          tooltip: 'Copy client ID',
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: widget.clientId),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Client ID copied')),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => context.push(
                            '/clients/${widget.clientId}/requests/add',
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Request'),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 220.ms)
                        .slideY(begin: .03, end: 0),
                    SizedBox(height: Responsive.gap(context, 2)),
                    SectionHeader(
                      title: 'Overview',
                      subtitle: client.project.isEmpty
                          ? 'Client summary and performance'
                          : client.project,
                    ),
                    _OverviewCard(client: client).animate().fadeIn(delay: 60.ms),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => context.push(
                            '/clients/${widget.clientId}/activity?name=${Uri.encodeComponent(client.name)}',
                          ),
                          icon: const Icon(Icons.timeline_rounded),
                          label: const Text('Activity'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.push(
                            '/clients/${widget.clientId}/board?name=${Uri.encodeComponent(client.name)}',
                          ),
                          icon: const Icon(Icons.view_kanban_rounded),
                          label: const Text('Board'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.push(
                            '/clients/${widget.clientId}/notes',
                          ),
                          icon: const Icon(Icons.notes_rounded),
                          label: const Text('Notes'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.push(
                            '/clients/${widget.clientId}/contract?name=${Uri.encodeComponent(client.name)}',
                          ),
                          icon: const Icon(Icons.description_rounded),
                          label: const Text('Contract'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.push(
                            '/clients/${widget.clientId}/reports?name=${Uri.encodeComponent(client.name)}',
                          ),
                          icon: const Icon(Icons.picture_as_pdf_rounded),
                          label: const Text('Reports'),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.gap(context, 2)),
                    SectionHeader(
                      title: 'KPIs',
                      subtitle: 'Scope health and revenue signals',
                      action: FilledButton.icon(
                        onPressed: stats.total == 0
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ScopeReportScreen(
                                      clientId: widget.clientId,
                                      clientName: client.name,
                                      requests: requests,
                                    ),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        label: const Text('Generate report'),
                      ),
                    ),
                    _KpiRow(stats: stats).animate().fadeIn(delay: 90.ms),
                    SizedBox(height: Responsive.gap(context, 2)),
                    SectionHeader(
                      title: 'Requests',
                      subtitle: 'Filter and review scope changes',
                    ),
                    _FilterBar(
                      controller: _queryController,
                      filter: _filter,
                      onChanged: (f) => setState(() => _filter = f),
                      query: _query,
                      onQuery: (v) => setState(() => _query = v),
                    )
                        .animate()
                        .fadeIn(delay: 120.ms)
                        .slideY(begin: .02, end: 0),
                    if (_query.isNotEmpty || _filter != _Filter.all) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _query = '';
                              _filter = _Filter.all;
                              _queryController.clear();
                            });
                          },
                          icon: const Icon(Icons.filter_alt_off_rounded),
                          label: const Text('Clear filters'),
                        ),
                      ),
                    ],
                    SizedBox(height: Responsive.gap(context, 1)),
                    if (filtered.isEmpty)
                      EmptyState(
                        icon: Icons.assignment_rounded,
                        title:
                            requests.isEmpty ? 'No requests yet' : 'No matches',
                        message: requests.isEmpty
                            ? 'Add requests to track scope creep for this client.'
                            : 'Try adjusting your filters or search.',
                        action: ElevatedButton.icon(
                          onPressed: () => context.push(
                            '/clients/${widget.clientId}/requests/add',
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Request'),
                        ),
                      )
                    else
                      ...filtered.map(
                        (r) => RequestTile(
                          request: r,
                          onTap: () => context.push(
                            '/clients/${widget.clientId}/requests/${r.id}',
                          ),
                          onToggleScope: (newInScope) async {
                            await RequestsService.instance.toggleScope(
                              clientId: widget.clientId,
                              requestId: r.id,
                              inScope: newInScope,
                            );
                          },
                          onDelete: () async {
                            final confirmed = await _confirmDeleteRequest();
                            if (!confirmed) return;
                            await RequestsService.instance.deleteRequest(
                              clientId: widget.clientId,
                              requestId: r.id,
                            );
                          },
                        )
                            .animate(delay: 40.ms)
                            .fadeIn()
                            .slideY(begin: .03, end: 0),
                      ),
                    SizedBox(height: Responsive.gap(context, 2)),
                    SectionHeader(
                      title: 'Reports',
                      subtitle: 'Recently generated scope PDFs',
                    ),
                    _ReportsPanel(clientId: widget.clientId),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  _Stats _computeStats(List<RequestModel> list) {
    final out = list.where((r) => !r.inScope).toList();
    final extra = out.fold<int>(0, (s, r) => s + (r.estimatedCost ?? 0));
    return _Stats(
      total: list.length,
      outOfScopeCount: out.length,
      extraEarned: extra,
    );
  }

  List<RequestModel> _applyFilter(List<RequestModel> input) {
    Iterable<RequestModel> list = input;

    if (_filter == _Filter.inScope) {
      list = list.where((r) => r.inScope);
    } else if (_filter == _Filter.outOfScope) {
      list = list.where((r) => !r.inScope);
    }

    final q = _query.toLowerCase().trim();
    if (q.isNotEmpty) {
      list = list.where(
        (r) =>
            r.title.toLowerCase().contains(q) ||
            r.description.toLowerCase().contains(q),
      );
    }

    return list.toList();
  }

}

enum _Filter { all, inScope, outOfScope }

class _Stats {
  final int total;
  final int outOfScopeCount;
  final int extraEarned;

  const _Stats({
    required this.total,
    required this.outOfScopeCount,
    required this.extraEarned,
  });
}

class _OverviewCard extends StatelessWidget {
  final ClientModel client;

  const _OverviewCard({required this.client});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Responsive.radius(context)),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.business_center_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.name, style: AppText.title(context)),
                    Text(client.project, style: AppText.small(context)),
                  ],
                ),
              ),
              if (client.risky)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.32)),
                  ),
                  child: Text(
                    'Risky',
                    style: AppText.chip(context).copyWith(color: AppColors.warning),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _InfoChip(label: 'Contract', value: client.contractType),
              _InfoChip(
                label: 'Created',
                value: Formatters.shortDate(client.createdAt),
              ),
            ],
          ),
          if (client.notes != null && client.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Notes', style: AppText.small(context)),
            const SizedBox(height: 4),
            Text(client.notes!, style: AppText.bodyMuted(context)),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label: $value',
        style: AppText.chip(context).copyWith(color: AppColors.subtext),
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  final _Stats stats;

  const _KpiRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final gap = Responsive.gap(context, 1);
    final cols = Responsive.value<int>(
      context: context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );

    final cards = [
      KpiCard(
        label: 'Requests',
        value: '${stats.total}',
        icon: Icons.list_alt_rounded,
        accent: AppColors.info,
      ),
      KpiCard(
        label: 'Out of scope',
        value: '${stats.outOfScopeCount}',
        icon: Icons.warning_rounded,
        accent: AppColors.warning,
      ),
      KpiCard(
        label: 'Extra earned',
        value: Formatters.currency(stats.extraEarned),
        icon: Icons.attach_money_rounded,
        accent: AppColors.success,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemWidth = (width - (gap * (cols - 1))) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards)
              SizedBox(width: itemWidth, child: card),
          ],
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  final TextEditingController controller;
  final _Filter filter;
  final ValueChanged<_Filter> onChanged;
  final String query;
  final ValueChanged<String> onQuery;

  const _FilterBar({
    required this.controller,
    required this.filter,
    required this.onChanged,
    required this.query,
    required this.onQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          controller: controller,
          label: 'Search requests',
          icon: Icons.search_rounded,
          showClear: query.isNotEmpty,
          onChanged: onQuery,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            for (final f in _Filter.values)
              ChoiceChip(
                label: Text(
                  f == _Filter.all
                      ? 'All'
                      : f == _Filter.inScope
                          ? 'In scope'
                          : 'Out of scope',
                ),
                selected: filter == f,
                onSelected: (_) => onChanged(f),
              ),
          ],
        ),
      ],
    );
  }
}

class _ReportsPanel extends StatelessWidget {
  final String clientId;

  const _ReportsPanel({required this.clientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReportModel>>(
      stream: ReportsService.instance.watchReports(clientId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingState(message: 'Loading reports...');
        }
        final reports = snap.data ?? const [];
        if (reports.isEmpty) {
          return const EmptyState(
            icon: Icons.picture_as_pdf_rounded,
            title: 'No reports yet',
            message: 'Generate a report to track scope change history.',
          );
        }

        return Column(
          children: reports.map((r) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(Responsive.radius(context)),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title, style: AppText.title(context)),
                        const SizedBox(height: 4),
                        Text(
                          '${r.outOfScopeCount} out of scope | ${Formatters.currency(r.totalExtra)}',
                          style: AppText.small(context),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.shortDate(r.createdAt),
                    style: AppText.small(context),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
