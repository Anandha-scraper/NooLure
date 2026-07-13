import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/text_styles.dart';

/// Gradient circular avatar showing initials — reused across Home, Birthday
/// detail, Profile and the nav drawer header.
///
/// The gradient is derived from the live accent color so it tracks the user's
/// accent choice, and the ink is picked for the active brightness rather than
/// being pinned to a light-mode swatch.
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.initials,
    this.size = 52,
    this.gradientStart,
    this.gradientEnd,
    this.textColor,
  });

  final String initials;
  final double size;
  final Color? gradientStart;
  final Color? gradientEnd;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final primary = theme.colorScheme.primary;

    final start = gradientStart ?? AppColors.softFill(primary, brightness);
    final end =
        gradientEnd ?? AppColors.softFill(AppColors.accent2, brightness);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [start, end],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyles.heading(
          size: size * 0.28,
          color: textColor ?? AppColors.softInk(primary, brightness),
        ),
      ),
    );
  }
}
