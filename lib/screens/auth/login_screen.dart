import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final brightness = theme.brightness;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -60,
              child: _decorativeCircle(
                180,
                AppColors.softFill(primary, brightness),
              ),
            ),
            Positioned(
              bottom: 140,
              left: -50,
              child: _decorativeCircle(
                140,
                AppColors.softFill(AppColors.accent2, brightness),
              ),
            ),
            // Scrollable: the logo + tagline + button stack overflows a short
            // screen (landscape, or a large text scale) in a fixed Column.
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              const SizedBox(height: 20),
                              Container(
                                width: 200,
                                height: 200,
                                padding: const EdgeInsets.all(36),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.softFill(primary, brightness),
                                      AppColors.softFill(
                                        AppColors.accent2,
                                        brightness,
                                      ),
                                    ],
                                  ),
                                  boxShadow: AppColors.shadowLg(brightness),
                                ),
                                child: Image.asset(
                                  'assets/images/noolure_logo.png',
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                AppStrings.tagline,
                                textAlign: TextAlign.center,
                                style: TextStyles.h2(color: onSurface),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                AppStrings.taglineSub,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Consumer<AuthProvider>(
                                builder: (context, auth, _) => PrimaryButton(
                                  label: 'Continue with Google',
                                  height: 52,
                                  leading: const GoogleLettermark(),
                                  onPressed:
                                      auth.status == AuthStatus.authenticating
                                      ? null
                                      : () => auth.signInWithGoogle(),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                AppStrings.termsFinePrint,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
