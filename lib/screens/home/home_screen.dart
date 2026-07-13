import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/birthday_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/avatar_circle.dart';
import '../../widgets/card_container.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/task_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().currentUser;
    final tasks = context.watch<TaskProvider>();
    final birthdays = context.watch<BirthdayProvider>().birthdays;
    final firstName = (user?.name ?? '').split(' ').first;
    final onSurface = theme.colorScheme.onSurface;
    final accentInk = AppColors.accentInk(
      theme.colorScheme.primary,
      theme.brightness,
    );

    final doneCount = tasks.doneCount;
    final totalCount = tasks.tasks.length;
    final progress = totalCount == 0 ? 0.0 : doneCount / totalCount;

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.home),
      floatingActionButton: AppFab(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addTask),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Row(
              children: [
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(LucideIcons.menu),
                    tooltip: 'Menu',
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_greeting()}, $firstName',
                        style: TextStyles.h4(color: onSurface),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        DateFormat('EEEE, MMMM d').format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 12,
                          color: onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.bell),
                      onPressed: () {},
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 22),
            CardContainer(
              elevation: CardElevation.md,
              child: Row(
                children: [
                  CircularProgressRing(
                    percent: progress,
                    size: 72,
                    child: Text(
                      '${(progress * 100).round()}%',
                      style: TextStyles.heading(size: 15, color: onSurface),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CardKicker("Today's focus"),
                        CardTitle('$doneCount of $totalCount tasks done'),
                        const SizedBox(height: 2),
                        CardMeta(
                          totalCount == 0
                              ? 'Add your first task to get started'
                              : tasks.allDone
                              ? 'All done — enjoy your day'
                              : 'Keep going — almost there',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            _SectionHeader(
              title: 'Upcoming birthdays',
              onSeeAll: () =>
                  Navigator.of(context).pushNamed(AppRoutes.birthdays),
            ),
            const SizedBox(height: 10),
            if (birthdays.isEmpty)
              const _EmptyHint('No birthdays yet')
            else
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: birthdays.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 16),
                  itemBuilder: (context, i) {
                    final b = birthdays[i];
                    return GestureDetector(
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.birthdayDetail, arguments: b.id),
                      child: SizedBox(
                        width: 64,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AvatarCircle(initials: b.initials, size: 52),
                            const SizedBox(height: 6),
                            Text(
                              b.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                            Text(
                              b.daysLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10, color: accentInk),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 26),
            _SectionHeader(
              title: 'Today',
              onSeeAll: () => Navigator.of(context).pushNamed(AppRoutes.tasks),
            ),
            const SizedBox(height: 10),
            if (tasks.homeTasks.isEmpty)
              const _EmptyHint('Nothing on your plate — tap + to add a task')
            else
              for (final task in tasks.homeTasks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TaskTile(
                    task: task,
                    dense: true,
                    onToggle: () => tasks.toggleDone(task.id),
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.taskDetail, arguments: task.id),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyles.heading(
            size: 16,
            color: theme.colorScheme.onSurface,
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            'See all',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.accentInk(
                theme.colorScheme.primary,
                theme.brightness,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
