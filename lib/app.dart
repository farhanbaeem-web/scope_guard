// lib/app.dart
import 'dart:ui'; // ✅ REQUIRED for PointerDeviceKind

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class ScopeGuardApp extends StatelessWidget {
  const ScopeGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Scope Guard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (context, child) {
        final reduceMotion =
            MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        Animate.defaultDuration =
            reduceMotion ? Duration.zero : const Duration(milliseconds: 220);
        return child ?? const SizedBox.shrink();
      },

      // Accessibility & UX
      scrollBehavior: const _AppScrollBehavior(),

      routerConfig: appRouter,
    );
  }
}

/// Custom scroll behavior for web + desktop
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
