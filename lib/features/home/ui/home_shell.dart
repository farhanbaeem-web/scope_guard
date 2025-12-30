import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../clients/ui/clients_list_screen.dart';
import '../../dashboard/ui/dashboard_screen.dart';
import '../../analytics/ui/analytics_hub_screen.dart';
import '../../integrations/ui/integrations_screen.dart';
import '../../billing/ui/billing_screen.dart';
import '../../insights/ui/insights_screen.dart';
import '../../profile/ui/profile_screen.dart';
import '../../notifications/ui/notifications_screen.dart';
import '../../activity/ui/activity_screen.dart';
import '../../support/ui/support_screen.dart';
import '../../exports/ui/exports_screen.dart';
import '../../team/ui/team_screen.dart';
import '../../reports/ui/reports_hub_screen.dart';
import '../../requests/ui/requests_hub_screen.dart';
import '../../settings/ui/settings_screen.dart';

/// Main shell that wires sidebar/hamburger navigation to the app pages.
class HomeShell extends StatelessWidget {
  final int initialIndex;

  const HomeShell({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    const navItems = [
      AppNavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: '/'),
      AppNavItem(
        label: 'Clients',
        icon: Icons.people_alt_rounded,
        route: '/clients',
      ),
      AppNavItem(
        label: 'Requests',
        icon: Icons.assignment_rounded,
        route: '/requests',
      ),
      AppNavItem(label: 'Analytics', icon: Icons.auto_graph_rounded, route: '/analytics'),
      AppNavItem(label: 'Reports', icon: Icons.picture_as_pdf_rounded, route: '/reports'),
      AppNavItem(label: 'Integrations', icon: Icons.extension_rounded, route: '/integrations'),
      AppNavItem(label: 'Billing', icon: Icons.credit_card_rounded, route: '/billing'),
      AppNavItem(label: 'Insights', icon: Icons.bar_chart_rounded, route: '/insights'),
      AppNavItem(label: 'Profile', icon: Icons.person_rounded, route: '/profile'),
      AppNavItem(label: 'Notifications', icon: Icons.notifications_rounded, route: '/notifications'),
      AppNavItem(label: 'Activity', icon: Icons.timeline_rounded, route: '/activity'),
      AppNavItem(label: 'Support', icon: Icons.support_agent_rounded, route: '/support'),
      AppNavItem(label: 'Exports', icon: Icons.file_upload_rounded, route: '/exports'),
      AppNavItem(label: 'Team', icon: Icons.group_rounded, route: '/team'),
      AppNavItem(
        label: 'Settings',
        icon: Icons.settings_rounded,
        route: '/settings',
      ),
    ];

    return AppScaffold(
      initialIndex: initialIndex,
      navItems: navItems,
      pages: const [
        DashboardScreen(),
        ClientsListScreen(),
        RequestsHubScreen(),
        AnalyticsHubScreen(),
        ReportsHubScreen(),
        IntegrationsScreen(),
        BillingScreen(),
        InsightsScreen(),
        ProfileScreen(),
        NotificationsScreen(),
        ActivityScreen(),
        SupportScreen(),
        ExportsScreen(),
        TeamScreen(),
        SettingsScreen(),
      ],
    );
  }
}
