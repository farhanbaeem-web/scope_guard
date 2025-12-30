import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';

class MonthlySummaryScreen extends StatelessWidget {
  const MonthlySummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Summary')),
      body: Responsive.centeredContent(
        context,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collectionGroup('requests')
              .where('inScope', isEqualTo: false)
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start),
              )
              .snapshots(),
          builder: (_, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return Center(
                child: Text('No data', style: AppText.bodyMuted(context)),
              );
            }

            final docs = snapshot.data!.docs;

            int total = 0;
            int count = 0;

            for (final d in docs) {
              final data = d.data() as Map<String, dynamic>;
              final cost = data['estimatedCost'];
              final inScope = (data['inScope'] as bool?) ?? true;
              if (inScope) continue;

              count += 1;
              if (cost is int) total += cost;
              if (cost is num) total += cost.toInt();
            }

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: Responsive.bottomSafeSpace(context, extra: 24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Formatters.monthYear(now), style: AppText.h2(context))
                      .animate()
                      .fadeIn(duration: 220.ms)
                      .slideY(begin: .04, end: 0),

                  SizedBox(height: Responsive.gap(context, 2)),

                  _SummaryCard(
                    title: 'Extra earned this month',
                    value: Formatters.currency(total),
                    subtitle:
                        'From out-of-scope items logged since ${Formatters.shortDate(start)}',
                    icon: Icons.attach_money_rounded,
                    accent: AppColors.success,
                  ).animate().fadeIn(delay: 80.ms).slideY(begin: .04, end: 0),

                  SizedBox(height: Responsive.gap(context, 2)),

                  _SummaryCard(
                    title: 'Out-of-scope count',
                    value: '$count',
                    subtitle: 'Items flagged as outside original scope',
                    icon: Icons.warning_rounded,
                    accent: AppColors.warning,
                  ).animate().fadeIn(delay: 140.ms).slideY(begin: .04, end: 0),

                  SizedBox(height: Responsive.gap(context, 2)),

                  _PremiumHint()
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideY(begin: .04, end: 0),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.small(context)),
                const SizedBox(height: 6),
                Text(value, style: AppText.h3(context)),
                const SizedBox(height: 8),
                Text(subtitle, style: AppText.bodyMuted(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Responsive.radius(context)),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_rounded,
            color: AppColors.primary.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tip: Add estimated cost to every out-of-scope request to generate stronger client reports.',
              style: AppText.body(context),
            ),
          ),
        ],
      ),
    );
  }
}
