import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../requests/data/request_model.dart';
import '../../requests/logic/requests_service.dart';
import '../../requests/ui/widgets/request_tile.dart';
import '../data/client_model.dart';
import '../logic/clients_service.dart';
import 'widgets/client_card.dart';

class ClientsListScreen extends StatefulWidget {
  const ClientsListScreen({super.key});

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends State<ClientsListScreen> {
  String _query = '';
  bool _showRiskyOnly = false;
  _ClientSort _sort = _ClientSort.newest;
  ClientModel? _selected;
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ClientModel>>(
      stream: ClientsService.instance.watchClients(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState(message: 'Loading clients...');
        }
        if (snapshot.hasError) {
          return const EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Unable to load clients',
            message: 'Please check your connection and try again.',
          );
        }

        final clients = snapshot.data ?? const [];
        final isDesktop = Responsive.isDesktop(context);

        final filtered = clients.where((c) {
          if (_showRiskyOnly && !c.risky) return false;
          if (_query.isEmpty) return true;

          final q = _query.toLowerCase();
          return c.name.toLowerCase().contains(q) ||
              c.project.toLowerCase().contains(q);
        }).toList();

        final sorted = [...filtered];
        sorted.sort((a, b) {
          switch (_sort) {
            case _ClientSort.newest:
              return b.createdAt.compareTo(a.createdAt);
            case _ClientSort.oldest:
              return a.createdAt.compareTo(b.createdAt);
            case _ClientSort.nameAsc:
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            case _ClientSort.nameDesc:
              return b.name.toLowerCase().compareTo(a.name.toLowerCase());
            case _ClientSort.riskyFirst:
              final riskCompare =
                  (b.risky ? 1 : 0).compareTo(a.risky ? 1 : 0);
              if (riskCompare != 0) return riskCompare;
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }
        });

        final listColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Clients', style: AppText.h2(context))),
                DropdownButtonHideUnderline(
                  child: DropdownButton<_ClientSort>(
                    value: _sort,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _sort = value);
                    },
                    items: _ClientSort.values
                        .map(
                          (sort) => DropdownMenuItem(
                            value: sort,
                            child: Text(sort.label),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => context.push('/clients/add'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Client'),
                ),
              ],
            ).animate().fadeIn(duration: 200.ms).slideY(begin: .03, end: 0),

            SizedBox(height: Responsive.gap(context, 1)),

            _StatsBar(
              total: clients.length,
              risky: clients.where((c) => c.risky).length,
            ).animate().fadeIn(delay: 80.ms).slideY(begin: .03, end: 0),

            SizedBox(height: Responsive.gap(context, 1)),

            _Filters(
              controller: _queryController,
              query: _query,
              riskyOnly: _showRiskyOnly,
              onQuery: (v) => setState(() => _query = v),
              onRiskyToggle: (v) => setState(() => _showRiskyOnly = v),
            ).animate().fadeIn(delay: 140.ms).slideY(begin: .03, end: 0),

            if (_query.isNotEmpty || _showRiskyOnly) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _query = '';
                      _showRiskyOnly = false;
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
              child: sorted.isEmpty
                  ? EmptyState(
                      icon: Icons.group_rounded,
                      title: 'No clients found',
                      message: _query.isEmpty
                          ? 'Add your first client to start tracking scope.'
                          : 'Try adjusting your search or filters.',
                      action: ElevatedButton.icon(
                        onPressed: () => context.push('/clients/add'),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Client'),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => setState(() {}),
                      child: Scrollbar(
                        controller: _listController,
                        child: ListView.builder(
                          controller: _listController,
                          padding: EdgeInsets.zero,
                          itemCount: sorted.length,
                          itemBuilder: (context, i) {
                            final c = sorted[i];
                            return ClientCard(
                                  name: c.name,
                                  project: c.project,
                                  contractType: c.contractType,
                                  risky: c.risky,
                                  outOfScopeCount: c.outOfScopeCount,
                                  onTap: () {
                                    if (isDesktop) {
                                      setState(() => _selected = c);
                                    } else {
                                      context.push(
                                        '/clients/${c.id}',
                                        extra: c,
                                      );
                                    }
                                  },
                                )
                                .animate(delay: (40 * i).ms)
                                .fadeIn()
                                .slideX(begin: .03, end: 0);
                          },
                        ),
                      ),
                    ),
            ),
          ],
        );

        if (!isDesktop) return listColumn;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: listColumn),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _ClientPreview(
                client: _selected,
                onOpen: (client) =>
                    context.push('/clients/${client.id}', extra: client),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatsBar extends StatelessWidget {
  final int total;
  final int risky;

  const _StatsBar({required this.total, required this.risky});

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
          _MiniStat(label: 'Clients', value: '$total'),
          const SizedBox(width: 12),
          _MiniStat(label: 'Risky', value: '$risky', accent: AppColors.warning),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? accent;

  const _MiniStat({required this.label, required this.value, this.accent});

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.primary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.small(context)),
            const SizedBox(height: 4),
            Text(value, style: AppText.title(context)),
          ],
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final bool riskyOnly;
  final ValueChanged<String> onQuery;
  final ValueChanged<bool> onRiskyToggle;

  const _Filters({
    required this.controller,
    required this.query,
    required this.riskyOnly,
    required this.onQuery,
    required this.onRiskyToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          controller: controller,
          label: 'Search clients',
          icon: Icons.search_rounded,
          onChanged: onQuery,
          showClear: query.isNotEmpty,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: riskyOnly,
          onChanged: onRiskyToggle,
          title: Text('Show risky only', style: AppText.title(context)),
        ),
      ],
    );
  }
}

enum _ClientSort {
  newest,
  oldest,
  nameAsc,
  nameDesc,
  riskyFirst,
}

extension _ClientSortLabel on _ClientSort {
  String get label {
    switch (this) {
      case _ClientSort.newest:
        return 'Newest';
      case _ClientSort.oldest:
        return 'Oldest';
      case _ClientSort.nameAsc:
        return 'Name A-Z';
      case _ClientSort.nameDesc:
        return 'Name Z-A';
      case _ClientSort.riskyFirst:
        return 'Risky first';
    }
  }
}

class _ClientPreview extends StatelessWidget {
  final ClientModel? client;
  final ValueChanged<ClientModel> onOpen;

  const _ClientPreview({required this.client, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (client == null) {
      return const EmptyState(
        icon: Icons.business_center_rounded,
        title: 'Select a client',
        message: 'Choose a client to see details and recent requests.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Client detail',
          subtitle: client!.project,
          action: TextButton(
            onPressed: () => onOpen(client!),
            child: const Text('Open full view'),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(Responsive.radius(context)),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(client!.name, style: AppText.h3(context)),
              const SizedBox(height: 6),
              Text(client!.project, style: AppText.bodyMuted(context)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoPill(label: 'Contract', value: client!.contractType),
                  if (client!.risky) ...[
                    const SizedBox(width: 8),
                    _InfoPill(
                      label: 'Risk',
                      value: 'High',
                      color: AppColors.warning,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionHeader(title: 'Recent requests'),
        _RecentRequests(clientId: client!.id),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoPill({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$label: $value',
        style: AppText.chip(context).copyWith(color: accent),
      ),
    );
  }
}

class _RecentRequests extends StatelessWidget {
  final String clientId;

  const _RecentRequests({required this.clientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RequestModel>>(
      stream: RequestsService.instance.watchRequests(clientId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingState(message: 'Loading requests...');
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.assignment_rounded,
            title: 'No requests yet',
            message: 'Requests will show here as they are added.',
          );
        }

        final top = items.take(4).toList();
        return Column(
          children: top
              .map(
                (r) => RequestTile(
                      request: r,
                      onTap: () => context.push(
                        '/clients/$clientId/requests/${r.id}',
                      ),
                    )
                    .animate(delay: 30.ms)
                    .fadeIn()
                    .slideY(begin: .02, end: 0),
              )
              .toList(),
        );
      },
    );
  }
}
