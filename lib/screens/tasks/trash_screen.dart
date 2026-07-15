import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_labels.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/tag_chip.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final trashed = provider.trashedTasks;
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return AppScaffold(
      title: 'Deleted Tasks',
      actions: trashed.isNotEmpty
          ? [
              IconButton(
                icon: const Icon(LucideIcons.trash2),
                tooltip: 'Empty trash',
                onPressed: () => _confirmEmptyTrash(context, provider, trashed.length),
              ),
              const SizedBox(width: 8),
            ]
          : null,
      body: trashed.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.trash2,
                    size: 40,
                    color: onSurface.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Trash is empty',
                    style: TextStyle(
                      fontSize: 14,
                      color: onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              itemCount: trashed.length,
              itemBuilder: (context, i) => _trashTile(
                context,
                theme,
                provider,
                trashed[i],
              ),
            ),
    );
  }

  Widget _trashTile(
    BuildContext context,
    ThemeData theme,
    TaskProvider provider,
    TaskModel task,
  ) {
    final onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(task.id),
        background: _swipeBg(
          alignment: Alignment.centerLeft,
          color: AppColors.softFill(AppColors.accent2, theme.brightness),
          icon: LucideIcons.archiveRestore,
          iconColor: AppColors.softInk(AppColors.accent2, theme.brightness),
        ),
        secondaryBackground: _swipeBg(
          alignment: Alignment.centerRight,
          color: theme.colorScheme.error.withValues(alpha: 0.15),
          icon: LucideIcons.trash2,
          iconColor: theme.colorScheme.error,
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            _restore(context, provider, task);
          } else {
            await confirmDeleteTask(
              context,
              title: task.title,
              onConfirm: () => provider.permanentlyDeleteTask(task.id),
              permanent: true,
            );
          }
          return false;
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: AppColors.shadowSm(theme.brightness),
          ),
          child: Material(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(32),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 14.5,
                            color: onSurface,
                            decoration: task.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Deleted ${DateLabels.relativeLabel(task.deletedAt!)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                            TagChip(task.category),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      LucideIcons.archiveRestore,
                      size: 18,
                      color: AppColors.accentInk(
                        theme.colorScheme.primary,
                        theme.brightness,
                      ),
                    ),
                    tooltip: 'Restore',
                    onPressed: () => _restore(context, provider, task),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _restore(BuildContext context, TaskProvider provider, TaskModel task) {
    final hadPastDue =
        task.dueAt != null && task.dueAt!.isBefore(DateTime.now());
    provider.restoreTask(task.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hadPastDue ? 'Task restored — due date set to now' : 'Task restored',
        ),
      ),
    );
  }

  Future<void> _confirmEmptyTrash(
    BuildContext context,
    TaskProvider provider,
    int count,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Permanently delete $count ${count == 1 ? 'task' : 'tasks'}?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.emptyTrash();
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
  }

  Widget _swipeBg({
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
