import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/platform/responsive.dart';

class NavTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const NavTile({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<NavTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final canHover = Responsive.supportsHover(context);

    // Premium styling logic restored
    final bg = widget.selected
        ? AppColors.primary.withValues(alpha: 0.10)
        : (_hover
              ? AppColors.primary.withValues(alpha: 0.06)
              : Colors.transparent);

    final border = widget.selected
        ? AppColors.primary.withValues(alpha: 0.25)
        : (_hover
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent);

    final iconColor = widget.selected ? AppColors.primary : AppColors.subtext;
    final textColor = widget.selected ? AppColors.primary : AppColors.text;

    return MouseRegion(
      onEnter: canHover ? (_) => setState(() => _hover = true) : null,
      onExit: canHover ? (_) => setState(() => _hover = false) : null,
      cursor: canHover ? SystemMouseCursors.click : MouseCursor.defer,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        offset: widget.selected || _hover ? const Offset(0, -0.02) : Offset.zero,
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      blurRadius: 16,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: ListTile(
            dense: true,
            leading: Icon(widget.icon, color: iconColor),
            title: Text(
              widget.label,
              style: TextStyle(
                fontWeight: widget.selected ? FontWeight.w800 : FontWeight.w600,
                color: textColor,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: iconColor.withValues(alpha: 0.8),
            ),
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}
