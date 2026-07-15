import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/text_styles.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/confirm_done_dialog.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/task_preview_sheet.dart';
import '../../widgets/task_tile.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  bool _celebrationDismissed = false;
  bool _wasAllDone = false;
  bool _completedExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TaskProvider>();
    final onSurface = theme.colorScheme.onSurface;
    final all = provider.filteredTasks;
    final openTasks = all.where((t) => !t.done).toList();
    final completedTasks = all.where((t) => t.done).toList();

    // Re-arm the celebration each time it's freshly earned, rather than only
    // ever showing it once per app session.
    if (provider.allDone && !_wasAllDone) {
      _celebrationDismissed = false;
    }
    _wasAllDone = provider.allDone;
    // Fixed defaults plus whatever categories the user has actually typed in
    // — a hardcoded 'Errands'/'Urgent' chip that no task uses is just noise.
    final extraCategories =
        provider.tasks
            .map((t) => t.category)
            .where((c) => c.isNotEmpty && c != 'Work' && c != 'Personal')
            .toSet()
            .toList()
          ..sort();
    final filters = ['All', 'Work', 'Personal', ...extraCategories];

    return AppScaffold(
      title: 'Tasks',
      drawerRoute: AppRoutes.tasks,
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.trash2),
          tooltip: 'Deleted tasks',
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRoutes.trash),
        ),
        if (provider.allDone && !_celebrationDismissed)
          IconButton(
            icon: const Icon(LucideIcons.x),
            tooltip: 'Dismiss',
            onPressed: () => setState(() => _celebrationDismissed = true),
          ),
        const SizedBox(width: 8),
      ],
      titleStyle: TextStyles.h2(color: onSurface),
      floatingActionButton: AppFab(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addTask),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              Text(
                '${provider.openCount} open · ${provider.dueTodayCount} due today',
                style: TextStyle(
                  fontSize: 13,
                  color: onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final f = filters[i];
                    return TagChip(
                      f,
                      variant: f == provider.selectedFilter
                          ? TagVariant.accent
                          : TagVariant.neutral,
                      onTap: () => provider.setFilter(f),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              if (all.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Text(
                    provider.selectedFilter == 'All'
                        ? 'No tasks yet — tap + to add one'
                        : 'Nothing under "${provider.selectedFilter}"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              for (final task in openTasks)
                _taskRow(context, theme, provider, task, allowComplete: true),
              if (openTasks.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '← swipe to delete',
                      style: TextStyle(
                        fontSize: 11,
                        color: onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                    Text(
                      'swipe to complete →',
                      style: TextStyle(
                        fontSize: 11,
                        color: onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ],
              if (completedTasks.isNotEmpty) ...[
                const SizedBox(height: 18),
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => setState(
                    () => _completedExpanded = !_completedExpanded,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Completed (${completedTasks.length})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _completedExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          LucideIcons.chevronDown,
                          size: 16,
                          color: onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (_completedExpanded)
                  for (final task in completedTasks)
                    _taskRow(
                      context,
                      theme,
                      provider,
                      task,
                      allowComplete: false,
                    ),
              ],
            ],
          ),
          if (provider.allDone && !_celebrationDismissed)
            const _CelebrationOverlay(),
        ],
      ),
    );
  }

  /// A single swipeable, tappable task row — shared by the open and
  /// completed sections. [allowComplete] gates the complete-swipe direction
  /// entirely (via [Dismissible.direction], not just hiding a background),
  /// since a completed task has nothing left to confirm-complete into.
  Widget _taskRow(
    BuildContext context,
    ThemeData theme,
    TaskProvider provider,
    TaskModel task, {
    required bool allowComplete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(task.id),
        direction: allowComplete
            ? DismissDirection.horizontal
            : DismissDirection.endToStart,
        background: _swipeBackground(
          alignment: Alignment.centerLeft,
          color: AppColors.softFill(AppColors.accent2, theme.brightness),
          icon: LucideIcons.check,
          iconColor: AppColors.softInk(AppColors.accent2, theme.brightness),
        ),
        secondaryBackground: _swipeBackground(
          alignment: Alignment.centerRight,
          color: theme.colorScheme.error.withValues(alpha: 0.15),
          icon: LucideIcons.trash2,
          iconColor: theme.colorScheme.error,
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            await confirmDoneTask(
              context,
              title: task.title,
              onConfirm: () => provider.toggleDone(task.id),
            );
          } else {
            await confirmDeleteTask(
              context,
              title: task.title,
              onConfirm: () => provider.trashTask(task.id),
            );
          }
          return false;
        },
        child: TaskTile(
          task: task,
          showDragHandle: true,
          onToggle: null,
          onTap: () => showTaskPreview(
            context,
            task,
            onEdit: () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.taskDetail, arguments: task.id),
            onToggleDone: null,
          ),
          onLongPress: () => Navigator.of(
            context,
          ).pushNamed(AppRoutes.taskDetail, arguments: task.id),
        ),
      ),
    );
  }

  Widget _swipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Icon(icon, color: iconColor),
    );
  }
}

class _CelebrationOverlay extends StatelessWidget {
  const _CelebrationOverlay();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final firstName = (context.watch<AuthProvider>().currentUser?.name ?? '')
        .split(' ')
        .first;

    return Positioned.fill(
      child: Container(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.88),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.partyPopper,
              size: 48,
              color: AppColors.accentInk(
                theme.colorScheme.primary,
                theme.brightness,
              ),
            ),
            const SizedBox(height: 10),
            Text('All tasks complete', style: TextStyles.h4(color: onSurface)),
            const SizedBox(height: 4),
            Text(
              firstName.isEmpty
                  ? 'Nice work today'
                  : 'Nice work today, $firstName',
              style: TextStyle(
                fontSize: 12,
                color: onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
