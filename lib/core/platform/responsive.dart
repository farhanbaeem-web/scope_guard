import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Responsive + platform-adaptive helpers for cross-platform UI:
/// Web • Desktop • Android • iOS
class Responsive {
  /// Breakpoints (kept simple & stable)
  static const double mobileMax = 600;
  static const double tabletMax = 1024;
  static const double desktopMin = 1025;

  /// Extra-wide layouts (large monitors)
  static const double wideMin = 1440;

  /// Content width caps to keep layouts "premium"
  static const double maxContentDesktop = 1100;
  static const double maxContentWide = 1280;

  /// When true, we consider hover interactions safe/expected.
  static bool supportsHover(BuildContext context) {
    // ✅ FIX: Replaced undefined 'pointerHoverEnabled' with target platform detection.
    // Web and Desktop OSs are considered hover-supported.
    if (kIsWeb) return true;

    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  static Size size(BuildContext context) => MediaQuery.sizeOf(context);
  static double w(BuildContext context) => size(context).width;
  static double h(BuildContext context) => size(context).height;

  static bool isMobile(BuildContext context) => w(context) <= mobileMax;

  static bool isTablet(BuildContext context) {
    final width = w(context);
    return width > mobileMax && width <= tabletMax;
  }

  static bool isDesktop(BuildContext context) => w(context) >= desktopMin;

  static bool isWide(BuildContext context) => w(context) >= wideMin;

  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    required T desktop,
    T? wide,
  }) {
    if (wide != null && isWide(context)) return wide;
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  static double contentMaxWidth(BuildContext context) {
    if (isWide(context)) return maxContentWide;
    if (isDesktop(context)) return maxContentDesktop;
    return double.infinity;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final width = w(context);
    if (width >= wideMin) {
      return const EdgeInsets.symmetric(horizontal: 28, vertical: 18);
    }
    if (width >= desktopMin) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
    if (width > mobileMax) {
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  }

  static EdgeInsets listPadding(BuildContext context) {
    final width = w(context);
    if (width >= desktopMin) {
      return const EdgeInsets.fromLTRB(24, 12, 24, 24);
    }
    if (width > mobileMax) {
      return const EdgeInsets.fromLTRB(20, 12, 20, 20);
    }
    return const EdgeInsets.fromLTRB(16, 10, 16, 16);
  }

  static double radius(BuildContext context) {
    return value<double>(
      context: context,
      mobile: 16,
      tablet: 18,
      desktop: 20,
      wide: 22,
    );
  }

  static double gap(BuildContext context, int step) {
    final base = value<double>(
      context: context,
      mobile: 8,
      tablet: 10,
      desktop: 12,
      wide: 12,
    );
    return base * step.clamp(1, 10);
  }

  static Widget centeredContent(
    BuildContext context, {
    required Widget child,
    EdgeInsets? padding,
  }) {
    final p = padding ?? pagePadding(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
        child: Padding(padding: p, child: child),
      ),
    );
  }

  static double bottomSafeSpace(BuildContext context, {double extra = 0}) {
    final mq = MediaQuery.of(context);
    return mq.padding.bottom + extra;
  }
}
