import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

class KpiCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  /// Optional: allow KPI to be clickable (e.g., go to Analytics)
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  State<KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<KpiCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.color ?? AppColors.primary;
    final canHover = Responsive.supportsHover(context);

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
              transform: _hovered
                  ? (Matrix4.identity()..translate(0.0, -2.0))
                  : Matrix4.identity(),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(Responsive.radius(context)),
                border: Border.all(
                  color: _hovered
                      ? accent.withValues(alpha: 0.28)
                      : AppColors.border,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _hovered
                        ? AppColors.shadowMedium
                        : AppColors.shadowSoft,
                    blurRadius: _hovered ? 24 : 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(widget.icon, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: AppText.small(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.value,
                          style: AppText.h3(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (widget.onTap != null) ...[
                    const SizedBox(width: 10),
                    Icon(Icons.chevron_right_rounded, color: AppColors.subtext),
                  ],
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 220.ms)
        .scale(
          begin: const Offset(.985, .985),
          end: const Offset(1, 1),
          curve: Curves.easeOutCubic,
          duration: 220.ms,
        );
  }
}
