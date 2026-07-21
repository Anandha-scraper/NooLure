import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/text_styles.dart';
import '../providers/auth_provider.dart';
import 'app_scaffold.dart';
import 'avatar_circle.dart';

class _DrawerItem {
  const _DrawerItem(this.icon, this.label, this.route);
  final IconData icon;
  final String label;
  final String route;
}

const _drawerItems = [
  _DrawerItem(LucideIcons.house, 'Home', AppRoutes.home),
  _DrawerItem(LucideIcons.checkSquare, 'Tasks', AppRoutes.tasks),
  _DrawerItem(LucideIcons.notebook, 'Notes', AppRoutes.notes),
  _DrawerItem(LucideIcons.cake, 'Birthdays', AppRoutes.birthdays),
  _DrawerItem(LucideIcons.plane, 'Trip Planner', AppRoutes.trips),
  _DrawerItem(LucideIcons.keyRound, 'Passwords', AppRoutes.passwords),
];

/// The side-drawer nav — header (avatar/name/email), nav items with an
/// active-pill highlight, then Settings. Log out lives on the Profile screen
/// only. Used via `Scaffold(drawer:)` on every top-level screen;
/// `currentRoute` decides which pill is active.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AvatarCircle(initials: user?.initials ?? '', size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user?.name ?? '',
                          style: TextStyles.heading(size: 14, color: onSurface),
                        ),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              for (final item in _drawerItems)
                _DrawerRow(
                  icon: item.icon,
                  label: item.label,
                  active: item.route == currentRoute,
                  onTap: () {
                    Navigator.of(context).pop();
                    if (item.route != currentRoute) {
                      goToSection(context, item.route);
                    }
                  },
                ),
              const Divider(height: 24),
              _DrawerRow(
                icon: LucideIcons.settings,
                label: 'Settings',
                active: currentRoute == AppRoutes.profile,
                faded: true,
                onTap: () {
                  Navigator.of(context).pop();
                  if (currentRoute != AppRoutes.profile) {
                    goToSection(context, AppRoutes.profile);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerRow extends StatelessWidget {
  const _DrawerRow({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.faded = false,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool faded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;
    final color = active
        ? AppColors.softInk(primary, theme.brightness)
        : faded
        ? onSurface.withValues(alpha: 0.7)
        : onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? AppColors.softFill(primary, theme.brightness)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(fontSize: 14, color: color)),
          ],
        ),
      ),
    );
  }
}
