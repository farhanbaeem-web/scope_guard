import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../models/nav_item.dart';
import '../../features/auth/logic/auth_service.dart';
import 'nav_tile.dart'; // ✅ Import the premium tile

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<NavItem> items;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      size: 26,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Scope Guard',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Stay ahead of scope creep',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                itemCount: items.length + _quickLinks.length + 1,
                itemBuilder: (_, i) {
                  // Main nav items first
                  if (i < items.length) {
                    return NavTile(
                      // ✅ Using premium tile
                      label: items[i].label,
                      icon: items[i].icon,
                      selected: i == selectedIndex,
                      onTap: () {
                        Navigator.pop(context); // Close drawer on mobile
                        onSelect(i);
                      },
                    );
                  }

                  // Divider before quick links
                  if (i == items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Divider(),
                    );
                  }

                  final link = _quickLinks[i - items.length - 1];
                  return ListTile(
                    leading: Icon(link.icon, color: AppColors.subtext),
                    title: Text(link.label),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.pop(context);
                      if (link.route != null) context.go(link.route!);
                      if (link.onTap != null) link.onTap!(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLink {
  final IconData icon;
  final String label;
  final String? route;
  final void Function(BuildContext context)? onTap;

  const _QuickLink({
    required this.icon,
    required this.label,
    this.route,
    this.onTap,
  });
}

final _quickLinks = [
  const _QuickLink(icon: Icons.person_add_rounded, label: 'Add client', route: '/clients/add'),
  const _QuickLink(icon: Icons.bar_chart_rounded, label: 'Insights', route: '/insights'),
  const _QuickLink(icon: Icons.picture_as_pdf_rounded, label: 'Reports', route: '/reports'),
  const _QuickLink(icon: Icons.extension_rounded, label: 'Integrations', route: '/integrations'),
  const _QuickLink(icon: Icons.credit_card_rounded, label: 'Billing', route: '/billing'),
  const _QuickLink(icon: Icons.person_rounded, label: 'Profile', route: '/profile'),
  const _QuickLink(icon: Icons.notifications_rounded, label: 'Notifications', route: '/notifications'),
  const _QuickLink(icon: Icons.timeline_rounded, label: 'Activity', route: '/activity'),
  const _QuickLink(icon: Icons.support_agent_rounded, label: 'Support', route: '/support'),
  const _QuickLink(icon: Icons.file_upload_rounded, label: 'Exports', route: '/exports'),
  const _QuickLink(icon: Icons.group_rounded, label: 'Team', route: '/team'),
  _QuickLink(
    icon: Icons.logout_rounded,
    label: 'Logout',
    onTap: (ctx) {
      AuthService.instance.signOut();
      ctx.go('/login');
    },
  ),
];
