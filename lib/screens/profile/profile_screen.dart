import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/date_labels.dart';
import '../../providers/auth_provider.dart';
import '../../providers/birthday_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/avatar_circle.dart';
import '../../widgets/card_container.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/segmented_control.dart';

class _SettingsRow {
  const _SettingsRow(this.icon, this.label);
  final IconData icon;
  final String label;
}

const _settingsRows = [
  _SettingsRow(LucideIcons.bell, 'Notifications'),
  _SettingsRow(LucideIcons.palette, 'Accent color'),
  _SettingsRow(LucideIcons.info, 'About'),
];

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final themeProvider = context.watch<ThemeProvider>();
    final tasks = context.watch<TaskProvider>().tasks;
    final noteCount = context.watch<NoteProvider>().notes.length;
    final birthdayCount = context.watch<BirthdayProvider>().birthdays.length;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final accentInk = AppColors.accentInk(
      theme.colorScheme.primary,
      theme.brightness,
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final dueToday = tasks
        .where((t) => t.dueAt != null && DateLabels.isSameDay(t.dueAt!, now))
        .toList();
    final dueWeek = tasks
        .where(
          (t) =>
              t.dueAt != null &&
              !t.dueAt!.isBefore(weekStart) &&
              t.dueAt!.isBefore(weekEnd),
        )
        .toList();
    final doneToday = dueToday.where((t) => t.done).length;
    final doneWeek = dueWeek.where((t) => t.done).length;

    return AppScaffold(
      title: 'Profile',
      drawerRoute: AppRoutes.profile,
      titleStyle: TextStyles.h2(color: onSurface),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Row(
            children: [
              AvatarCircle(initials: user?.initials ?? '', size: 76),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user?.name ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.h4(color: onSurface),
                    ),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.pencil, size: 18),
                tooltip: 'Edit profile',
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.editProfile),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CardContainer(
            elevation: CardElevation.sm,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
            child: Row(
              children: [
                Expanded(
                  child: _StatColumn(
                    icon: LucideIcons.cake,
                    value: '$birthdayCount',
                    label: 'birthdays',
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: VerticalDivider(width: 1, color: theme.dividerColor),
                ),
                Expanded(
                  child: _TaskProgressColumn(
                    doneToday: doneToday,
                    dueToday: dueToday.length,
                    doneWeek: doneWeek,
                    dueWeek: dueWeek.length,
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: VerticalDivider(width: 1, color: theme.dividerColor),
                ),
                Expanded(
                  child: _StatColumn(
                    icon: LucideIcons.notebook,
                    value: '$noteCount',
                    label: 'notes',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CardContainer(
            elevation: CardElevation.sm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Appearance',
                  style: TextStyles.sectionLabel(color: onSurface),
                ),
                const SizedBox(height: 10),
                AppSegmentedControl<ThemeMode>(
                  value: themeProvider.mode,
                  onChanged: themeProvider.setMode,
                  options: const [
                    (ThemeMode.light, 'Light'),
                    (ThemeMode.dark, 'Dark'),
                  ],
                ),
                const SizedBox(height: 14),
                for (final role in const [
                  'background',
                  'surface',
                  'text',
                  'accent',
                ])
                  _ColorRolePicker(role: role, provider: themeProvider),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final row in _settingsRows)
            InkWell(
              onTap: row.label == 'About'
                  ? () => Navigator.of(context).pushNamed(AppRoutes.about)
                  : () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${row.label} coming soon')),
                    ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: theme.dividerColor)),
                ),
                child: Row(
                  children: [
                    Icon(row.icon, size: 18, color: accentInk),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        row.label,
                        style: TextStyle(fontSize: 14, color: onSurface),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 15,
                      color: onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          SecondaryButton(
            label: 'Log out',
            height: 46,
            leading: const Icon(LucideIcons.logOut, size: 16),
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              final signedOut = await auth.signOut();
              if (!context.mounted) return;
              if (!signedOut) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(auth.errorMessage ?? 'Could not sign out'),
                  ),
                );
                return;
              }
              // Unwind to the root, which is AuthGate — it watches
              // AuthProvider and swaps itself to Login on sign-out.
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Delete account',
            height: 46,
            leading: const Icon(LucideIcons.trash2, size: 16),
            onPressed: () => _confirmDeleteAccount(context),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDeleteAccount(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete account?'),
      content: const Text(
        "This permanently deletes your account and all data. This can't be undone.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  // AuthGate reacts to the status change exactly like it does for sign-out.
  Navigator.of(context).popUntil((route) => route.isFirst);
  await context.read<AuthProvider>().deleteAccount();
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.accentInk(
            theme.colorScheme.primary,
            theme.brightness,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyles.h4(color: onSurface)),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

/// Center stat column — today's and this week's (Mon–Sun) task-completion
/// ratios, replacing a single "tasks done" running total.
class _TaskProgressColumn extends StatelessWidget {
  const _TaskProgressColumn({
    required this.doneToday,
    required this.dueToday,
    required this.doneWeek,
    required this.dueWeek,
  });

  final int doneToday;
  final int dueToday;
  final int doneWeek;
  final int dueWeek;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Column(
      children: [
        Icon(
          LucideIcons.checkCheck,
          size: 18,
          color: AppColors.accentInk(
            theme.colorScheme.primary,
            theme.brightness,
          ),
        ),
        const SizedBox(height: 4),
        Text('$doneToday/$dueToday', style: TextStyles.h4(color: onSurface)),
        Text(
          '$doneWeek/$dueWeek this wk',
          style: TextStyle(
            fontSize: 10.5,
            color: onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: Theme.of(context).scaffoldBackgroundColor,
            width: 2,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color, blurRadius: 0, spreadRadius: 1.5)]
              : null,
        ),
      ),
    );
  }
}

class _ColorRolePicker extends StatelessWidget {
  const _ColorRolePicker({required this.role, required this.provider});
  final String role;
  final ThemeProvider provider;

  static const options = <Color>[
    Color(0xFFF8E1B7),
    Color(0xFFCBB896),
    Color(0xFF2E2010),
    Color(0xFFCBA35C),
    Color(0xFF8CA592),
    Color(0xFFDEE9F2),
    Color(0xFFCAD7EE),
    Color(0xFF23354B),
    Color(0xFF4769A1),
    Color(0xFFF0DDE5),
    Color(0xFF653348),
    Color(0xFFAB5476),
    Color(0xFFFAF8F4),
    Color(0xFF29232B),
    Color(0xFFEEE6DC),
  ];

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(role[0].toUpperCase() + role.substring(1)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final color in options)
                _AccentSwatch(
                  color: color,
                  selected:
                      provider.customColors['${brightness.name}_$role'] ==
                      color,
                  onTap: () {
                    if (!provider.setColor(role, color, brightness)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Choose colors with stronger contrast for readable text and controls.',
                          ),
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
