import 'package:flutter/material.dart';

/// A premium Hero replacement that avoids the default zoom animation.
/// Uses a subtle fade + scale for web/desktop-friendly UX.
///
/// Recommended for:
/// - Cards
/// - Avatars
/// - KPI tiles
/// - Client / request transitions
class HeroFade extends StatelessWidget {
  final String tag;
  final Widget child;
  final bool enableScale;

  const HeroFade({
    super.key,
    required this.tag,
    required this.child,
    this.enableScale = true,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      transitionOnUserGestures: true,
      flightShuttleBuilder:
          (
            flightContext,
            animation,
            flightDirection,
            fromHeroContext,
            toHeroContext,
          ) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );

            final scaleTween = enableScale
                ? Tween<double>(begin: 0.98, end: 1.0)
                : Tween<double>(begin: 1.0, end: 1.0);

            return FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: scaleTween.animate(fade),
                child: flightDirection == HeroFlightDirection.push
                    ? toHeroContext.widget
                    : fromHeroContext.widget,
              ),
            );
          },
      child: child,
    );
  }
}
