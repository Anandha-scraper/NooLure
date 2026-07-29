import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

enum TagVariant { accent, accent2, neutral, outline }

/// Small pill label — `.tag` and its variants in the design system.
///
/// Colors are derived from the live theme rather than the fixed light-mode
/// ramps: the `accent` variant follows whichever accent the user picked, and
/// every variant flips correctly in dark mode.
class TagChip extends StatelessWidget {
  const TagChip(
    this.label, {
    super.key,
    this.variant = TagVariant.neutral,
    this.onTap,
  });

  final String label;
  final TagVariant variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final (bg, fg, border) = _colors(theme, brightness);

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border != null ? Border.all(color: border) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 0.2,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (onTap == null) return chip;
    return GestureDetector(onTap: onTap, child: chip);
  }

  (Color, Color, Color?) _colors(ThemeData theme, Brightness brightness) {
    final primary = theme.colorScheme.primary;

    switch (variant) {
      case TagVariant.accent:
        return (
          AppColors.softFill(primary, brightness),
          AppColors.softInk(primary, brightness),
          null,
        );
      case TagVariant.accent2:
        return (
          AppColors.softFill(AppColors.accent2, brightness),
          AppColors.softInk(AppColors.accent2, brightness),
          null,
        );
      case TagVariant.neutral:
        final onSurface = theme.colorScheme.onSurface;
        return (
          onSurface.withValues(
            alpha: brightness == Brightness.dark ? 0.12 : 0.08,
          ),
          onSurface.withValues(alpha: 0.7),
          null,
        );
      case TagVariant.outline:
        return (Colors.transparent, primary, primary);
    }
  }
}
