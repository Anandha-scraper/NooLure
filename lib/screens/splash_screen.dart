import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/text_styles.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final brightness = theme.brightness;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.softFill(primary, brightness),
                    AppColors.softFill(AppColors.accent2, brightness),
                  ],
                ),
                boxShadow: AppColors.shadowMd(brightness),
              ),
              child: Image.asset('assets/icons/appicon_square.png'),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.appName,
              style: TextStyles.h2(color: onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.taglineSub,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.accentInk(primary, brightness),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
