import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';

class RiskTag extends StatelessWidget {
  final bool risky;

  const RiskTag({super.key, required this.risky});

  @override
  Widget build(BuildContext context) {
    if (!risky) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Text(
        'RISKY',
        style: AppText.chip(context).copyWith(color: AppColors.warning),
      ),
    );
  }
}
