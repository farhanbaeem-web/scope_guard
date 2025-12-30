import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gap = Responsive.gap(context, 1);
    final bars = const [
      _BarDatum(label: 'In scope', value: 24, color: AppColors.success),
      _BarDatum(label: 'Out of scope', value: 14, color: AppColors.warning),
      _BarDatum(label: 'Pending', value: 6, color: AppColors.info),
    ];

    final trends = const [
      _Trend(label: 'Win rate', value: '68%', delta: '+4.2%', color: AppColors.success),
      _Trend(label: 'Avg. overage', value: '\$1.9k', delta: '-3.1%', color: AppColors.primary),
      _Trend(label: 'Turnaround', value: '2.3d', delta: '-0.4d', color: AppColors.info),
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: Responsive.bottomSafeSpace(context, extra: 24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Insights', style: AppText.h2(context))),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_rounded),
                label: const Text('Export snapshot'),
              ),
            ],
          ).animate().fadeIn(duration: 220.ms).slideY(begin: .03, end: 0),
          SizedBox(height: gap),
          Text(
            'Bar charts that highlight workload mix and performance deltas.',
            style: AppText.bodyMuted(context),
          ).animate(delay: 50.ms).fadeIn().slideY(begin: .02, end: 0),
          SizedBox(height: gap),
          _BarCard(data: bars).animate(delay: 90.ms).fadeIn().slideY(begin: .02, end: 0),
          SizedBox(height: gap),
          Wrap(
            spacing: gap,
            runSpacing: gap,
            children: trends
                .map((t) => _TrendCard(trend: t)
                    .animate(delay: 120.ms)
                    .fadeIn()
                    .slideY(begin: .02, end: 0))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _BarCard extends StatelessWidget {
  final List<_BarDatum> data;
  const _BarCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final max = data.map((d) => d.value).fold<int>(1, (m, v) => v > m ? v : m);
    final radius = BorderRadius.circular(16);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Scope mix', style: AppText.h3(context)),
              const Spacer(),
              Text('Last 30 days', style: AppText.bodyMuted(context)),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: data.map((d) {
              final factor = (d.value / max).clamp(0, 1).toDouble();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0, end: factor),
                  builder: (context, v, _) {
                    return Row(
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(d.label, style: AppText.body(context)),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 14,
                              color: AppColors.surfaceMuted,
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: v,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: d.color,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('${d.value}', style: AppText.body(context)),
                      ],
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final _Trend trend;
  const _TrendCard({required this.trend});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(trend.label, style: AppText.small(context)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(trend.value, style: AppText.h3(context)),
              const SizedBox(width: 8),
              _Delta(text: trend.delta, color: trend.color),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  trend.color.withValues(alpha: 0.16),
                  trend.color.withValues(alpha: 0.06),
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Delta extends StatelessWidget {
  final String text;
  final Color color;
  const _Delta({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: AppText.chip(context).copyWith(color: color),
      ),
    );
  }
}

class _BarDatum {
  final String label;
  final int value;
  final Color color;
  const _BarDatum({required this.label, required this.value, required this.color});
}

class _Trend {
  final String label;
  final String value;
  final String delta;
  final Color color;
  const _Trend({required this.label, required this.value, required this.delta, required this.color});
}
