import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/text_styles.dart';
import '../../models/birthday_model.dart';
import '../../providers/birthday_provider.dart';
import '../../widgets/avatar_circle.dart';
import '../../widgets/tag_chip.dart';

class BirthdayScreen extends StatelessWidget {
  const BirthdayScreen({super.key, required this.birthdayId});

  final String birthdayId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<BirthdayProvider>();
    final birthday = provider.byId(birthdayId);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final brightness = theme.brightness;

    if (birthday == null) {
      return const Scaffold(body: Center(child: Text('Not found')));
    }

    final upNext = provider.birthdays
        .where((b) => b.id != birthday.id)
        .toList();

    // The header keeps its gradient identity in both themes by deriving from
    // the live accent rather than pinning to the light-mode 300 swatches.
    final headerStart = AppColors.softFill(primary, brightness);
    final headerEnd = AppColors.softFill(AppColors.accent2, brightness);
    final headerInk = AppColors.softInk(primary, brightness);
    final accentInk = AppColors.accentInk(primary, brightness);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    0,
                    MediaQuery.paddingOf(context).top + 54,
                    0,
                    28,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [headerStart, headerEnd],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AvatarCircle(
                        initials: birthday.initials,
                        size: 104,
                        gradientStart: primary,
                        gradientEnd: AppColors.accent2,
                        textColor: theme.colorScheme.onPrimary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        birthday.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.h3(color: headerInk),
                      ),
                      const SizedBox(height: 6),
                      TagChip(birthday.relation, variant: TagVariant.outline),
                      const SizedBox(height: 6),
                      Text(
                        '${birthday.daysLabel} · ${birthday.dateLabel}',
                        style: TextStyles.heading(size: 15, color: headerInk),
                      ),
                    ],
                  ),
                ),
                // Inset by the status-bar height — this used to be a bare
                // `top: 8` that put the chevron under the notch.
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 4,
                  left: 8,
                  child: IconButton(
                    icon: const Icon(LucideIcons.chevronLeft),
                    tooltip: 'Back',
                    color: headerInk,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 4,
                  right: 8,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.pencil),
                        tooltip: 'Edit birthday',
                        color: headerInk,
                        onPressed: () => Navigator.of(context).pushNamed(
                          AppRoutes.editBirthday,
                          arguments: birthday.id,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.trash2),
                        tooltip: 'Delete birthday',
                        color: headerInk,
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final deleted = await _confirmDeleteBirthday(
                            context,
                            provider,
                            birthday,
                          );
                          if (deleted) navigator.pop();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (birthday.bornLabel.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(LucideIcons.cake, size: 18, color: accentInk),
                        const SizedBox(width: 12),
                        Text(
                          birthday.bornLabel,
                          style: TextStyle(fontSize: 14, color: onSurface),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                  ],
                  Text(
                    'Notes',
                    style: TextStyles.sectionLabel(color: onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    birthday.notes.isEmpty ? 'No notes yet.' : birthday.notes,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                  if (birthday.giftIdeas.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Text(
                      'Gift ideas',
                      style: TextStyles.sectionLabel(color: onSurface),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final idea in birthday.giftIdeas)
                          TagChip(idea, variant: TagVariant.accent2),
                      ],
                    ),
                  ],
                  const SizedBox(height: 22),
                  Text(
                    'Reminders',
                    style: TextStyles.sectionLabel(color: onSurface),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final d in birthday.reminderDaysBefore)
                        TagChip(
                          key: ValueKey('reminder-$d'),
                          d == 0 ? 'On the day' : '$d days before',
                          variant: TagVariant.accent,
                          onTap: () => _confirmRemoveReminder(
                            context,
                            provider,
                            birthday.id,
                            d,
                          ),
                        ),
                      TagChip(
                        key: const ValueKey('add-custom-reminder'),
                        '+ Add custom',
                        variant: TagVariant.outline,
                        onTap: () =>
                            _showAddReminderDialog(context, provider, birthday.id),
                      ),
                    ],
                  ),
                  if (upNext.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Text(
                      'Up next',
                      style: TextStyles.sectionLabel(color: onSurface),
                    ),
                    const SizedBox(height: 10),
                    for (final b in upNext)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: GestureDetector(
                          onTap: () =>
                              Navigator.of(context).pushReplacementNamed(
                                AppRoutes.birthdayDetail,
                                arguments: b.id,
                              ),
                          child: Row(
                            children: [
                              AvatarCircle(initials: b.initials, size: 36),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      b.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: onSurface,
                                      ),
                                    ),
                                    Text(
                                      '${b.relation} · ${b.dateLabel}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: onSurface.withValues(alpha: 0.5),
                                      ),
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
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _confirmDeleteBirthday(
  BuildContext context,
  BirthdayProvider provider,
  BirthdayModel birthday,
) async {
  final deleted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete birthday?'),
      content: Text(
        'This removes "${birthday.name}" and all of its reminders. '
        "This can't be undone.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            await provider.deleteBirthday(birthday.id);
            if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return deleted ?? false;
}

Future<void> _showAddReminderDialog(
  BuildContext context,
  BirthdayProvider provider,
  String birthdayId,
) async {
  final controller = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Add custom reminder'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          hintText: 'Days before (0 = on the day)',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final days = int.tryParse(controller.text);
            // Mutate the provider (and let its rebuild happen) *before*
            // popping — popping first and mutating after races the dialog
            // route's own exit transition and trips a framework assertion
            // (`_dependents.isEmpty`) when the screen rebuilds mid-teardown.
            if (days != null && days >= 0) {
              await provider.addReminderDay(birthdayId, days);
            }
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
  controller.dispose();
}

Future<void> _confirmRemoveReminder(
  BuildContext context,
  BirthdayProvider provider,
  String birthdayId,
  int daysBefore,
) async {
  final label = daysBefore == 0 ? 'On the day' : '$daysBefore days before';
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Remove reminder?'),
      content: Text('"$label" won\'t remind you for this birthday anymore.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            await provider.removeReminderDay(birthdayId, daysBefore);
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          },
          child: const Text('Remove'),
        ),
      ],
    ),
  );
}
