import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';

class ScopeChip extends StatelessWidget {
  final String label;
  final bool highlighted;

  const ScopeChip({super.key, required this.label, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final Color bgColor = highlighted
        ? AppColors.warning.withValues(alpha: 0.14)
        : AppColors.primary.withValues(alpha: 0.06);

    final Color borderColor = highlighted
        ? AppColors.warning
        : AppColors.border;

    final Color textColor = highlighted ? AppColors.warning : AppColors.text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.chip(context).copyWith(color: textColor),
      ),
    );
  }
}
