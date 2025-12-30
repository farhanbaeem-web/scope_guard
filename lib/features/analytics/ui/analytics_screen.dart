import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/kpi_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../requests/data/request_model.dart';

class AnalyticsScreen extends StatefulWidget {
  final List<RequestModel> allRequests;

  const AnalyticsScreen({super.key, required this.allRequests});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
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
    final outOfScope =
        widget.allRequests.where((r) => !r.inScope).toList();

    final totalExtra = outOfScope.fold<int>(
      0,
      (sum, r) => sum + (r.estimatedCost ?? 0),
    );

    final countOut = outOfScope.length;
    final countAll = widget.allRequests.length;
    final buckets = _costBuckets(outOfScope);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Responsive.centeredContent(
        context,
        child: countAll == 0
            ? const EmptyState(
                icon: Icons.bar_chart_rounded,
                title: 'No data yet',
                message: 'Log a few requests to see analytics.',
              )
            : RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: Scrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      bottom: Responsive.bottomSafeSpace(context, extra: 24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  Text(
                    'Performance Overview',
                    style: AppText.h2(context),
                  ).animate().fadeIn(duration: 220.ms).slideY(begin: .04, end: 0),
                  SizedBox(height: Responsive.gap(context, 2)),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => context.push('/analytics/insights'),
                        icon: const Icon(Icons.insights_rounded),
                        label: const Text('Insights detail'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/analytics/forecast'),
                        icon: const Icon(Icons.trending_up_rounded),
                        label: const Text('Revenue forecast'),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.gap(context, 2)),
                  _KpiGrid(
                    totalExtra: totalExtra,
                    outCount: countOut,
                    allCount: countAll,
                  ).animate().fadeIn(delay: 70.ms).slideY(begin: .04, end: 0),
                  SizedBox(height: Responsive.gap(context, 2)),
                  _PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Out-of-scope breakdown',
                              style: AppText.h3(context),
                            ),
                            const Spacer(),
                            _Pill(
                              text: '$countOut items',
                              icon: Icons.warning_rounded,
                              color: AppColors.warning,
                            ),
                          ],
                        ),
                        SizedBox(height: Responsive.gap(context, 1)),
                        Text(
                          'Understand where scope creep is costing you time and money.',
                          style: AppText.bodyMuted(context),
                        ),
                        SizedBox(height: Responsive.gap(context, 2)),
                        _Bars(
                          titleLeft: 'Cost range',
                          titleRight: 'Count',
                          items: buckets,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 140.ms).slideY(begin: .04, end: 0),
                  SizedBox(height: Responsive.gap(context, 2)),
                  _PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Recommendations', style: AppText.h3(context)),
                            const Spacer(),
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.primary.withValues(alpha: 0.8),
                            ),
                          ],
                        ),
                        SizedBox(height: Responsive.gap(context, 1)),
                        _TipLine(
                          icon: Icons.article_rounded,
                          text:
                              'Generate a scope report and send it before starting extra work.',
                        ),
                        _TipLine(
                          icon: Icons.attach_money_rounded,
                          text:
                              'Always attach an estimate to out-of-scope requests.',
                        ),
                        _TipLine(
                          icon: Icons.handshake_rounded,
                          text:
                              'Use templates to standardize approvals and reduce surprises.',
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 210.ms).slideY(begin: .04, end: 0),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  static List<_BarItem> _costBuckets(List<RequestModel> out) {
    int b0 = 0; // 0-999
    int b1 = 0; // 1k-4,999
    int b2 = 0; // 5k-14,999
    int b3 = 0; // 15k+

    for (final r in out) {
      final c = r.estimatedCost ?? 0;
      if (c <= 999) {
        b0++;
      } else if (c <= 4999) {
        b1++;
      } else if (c <= 14999) {
        b2++;
      } else {
        b3++;
      }
    }

    return [
      _BarItem(r'$0-$999', b0),
      _BarItem(r'$1k-$4.9k', b1),
      _BarItem(r'$5k-$14.9k', b2),
      _BarItem(r'$15k+', b3),
    ];
  }
}

class _KpiGrid extends StatelessWidget {
  final int totalExtra;
  final int outCount;
  final int allCount;

  const _KpiGrid({
    required this.totalExtra,
    required this.outCount,
    required this.allCount,
  });

  @override
  Widget build(BuildContext context) {
    final cols = Responsive.value<int>(
      context: context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
    );
    final gap = Responsive.gap(context, 1);

    final cards = [
      KpiCard(
        label: 'Extra earned',
        value: Formatters.currency(totalExtra),
        icon: Icons.attach_money_rounded,
        accent: AppColors.success,
        subtitle: 'Out-of-scope totals',
      ),
      KpiCard(
        label: 'Out-of-scope',
        value: '$outCount',
        icon: Icons.warning_rounded,
        accent: AppColors.warning,
        subtitle: 'Requests flagged',
      ),
      KpiCard(
        label: 'Total requests',
        value: '$allCount',
        icon: Icons.list_alt_rounded,
        accent: AppColors.info,
        subtitle: 'All logged work',
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
            for (final c in cards) SizedBox(width: itemWidth, child: c),
          ],
        );
      },
    );
  }
}

class _Bars extends StatelessWidget {
  final String titleLeft;
  final String titleRight;
  final List<_BarItem> items;

  const _Bars({
    required this.titleLeft,
    required this.titleRight,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final maxV = items
        .map((e) => e.value)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final safeMax = maxV == 0 ? 1 : maxV;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(titleLeft, style: AppText.small(context))),
            Text(titleRight, style: AppText.small(context)),
          ],
        ),
        const SizedBox(height: 10),
        for (int i = 0; i < items.length; i++)
          _BarRow(
            label: items[i].label,
            value: items[i].value,
            progress: items[i].value / safeMax,
          ).animate(delay: (60 * i).ms).fadeIn().slideX(begin: .02, end: 0),
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final int value;
  final double progress;

  const _BarRow({
    required this.label,
    required this.value,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(label, style: AppText.body(context))),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: radius,
              child: Container(
                height: 10,
                color: AppColors.surfaceMuted,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress.clamp(0, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: radius,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: AppText.label(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final Widget child;
  const _PremiumCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _Pill({required this.text, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: AppText.chip(context).copyWith(color: color)),
        ],
      ),
    );
  }
}

class _TipLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.subtext),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppText.bodyMuted(context))),
        ],
      ),
    );
  }
}

class _BarItem {
  final String label;
  final int value;
  _BarItem(this.label, this.value);
}
