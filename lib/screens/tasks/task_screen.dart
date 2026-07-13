import 'dart:async';

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
import '../../widgets/custom_button.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/task_tile.dart';

const _filters = ['All', 'Work', 'Personal', 'Errands', 'Urgent'];

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  String? _justCompletedId;
  Timer? _highlightTimer;
  bool _completedExpanded = false;

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  void _onToggle(TaskProvider provider, TaskModel task) {
    final completing = !task.done;
    provider.toggleDone(task.id);
    if (!completing) {
      if (_justCompletedId == task.id) {
        setState(() => _justCompletedId = null);
      }
      return;
    }
    _highlightTimer?.cancel();
    setState(() => _justCompletedId = task.id);
    _highlightTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _justCompletedId = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TaskProvider>();
    final onSurface = theme.colorScheme.onSurface;
    final accentInk = AppColors.accentInk(
      theme.colorScheme.primary,
      theme.brightness,
    );
    final all = provider.filteredTasks;
    final active = all.where((t) => !t.done).toList();
    final completed = all.where((t) => t.done).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return AppScaffold(
      title: 'Tasks',
      drawerRoute: AppRoutes.tasks,
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
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final f = _filters[i];
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.sparkles, size: 16, color: accentInk),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Try "Call mom Friday 3pm"',
                        style: TextStyle(
                          fontSize: 13,
                          color: onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    Icon(LucideIcons.mic, size: 18, color: accentInk),
                  ],
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
              for (final task in active)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Dismissible(
                    key: ValueKey(task.id),
                    background: _swipeBackground(
                      alignment: Alignment.centerLeft,
                      color: AppColors.softFill(
                        AppColors.accent2,
                        theme.brightness,
                      ),
                      icon: LucideIcons.check,
                      iconColor: AppColors.softInk(
                        AppColors.accent2,
                        theme.brightness,
                      ),
                    ),
                    secondaryBackground: _swipeBackground(
                      alignment: Alignment.centerRight,
                      color: theme.colorScheme.error.withValues(alpha: 0.15),
                      icon: LucideIcons.trash2,
                      iconColor: theme.colorScheme.error,
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        _onToggle(provider, task);
                        return false;
                      }
                      return true;
                    },
                    onDismissed: (_) => provider.deleteTask(task.id),
                    child: _HighlightableTile(
                      highlighted: task.id == _justCompletedId,
                      child: TaskTile(
                        task: task,
                        showDragHandle: true,
                        onToggle: () => _onToggle(provider, task),
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.taskDetail,
                          arguments: task.id,
                        ),
                      ),
                    ),
                  ),
                ),
              if (active.isNotEmpty) ...[
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
              if (completed.isNotEmpty) ...[
                const SizedBox(height: 18),
                InkWell(
                  onTap: () =>
                      setState(() => _completedExpanded = !_completedExpanded),
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          _completedExpanded
                              ? LucideIcons.chevronDown
                              : LucideIcons.chevronRight,
                          size: 16,
                          color: onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Completed (${completed.length})',
                          style: TextStyles.sectionLabel(
                            color: onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_completedExpanded)
                  for (final task in completed)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _HighlightableTile(
                        highlighted: task.id == _justCompletedId,
                        child: TaskTile(
                          task: task,
                          showDragHandle: true,
                          onToggle: () => _onToggle(provider, task),
                          onTap: () => Navigator.of(context).pushNamed(
                            AppRoutes.taskDetail,
                            arguments: task.id,
                          ),
                        ),
                      ),
                    ),
              ],
            ],
          ),
          if (provider.allDone) const _CelebrationOverlay(),
        ],
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

/// Briefly tints a task tile right as it's completed, so the transition into
/// the Completed section doesn't feel abrupt.
class _HighlightableTile extends StatelessWidget {
  const _HighlightableTile({required this.highlighted, required this.child});

  final bool highlighted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.softFill(AppColors.accent2, theme.brightness)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.all(2),
      child: child,
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
