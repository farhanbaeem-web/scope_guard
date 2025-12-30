import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatters.dart';

class RecentActivityTile extends StatefulWidget {
  final String title;
  final bool inScope;
  final DateTime createdAt;
  final int? cost;

  /// Optional: open detail view later
  final VoidCallback? onTap;

  const RecentActivityTile({
    super.key,
    required this.title,
    required this.inScope,
    required this.createdAt,
    this.cost,
    this.onTap,
  });

  @override
  State<RecentActivityTile> createState() => _RecentActivityTileState();
}

class _RecentActivityTileState extends State<RecentActivityTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final canHover = Responsive.supportsHover(context);
    final color = widget.inScope ? AppColors.success : AppColors.warning;

    final timeText = Formatters.relative(widget.createdAt);

    return MouseRegion(
      cursor: (canHover && widget.onTap != null)
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: canHover ? (_) => setState(() => _hovered = true) : null,
      onExit: canHover ? (_) => setState(() => _hovered = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(Responsive.radius(context)),
            border: Border.all(
              color: _hovered
                  ? AppColors.primary.withValues(alpha: 0.22)
                  : AppColors.border,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.inScope
                      ? Icons.check_circle_rounded
                      : Icons.warning_rounded,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppText.body(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeText, // relative time looks premium
                      style: AppText.small(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              if (!widget.inScope && widget.cost != null)
                Text(
                  Formatters.currency(widget.cost!),
                  style: AppText.label(
                    context,
                  ).copyWith(color: AppColors.warning),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: widget.onTap != null
                      ? AppColors.subtext
                      : Colors.transparent,
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(begin: .02, end: 0);
  }
}
