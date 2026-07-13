import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

/// Reusable circular progress ring with an optional centered child — used for
/// the Home "today's focus" ring.
///
/// Defaults come from the theme so the ring follows the accent setting and its
/// track doesn't glow white against a dark background.
class CircularProgressRing extends StatelessWidget {
  const CircularProgressRing({
    super.key,
    required this.percent,
    required this.size,
    this.strokeWidth = 7,
    this.child,
    this.progressColor,
  });

  final double percent;
  final double size;
  final double strokeWidth;
  final Widget? child;
  final Color? progressColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return CircularPercentIndicator(
      radius: size / 2,
      lineWidth: strokeWidth,
      percent: percent.clamp(0.0, 1.0),
      circularStrokeCap: CircularStrokeCap.round,
      backgroundColor: scheme.onSurface.withValues(alpha: 0.12),
      progressColor: progressColor ?? scheme.primary,
      center: child,
    );
  }
}
