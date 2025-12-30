import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/platform/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/request_model.dart';
import 'status_pill.dart';

class RequestTile extends StatefulWidget {
  final RequestModel request;

  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Quick scope toggle
  final ValueChanged<bool>? onToggleScope;

  const RequestTile({
    super.key,
    required this.request,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleScope,
  });

  @override
  State<RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends State<RequestTile> {
  bool _hovered = false;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final canHover = Responsive.supportsHover(context);
    final radius = Responsive.radius(context);

    final tile = MouseRegion(
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
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: _hovered
                  ? AppColors.primary.withValues(alpha: 0.22)
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: status + actions
              Row(
                children: [
                  Expanded(
                    child: StatusPill(
                      inScope: r.inScope,
                      cost: r.estimatedCost,
                      compact: true,
                    ),
                  ),
                  if (widget.onToggleScope != null)
                    Tooltip(
                      message: r.inScope
                          ? 'Mark as out of scope'
                          : 'Mark as in scope',
                      child: IconButton(
                        onPressed: () => widget.onToggleScope?.call(!r.inScope),
                        icon: Icon(
                          r.inScope
                              ? Icons.warning_rounded
                              : Icons.check_circle_rounded,
                          color: AppColors.subtext,
                        ),
                      ),
                    ),
                  if (widget.onEdit != null)
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: widget.onEdit,
                      icon: const Icon(Icons.edit_rounded),
                      color: AppColors.subtext,
                    ),
                  if (widget.onDelete != null)
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete_rounded),
                      color: AppColors.danger,
                    ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                r.title,
                style: AppText.title(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  (r.description.isEmpty) ? '—' : r.description,
                  style: AppText.bodyMuted(context),
                  maxLines: _expanded ? 12 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: AppColors.subtext,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      Formatters.dateTime(r.createdAt),
                      style: AppText.small(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              if (r.description.length > 80) ...[
                const SizedBox(height: 6),
                Text(
                  _expanded ? 'Tap to collapse' : 'Tap to expand',
                  style: AppText.small(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (reduceMotion) return tile;

    return tile.animate().fadeIn(duration: 220.ms).slideY(begin: .04, end: 0);
  }
}
