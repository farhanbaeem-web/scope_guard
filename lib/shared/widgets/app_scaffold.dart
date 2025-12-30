import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/platform/adaptive_layout.dart';
import '../../core/platform/responsive.dart';
import '../models/nav_item.dart';

class AppScaffold extends StatefulWidget {
  final List<Widget> pages;
  final List<AppNavItem> navItems;
  final int initialIndex;
  final int primaryDestinations;

  const AppScaffold({
    super.key,
    required this.pages,
    required this.navItems,
    this.initialIndex = 0,
    this.primaryDestinations = 4,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.pages.length - 1).toInt();
  }

  @override
  void didUpdateWidget(covariant AppScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() {
        _index = widget.initialIndex.clamp(0, widget.pages.length - 1).toInt();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      selectedIndex: _index,
      onSelectIndex: (i) {
        final route = widget.navItems[i].route;
        if (route != null) context.go(route);
        setState(() => _index = i);
      },
      primaryDestinations: widget.primaryDestinations,
      pages: widget.pages.map((page) {
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.contentMaxWidth(context),
            ),
            child: Padding(
              padding: Responsive.pagePadding(context),
              child: page,
            ),
          ),
        );
      }).toList(),
      items: widget.navItems
          .map(
            // ✅ NOW WORKS: Uses NavItem from adaptive_layout.dart
            (e) => NavItem(label: e.label, icon: e.icon),
          )
          .toList(),
    );
  }
}

/// Public nav item model used for the AppScaffold constructor
class AppNavItem {
  final String label;
  final IconData icon;
  final String? route;

  const AppNavItem({required this.label, required this.icon, this.route});
}
