import 'package:flutter/material.dart';

/// A reusable fade + slide page transition.
/// Professional, subtle, and cross-platform friendly.
///
/// Usage:
/// Navigator.of(context).push(
///   FadeSlideTransition(page: MyScreen()),
/// );
class FadeSlideTransition extends PageRouteBuilder {
  final Widget page;
  final Duration duration;
  final Offset beginOffset;

  FadeSlideTransition({
    required this.page,
    this.duration = const Duration(milliseconds: 260),
    this.beginOffset = const Offset(0, 0.04),
  }) : super(
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         pageBuilder: (_, __, ___) => page,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final media = MediaQuery.maybeOf(context);
           final reduceMotion = media?.disableAnimations ?? false;

           if (reduceMotion) {
             // Accessibility: no animation
             return child;
           }

           final curve = CurvedAnimation(
             parent: animation,
             curve: Curves.easeOutCubic,
             reverseCurve: Curves.easeInCubic,
           );

           final slide = Tween<Offset>(
             begin: beginOffset,
             end: Offset.zero,
           ).animate(curve);

           return FadeTransition(
             opacity: curve,
             child: SlideTransition(position: slide, child: child),
           );
         },
       );

  /// Helper presets (optional)
  static FadeSlideTransition fromBottom(Widget page) =>
      FadeSlideTransition(page: page, beginOffset: const Offset(0, 0.06));

  static FadeSlideTransition fromRight(Widget page) =>
      FadeSlideTransition(page: page, beginOffset: const Offset(0.06, 0));

  static FadeSlideTransition fromLeft(Widget page) =>
      FadeSlideTransition(page: page, beginOffset: const Offset(-0.06, 0));
}
