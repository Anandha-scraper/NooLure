import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/birthday_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/avatar_circle.dart';
import '../../widgets/card_container.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/tag_chip.dart';

/// A simple list of birthdays — implied by Home's "See all" and the
/// detail screen's "Up next" list, though not itself in the mockup.
class BirthdaysScreen extends StatelessWidget {
  const BirthdaysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final birthdays = context.watch<BirthdayProvider>().birthdays;
    final onSurface = theme.colorScheme.onSurface;
    final accentInk = AppColors.accentInk(
      theme.colorScheme.primary,
      theme.brightness,
    );

    return AppScaffold(
      title: 'Birthdays',
      drawerRoute: AppRoutes.birthdays,
      titleStyle: TextStyles.h2(color: onSurface),
      floatingActionButton: AppFab(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addBirthday),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          if (birthdays.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'No birthdays yet — tap + to add one',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          for (final b in birthdays)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(AppRoutes.birthdayDetail, arguments: b.id),
                child: CardContainer(
                  elevation: CardElevation.sm,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      AvatarCircle(initials: b.initials, size: 64),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              b.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyles.heading(
                                size: 15,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${b.relation} · ${b.dateLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                            if (b.bornLabel.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                b.bornLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.bell,
                                  size: 13,
                                  color: b.reminderDaysBefore.isNotEmpty
                                      ? accentInk
                                      : onSurface.withValues(alpha: 0.25),
                                ),
                                if (b.giftIdeas.isNotEmpty) ...[
                                  const SizedBox(width: 10),
                                  Icon(
                                    LucideIcons.gift,
                                    size: 13,
                                    color: accentInk,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TagChip(b.daysLabel, variant: TagVariant.accent),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
