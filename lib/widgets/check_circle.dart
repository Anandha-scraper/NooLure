import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The round checkbox used for tasks and subtasks. Previously duplicated
/// between TaskTile and the task detail screen at two different sizes, each
/// with its own hardcoded gold.
class CheckCircle extends StatelessWidget {
  const CheckCircle({
    super.key,
    required this.checked,
    this.onTap,
    this.size = 22,
  });

  final bool checked;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? scheme.primary : Colors.transparent,
        border: Border.all(
          color: checked
              ? scheme.primary
              : scheme.onSurface.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: checked
          ? Icon(LucideIcons.check, size: size * 0.6, color: scheme.onPrimary)
          : null,
    );

    if (onTap == null) return circle;
    return GestureDetector(onTap: onTap, child: circle);
  }
}
