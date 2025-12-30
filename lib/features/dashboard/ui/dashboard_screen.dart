import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/kpi_card.dart';
import '../logic/dashboard_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final ScrollController _scrollController;

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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DashboardSummary>(
      stream: DashboardController.instance.watchSummary(),
      builder: (context, snap) {
        final summary = snap.data ?? DashboardSummary.empty;

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
                top: 12,
                bottom: Responsive.bottomSafeSpace(context, extra: 96),
              ),
              children: [
                Text(
                  'Welcome back',
                  style: AppText.h2(context),
                ).animate().fadeIn(duration: 220.ms).slideY(begin: .04, end: 0),
                SizedBox(height: Responsive.gap(context, 2)),
                _KpiGrid(
                  summary: summary,
                ).animate().fadeIn(delay: 60.ms).slideY(begin: .03, end: 0),
                SizedBox(height: Responsive.gap(context, 2)),
                if (summary.outOfScopeCount > 0)
                  _InsightBanner(
                    count: summary.outOfScopeCount,
                    amount: summary.outOfScopeTotal,
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: .03, end: 0),
                SizedBox(height: Responsive.gap(context, 2)),
                const _QuickActions()
                    .animate()
                    .fadeIn(delay: 140.ms)
                    .slideY(begin: .03, end: 0),
                SizedBox(height: Responsive.gap(context, 2)),
                if (summary.clientsCount == 0)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        Responsive.radius(context),
                      ),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_add_alt_rounded,
                            color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Add your first client to unlock reports and analytics.',
                            style: AppText.body(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => context.go('/clients/add'),
                          child: const Text('Add client'),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 160.ms).slideY(begin: .03, end: 0),
                if (summary.clientsCount == 0)
                  SizedBox(height: Responsive.gap(context, 2)),
                Row(
                  children: [
                    Expanded(
                      child: Text('Recent clients', style: AppText.h3(context)),
                    ),
                    TextButton.icon(
                      onPressed: () => context.go('/clients'),
                      icon: const Icon(Icons.chevron_right_rounded),
                      label: const Text('View all'),
                    ),
                  ],
                ).animate().fadeIn(delay: 180.ms),
                const SizedBox(height: 10),
                const _RecentClients()
                    .animate()
                    .fadeIn(delay: 220.ms)
                    .slideY(begin: .03, end: 0),
              ],
            ),
          ),
        );
      },
    );
  }
}

// KPIs
class _KpiGrid extends StatelessWidget {
  final DashboardSummary summary;
  const _KpiGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isDesktop(context) || Responsive.isWide(context);
    final crossAxisCount = isWide ? 4 : 2;

    final kpis = [
      _KpiData(
        'Clients',
        '${summary.clientsCount}',
        Icons.people_alt_rounded,
        AppColors.primary,
      ),
      _KpiData(
        'Requests',
        '${summary.requestsCount}',
        Icons.list_alt_rounded,
        AppColors.info,
      ),
      _KpiData(
        'Out of scope',
        '${summary.outOfScopeCount}',
        Icons.warning_rounded,
        AppColors.warning,
      ),
      _KpiData(
        'Extra earned',
        Formatters.currency(summary.outOfScopeTotal),
        Icons.attach_money_rounded,
        AppColors.success,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kpis.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isWide ? 1.6 : 1.25,
      ),
      itemBuilder: (_, i) => KpiCard(
            label: kpis[i].title,
            value: kpis[i].value,
            icon: kpis[i].icon,
            accent: kpis[i].accent,
          )
          .animate(delay: (60 * i).ms)
          .fadeIn(duration: 200.ms)
          .scale(begin: const Offset(.98, .98), end: const Offset(1, 1)),
    );
  }
}

class _KpiData {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  const _KpiData(this.title, this.value, this.icon, this.accent);
}

// Alerts / Insight
class _InsightBanner extends StatelessWidget {
  final int count;
  final int amount;

  const _InsightBanner({required this.count, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Responsive.radius(context)),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights_rounded, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$count out-of-scope requests detected - '
              'Potential ${Formatters.currency(amount)} revenue',
              style: AppText.body(context),
            ),
          ),
        ],
      ),
    );
  }
}

// Quick Actions
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final gap = Responsive.gap(context, 1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Responsive.radius(context)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick actions', style: AppText.h3(context)),
          const SizedBox(height: 12),
          Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              _ActionChip(
                'Clients',
                Icons.people_alt_rounded,
                () => context.go('/clients'),
              ),
              _ActionChip(
                'Requests',
                Icons.assignment_rounded,
                () => context.go('/requests'),
              ),
              _ActionChip(
                'Analytics',
                Icons.bar_chart_rounded,
                () => context.go('/analytics'),
              ),
              _ActionChip(
                'Alerts',
                Icons.warning_rounded,
                () => context.go('/alerts'),
              ),
              _ActionChip(
                'Settings',
                Icons.settings_rounded,
                () => context.go('/settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionChip(this.label, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label, style: AppText.label(context)),
          ],
        ),
      ),
    );
  }
}

// Recent Clients
class _RecentClients extends StatelessWidget {
  const _RecentClients();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: DashboardController.instance.watchRecentClients(limit: 6),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _EmptyActivityCard(
            title: 'No clients yet',
            subtitle: 'Add your first client to start tracking.',
          );
        }

        return Column(
          children: snap.data!.docs.map((d) {
            return _RecentClientTile(
              name: d.data()['name'] ?? 'Unnamed',
              project: d.data()['project'] ?? '',
              onTap: () => context.go('/clients'),
            );
          }).toList(),
        );
      },
    );
  }
}

class _RecentClientTile extends StatelessWidget {
  final String name;
  final String project;
  final VoidCallback onTap;

  const _RecentClientTile({
    required this.name,
    required this.project,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.business_center_rounded,
          color: AppColors.primary,
        ),
      ),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        project.isEmpty ? 'No project' : project,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.small(context),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.subtext,
      ),
    );
  }
}

class _EmptyActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyActivityCard({required this.title, required this.subtitle});

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
          Icon(Icons.insights_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.title(context)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppText.bodyMuted(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
