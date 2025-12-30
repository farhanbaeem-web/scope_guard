import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Wrap any page with AnimatedPage to get
/// consistent fade + slide transitions across platforms.
class AnimatedPage extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const AnimatedPage({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 240),
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return child;
    return child
        .animate()
        .fadeIn(duration: duration)
        .slideY(
          begin: 0.04,
          end: 0,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
  }
}
