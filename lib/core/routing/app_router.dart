// lib/core/routing/app_router.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/ui/login_screen.dart';
import '../../features/auth/ui/signup_screen.dart';
import '../../features/auth/ui/splash_screen.dart';
import '../../features/auth/ui/onboarding_screen.dart';
import '../../features/auth/ui/forgot_password_screen.dart';
import '../../features/auth/ui/email_verification_screen.dart';
import '../../features/home/ui/home_shell.dart';
import '../../features/auth/logic/auth_service.dart';
import '../../features/clients/data/client_model.dart';
import '../../features/clients/ui/add_edit_client_screen.dart';
import '../../features/clients/ui/client_detail_screen.dart';
import '../../features/errors/ui/not_found_screen.dart';
import 'app_transitions.dart';
import '../../features/clients/ui/client_activity_screen.dart';
import '../../features/clients/ui/client_contract_screen.dart';
import '../../features/clients/ui/client_notes_screen.dart';
import '../../features/clients/ui/client_reports_screen.dart';
import '../../features/clients/ui/client_requests_board_screen.dart';
import '../../features/requests/ui/request_detail_screen.dart';
import '../../features/requests/ui/request_add_edit_screen.dart';
import '../../features/requests/ui/request_approval_screen.dart';
import '../../features/requests/ui/request_templates_screen.dart';
import '../../features/analytics/ui/insights_detail_screen.dart';
import '../../features/analytics/ui/revenue_forecast_screen.dart';
import '../../features/activity/ui/activity_audit_screen.dart';
import '../../features/dashboard/ui/alerts_screen.dart';
import '../../features/billing/ui/billing_invoices_screen.dart';
import '../../features/billing/ui/billing_subscription_screen.dart';
import '../../features/integrations/ui/integration_detail_screen.dart';
import '../../features/team/ui/team_member_detail_screen.dart';
import '../../features/notifications/ui/notification_preferences_screen.dart';
import '../../features/settings/ui/data_retention_screen.dart';
import '../../features/settings/ui/security_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  refreshListenable: GoRouterRefreshStream(
    AuthService.instance.authStateChanges(),
  ),
  redirect: (context, state) {
    final user = AuthService.instance.currentUser;
    final loggedIn = user != null;
    final emailVerified = user?.emailVerified ?? false;
    final isAnonymous = user?.isAnonymous ?? false;
    final path = state.matchedLocation;
    const publicPaths = {
      '/splash',
      '/onboarding',
      '/login',
      '/signup',
      '/forgot',
      '/verify-email',
    };

    if (!loggedIn && !publicPaths.contains(path)) {
      return '/login';
    }

    if (loggedIn && !isAnonymous && !emailVerified && path != '/verify-email') {
      return '/verify-email';
    }

    if (loggedIn && publicPaths.contains(path) && path != '/onboarding') {
      final stayingOnVerify =
          path == '/verify-email' && !emailVerified && !isAnonymous;
      if (!stayingOnVerify) return '/';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) =>
          fadeSlidePage(key: state.pageKey, child: const SplashScreen()),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) =>
          fadeSlidePage(key: state.pageKey, child: const OnboardingScreen()),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) =>
          fadeSlidePage(key: state.pageKey, child: const LoginScreen()),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) =>
          fadeSlidePage(key: state.pageKey, child: const SignupScreen()),
    ),
    GoRoute(
      path: '/forgot',
      pageBuilder: (context, state) =>
          fadeSlidePage(key: state.pageKey, child: const ForgotPasswordScreen()),
    ),
    GoRoute(
      path: '/verify-email',
      pageBuilder: (context, state) =>
          fadeSlidePage(key: state.pageKey, child: const EmailVerificationScreen()),
    ),
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          fadeSlidePage(key: state.pageKey, child: const HomeShell()),
    ),
    GoRoute(
      path: '/alerts',
      pageBuilder: (context, state) =>
          fadeSlidePage(key: state.pageKey, child: const AlertsScreen()),
    ),
    GoRoute(
      path: '/clients',
      pageBuilder: (context, state) => fadeSlidePage(
        key: state.pageKey,
        child: const HomeShell(initialIndex: 1),
      ),
    ),
    GoRoute(
      path: '/requests',
      pageBuilder: (context, state) => fadeSlidePage(
        key: state.pageKey,
        child: const HomeShell(initialIndex: 2),
      ),
    ),
    GoRoute(
      path: '/analytics',
      pageBuilder: (context, state) => fadeSlidePage(
        key: state.pageKey,
        child: const HomeShell(initialIndex: 3),
      ),
    ),
    GoRoute(
      path: '/reports',
      pageBuilder: (context, state) => fadeSlidePage(
        key: state.pageKey,
        child: const HomeShell(initialIndex: 4),
      ),
    ),
    GoRoute(
      path: '/integrations',
      pageBuilder: (context, state) => fadeSlidePage(
        key: state.pageKey,
        child: const HomeShell(initialIndex: 5),
      ),
    ),
    GoRoute(
      path: '/billing',
      pageBuilder: (context, state) => fadeSlidePage(
        key: state.pageKey,
        child: const HomeShell(initialIndex: 6),
      ),
    ),
    GoRoute(
      path: '/insights',
      pageBuilder: (context, state) => fadeSlidePage(
        key: state.pageKey,
        child: const HomeShell(initialIndex: 7),
      ),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => fadeSlidePage(
        key: state.pageKey,
        child: const HomeShell(initialIndex: 8),
      ),
    ),
    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) => fadeSlidePage(
        key: state.pageKey,
        child: const HomeShell(initialIndex: 9),
      ),
    ),
    GoRoute(
      path: '/activity',
      pageBuilder: (context, state) => fadeSlidePage(
        key: state.pageKey,
        child: const HomeShell(initialIndex: 10),
      ),
    ),
    GoRoute(
      path: '/support',
      pageBuilder: (context, state) => fadeSlidePage(
        key: state.pageKey,
        child: const HomeShell(initialIndex: 11),
      ),
    ),
    GoRoute(
      path: '/exports',
      pageBuilder: (context, state) => fadeSlidePage(
        key: state.pageKey,
        child: const HomeShell(initialIndex: 12),
      ),
    ),
    GoRoute(
      path: '/team',
      pageBuilder: (context, state) => fadeSlidePage(
        key: state.pageKey,
        child: const HomeShell(initialIndex: 13),
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => fadeSlidePage(
        key: state.pageKey,
        child: const HomeShell(initialIndex: 14),
      ),
    ),
    GoRoute(
      path: '/clients/add',
      pageBuilder: (context, state) => fadeSlidePage(
        key: state.pageKey,
        child: const AddEditClientScreen(),
      ),
    ),
    GoRoute(
      path: '/clients/:id',
      pageBuilder: (context, state) {
        final clientId = state.pathParameters['id'] ?? '';
        final extra = state.extra;
        final clientName = extra is ClientModel
            ? extra.name
            : state.uri.queryParameters['name'] ?? 'Client';

        return fadeSlidePage(
          key: state.pageKey,
          child: ClientDetailScreen(
            clientId: clientId,
            clientName: clientName,
          ),
        );
      },
    ),
    GoRoute(
      path: '/clients/:id/activity',
      pageBuilder: (context, state) {
        final clientId = state.pathParameters['id'] ?? '';
        final clientName = state.uri.queryParameters['name'] ?? 'Client';
        return fadeSlidePage(
          key: state.pageKey,
          child: ClientActivityScreen(
            clientId: clientId,
            clientName: clientName,
          ),
        );
      },
    ),
    GoRoute(
      path: '/clients/:id/board',
      pageBuilder: (context, state) {
        final clientId = state.pathParameters['id'] ?? '';
        final clientName = state.uri.queryParameters['name'] ?? 'Client';
        return fadeSlidePage(
          key: state.pageKey,
          child: ClientRequestsBoardScreen(
            clientId: clientId,
            clientName: clientName,
          ),
        );
      },
    ),
    GoRoute(
      path: '/clients/:id/reports',
      pageBuilder: (context, state) {
        final clientId = state.pathParameters['id'] ?? '';
        final clientName = state.uri.queryParameters['name'] ?? 'Client';
        return fadeSlidePage(
          key: state.pageKey,
          child: ClientReportsScreen(
            clientId: clientId,
            clientName: clientName,
          ),
        );
      },
    ),
    GoRoute(
      path: '/clients/:id/notes',
      pageBuilder: (context, state) {
        final clientId = state.pathParameters['id'] ?? '';
        return fadeSlidePage(
          key: state.pageKey,
          child: ClientNotesScreen(clientId: clientId),
        );
      },
    ),
    GoRoute(
      path: '/clients/:id/contract',
      pageBuilder: (context, state) {
        final clientId = state.pathParameters['id'] ?? '';
        final clientName = state.uri.queryParameters['name'] ?? 'Client';
        return fadeSlidePage(
          key: state.pageKey,
          child: ClientContractScreen(
            clientId: clientId,
            clientName: clientName,
          ),
        );
      },
    ),
    GoRoute(
      path: '/clients/:clientId/requests/add',
      pageBuilder: (context, state) {
        final clientId = state.pathParameters['clientId'] ?? '';
        return fadeSlidePage(
          key: state.pageKey,
          child: RequestAddEditScreen(clientId: clientId),
        );
      },
    ),
    GoRoute(
      path: '/clients/:clientId/requests/:requestId',
      pageBuilder: (context, state) {
        final clientId = state.pathParameters['clientId'] ?? '';
        final requestId = state.pathParameters['requestId'] ?? '';
        return fadeSlidePage(
          key: state.pageKey,
          child: RequestDetailScreen(
            clientId: clientId,
            requestId: requestId,
          ),
        );
      },
    ),
    GoRoute(
      path: '/clients/:clientId/requests/:requestId/edit',
      pageBuilder: (context, state) {
        final clientId = state.pathParameters['clientId'] ?? '';
        final requestId = state.pathParameters['requestId'] ?? '';
        return fadeSlidePage(
          key: state.pageKey,
          child: RequestAddEditScreen(
            clientId: clientId,
            requestId: requestId,
          ),
        );
      },
    ),
    GoRoute(
      path: '/clients/:clientId/requests/:requestId/approval',
      pageBuilder: (context, state) {
        final clientId = state.pathParameters['clientId'] ?? '';
        final requestId = state.pathParameters['requestId'] ?? '';
        return fadeSlidePage(
          key: state.pageKey,
          child: RequestApprovalScreen(
            clientId: clientId,
            requestId: requestId,
          ),
        );
      },
    ),
    GoRoute(
      path: '/requests/templates',
      pageBuilder: (context, state) =>
          fadeSlidePage(key: state.pageKey, child: const RequestTemplatesScreen()),
    ),
    GoRoute(
      path: '/analytics/insights',
      pageBuilder: (context, state) =>
          fadeSlidePage(key: state.pageKey, child: const InsightsDetailScreen()),
    ),
    GoRoute(
      path: '/analytics/forecast',
      pageBuilder: (context, state) =>
          fadeSlidePage(key: state.pageKey, child: const RevenueForecastScreen()),
    ),
    GoRoute(
      path: '/activity/audit',
      pageBuilder: (context, state) =>
          fadeSlidePage(key: state.pageKey, child: const ActivityAuditScreen()),
    ),
    GoRoute(
      path: '/billing/invoices',
      pageBuilder: (context, state) =>
          fadeSlidePage(key: state.pageKey, child: const BillingInvoicesScreen()),
    ),
    GoRoute(
      path: '/billing/subscription',
      pageBuilder: (context, state) =>
          fadeSlidePage(key: state.pageKey, child: const BillingSubscriptionScreen()),
    ),
    GoRoute(
      path: '/integrations/:id',
      pageBuilder: (context, state) {
        final integrationId = state.pathParameters['id'] ?? '';
        return fadeSlidePage(
          key: state.pageKey,
          child: IntegrationDetailScreen(integrationId: integrationId),
        );
      },
    ),
    GoRoute(
      path: '/team/:id',
      pageBuilder: (context, state) {
        final memberId = state.pathParameters['id'] ?? '';
        return fadeSlidePage(
          key: state.pageKey,
          child: TeamMemberDetailScreen(memberId: memberId),
        );
      },
    ),
    GoRoute(
      path: '/notifications/preferences',
      pageBuilder: (context, state) => fadeSlidePage(
        key: state.pageKey,
        child: const NotificationPreferencesScreen(),
      ),
    ),
    GoRoute(
      path: '/settings/data',
      pageBuilder: (context, state) =>
          fadeSlidePage(key: state.pageKey, child: const DataRetentionScreen()),
    ),
    GoRoute(
      path: '/settings/security',
      pageBuilder: (context, state) =>
          fadeSlidePage(key: state.pageKey, child: const SecurityScreen()),
    ),
  ],
  errorPageBuilder: (context, state) => fadeSlidePage(
    key: state.pageKey,
    child: NotFoundScreen(
      location: state.matchedLocation,
      error: state.error,
    ),
  ),
);

/// ✅ Allows GoRouter to refresh automatically when a Stream emits.
/// This is how auth redirects happen in real-time.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
