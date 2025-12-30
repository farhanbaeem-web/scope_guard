import 'package:flutter/material.dart';

import 'responsive.dart';
import '../../shared/models/nav_item.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/app_sidebar.dart';

/// Adaptive layout that switches navigation style based on screen size:
/// - Mobile/Tablet -> Drawer (hamburger)
/// - Desktop/Web   -> Sidebar (NavigationRail)
class AdaptiveLayout extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelectIndex;
  final List<Widget> pages;
  final List<NavItem> items;
  final int primaryDestinations;

  const AdaptiveLayout({
    super.key,
    required this.selectedIndex,
    required this.onSelectIndex,
    required this.pages,
    required this.items,
    this.primaryDestinations = 4,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final canShowBottomNav = !isDesktop && items.isNotEmpty;
    final primaryCount = items.length < primaryDestinations
        ? items.length
        : primaryDestinations;
    final hasMore = items.length > primaryCount;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final pageChild = AnimatedSwitcher(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey(selectedIndex),
        child: pages[selectedIndex],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(items[selectedIndex].label),
      ),
      drawer: AppDrawer(
        selectedIndex: selectedIndex,
        onSelect: onSelectIndex,
        items: items,
      ),
      body: isDesktop
          ? Row(
              children: [
                AppSidebar(
                  selectedIndex: selectedIndex,
                  onSelect: onSelectIndex,
                  items: items,
                ),
                const VerticalDivider(width: 1),
                Expanded(child: pageChild),
              ],
            )
          : pageChild,
      bottomNavigationBar: canShowBottomNav
          ? Builder(
              builder: (context) {
                final currentIndex =
                    selectedIndex < primaryCount ? selectedIndex : primaryCount;
                final destinations = [
                  for (int i = 0; i < primaryCount; i++)
                    NavigationDestination(
                      icon: Icon(items[i].icon),
                      label: items[i].label,
                    ),
                  if (hasMore)
                    const NavigationDestination(
                      icon: Icon(Icons.more_horiz_rounded),
                      label: 'More',
                    ),
                ];

                return NavigationBar(
                  selectedIndex: currentIndex,
                  onDestinationSelected: (i) {
                    if (hasMore && i == primaryCount) {
                      Scaffold.of(context).openDrawer();
                      return;
                    }
                    onSelectIndex(i);
                  },
                  destinations: destinations,
                );
              },
            )
          : null,
    );
  }
}
