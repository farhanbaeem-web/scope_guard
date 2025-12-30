import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';

class StatusPill extends StatelessWidget {
  final bool inScope;
  final int? cost;
  final bool compact;

  const StatusPill({
    super.key,
    required this.inScope,
    this.cost,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = inScope ? AppColors.success : AppColors.warning;
    final label = inScope ? 'IN SCOPE' : 'OUT OF SCOPE';

    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.chip(context).copyWith(color: color),
          ),
        ),
        if (!inScope && cost != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: compact
                ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              Formatters.currency(cost!),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.chip(context).copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ],
    );
  }
}
