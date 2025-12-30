import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/platform/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import 'scope_chip.dart';

class ClientCard extends StatefulWidget {
  final String name;
  final String project;
  final String contractType;
  final VoidCallback onTap;

  /// Optional premium flags
  final bool risky;
  final int? outOfScopeCount;

  const ClientCard({
    super.key,
    required this.name,
    required this.project,
    required this.contractType,
    required this.onTap,
    this.risky = false,
    this.outOfScopeCount,
  });

  @override
  State<ClientCard> createState() => _ClientCardState();
}

class _ClientCardState extends State<ClientCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final canHover = Responsive.supportsHover(context);
    final radius = Responsive.radius(context);

    return MouseRegion(
      cursor: canHover ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: canHover ? (_) => setState(() => _hovered = true) : null,
      onExit: canHover ? (_) => setState(() => _hovered = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: _hovered
              ? (Matrix4.identity()..translate(0.0, -2.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: _hovered
                  ? AppColors.primary.withValues(alpha: 0.25)
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered ? AppColors.shadowMedium : AppColors.shadowSoft,
                blurRadius: _hovered ? 24 : 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Leading icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.business_center_rounded,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(width: 12),

              // Main info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + risk
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.name,
                            style: AppText.title(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.risky)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.warning_rounded,
                              size: 18,
                              color: AppColors.warning,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Project
                    Text(
                      widget.project,
                      style: AppText.small(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Chips row
                    Row(
                      children: [
                        ScopeChip(label: widget.contractType),
                        if (widget.outOfScopeCount != null &&
                            widget.outOfScopeCount! > 0) ...[
                          const SizedBox(width: 6),
                          _CountChip(count: widget.outOfScopeCount!),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(Icons.chevron_right_rounded, color: AppColors.subtext),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: .04, end: 0);
  }
}

class _CountChip extends StatelessWidget {
  final int count;
  const _CountChip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$count OOS',
        style: AppText.chip(context).copyWith(color: AppColors.warning),
      ),
    );
  }
}
