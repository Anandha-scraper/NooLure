import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/text_styles.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/card_container.dart';

class _Feature {
  const _Feature(this.icon, this.title, this.description);
  final IconData icon;
  final String title;
  final String description;
}

const _features = [
  _Feature(
    LucideIcons.checkCheck,
    'Tasks',
    'Plan your to-dos with due dates, an archive and a trash.',
  ),
  _Feature(
    LucideIcons.notebook,
    'Notes',
    'Quick capture with checklists, formatting and search.',
  ),
  _Feature(
    LucideIcons.cake,
    'Birthdays',
    'Keep track of the people you care about.',
  ),
  _Feature(
    LucideIcons.lock,
    'Password Vault',
    'PIN-locked, encrypted storage for your logins.',
  ),
  _Feature(
    LucideIcons.mapPin,
    'Trip Planner',
    'Plan trips together with real-time shared updates.',
  ),
];

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final accentInk = AppColors.accentInk(
      theme.colorScheme.primary,
      theme.brightness,
    );

    return AppScaffold(
      title: 'About',
      titleStyle: TextStyles.h2(color: onSurface),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Column(
            children: [
              Text(AppStrings.appName, style: TextStyles.h2(color: onSurface)),
              const SizedBox(height: 6),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final info = snapshot.data;
                  final label = info == null
                      ? ' '
                      : 'v${info.version} (build ${info.buildNumber})';
                  return Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: onSurface.withValues(alpha: 0.55),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                AppStrings.taglineSub,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Features', style: TextStyles.sectionLabel(color: onSurface)),
          const SizedBox(height: 10),
          for (final feature in _features)
            CardContainer(
              elevation: CardElevation.sm,
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(feature.icon, size: 20, color: accentInk),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(feature.title, style: TextStyles.cardTitle(context)),
                        const SizedBox(height: 2),
                        Text(
                          feature.description,
                          style: TextStyles.cardBody(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
