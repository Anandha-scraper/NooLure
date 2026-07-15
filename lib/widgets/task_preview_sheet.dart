import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/text_styles.dart';
import '../models/task_model.dart';
import 'check_circle.dart';
import 'tag_chip.dart';

/// Read-only glance at a task — shown on tap, with an "Edit" affordance for
/// anyone who doesn't know (or doesn't want to use) the long-press shortcut.
/// Pass `onEdit: null` to omit that affordance entirely (e.g. Home, where
/// editing is only reachable from the Tasks page).
Future<void> showTaskPreview(
  BuildContext context,
  TaskModel task, {
  required VoidCallback? onEdit,
  required VoidCallback? onToggleDone,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _TaskPreviewSheet(
      task: task,
      onEdit: onEdit == null
          ? null
          : () {
              Navigator.of(sheetContext).pop();
              onEdit();
            },
      onToggleDone: onToggleDone,
    ),
  );
}

class _TaskPreviewSheet extends StatelessWidget {
  const _TaskPreviewSheet({
    required this.task,
    required this.onEdit,
    required this.onToggleDone,
  });

  final TaskModel task;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CheckCircle(checked: task.done, onTap: onToggleDone),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyles.h4(color: onSurface).copyWith(
                      decoration: task.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TagChip(
                  task.dueAt == null
                      ? task.dateLabel
                      : '${task.dateLabel} · ${task.timeLabel}',
                  variant: TagVariant.neutral,
                ),
                TagChip(task.priority.label, variant: TagVariant.accent2),
                TagChip(task.category, variant: TagVariant.accent),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 13.5,
                  color: onSurface.withValues(alpha: 0.75),
                ),
              ),
            ],
            if (onEdit != null) ...[
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(LucideIcons.pencil, size: 16),
                  label: const Text('Edit'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
