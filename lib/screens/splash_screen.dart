import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/text_styles.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: 64,
              color: AppColors.accentInk(primary, theme.brightness),
            ),
            const SizedBox(height: 20),
            Text(
              'NooLure',
              style: TextStyles.h1(color: onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Your space to plan',
              style: TextStyle(
                fontSize: 14,
                color: onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.accentInk(primary, theme.brightness),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
