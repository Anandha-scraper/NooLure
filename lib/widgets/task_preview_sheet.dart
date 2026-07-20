import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/text_styles.dart';
import '../models/task_model.dart';
import 'check_circle.dart';
import 'inline_confirm_card.dart';
import 'tag_chip.dart';

/// Read-only glance at a task — shown on tap, with an "Edit" affordance for
/// anyone who doesn't know (or doesn't want to use) the long-press shortcut.
/// Pass `onEdit: null` to omit that affordance entirely (e.g. Home, where
/// editing is only reachable from the Tasks page). `onArchive`/`onTrash`
/// are likewise optional — when present, tapping either arms an inline
/// icon-split confirm inside the sheet before actually acting.
Future<void> showTaskPreview(
  BuildContext context,
  TaskModel task, {
  required VoidCallback? onEdit,
  required VoidCallback? onToggleDone,
  VoidCallback? onArchive,
  VoidCallback? onTrash,
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
      onArchive: onArchive,
      onTrash: onTrash,
    ),
  );
}

enum _TaskPendingAction { archive, trash }

class _TaskPreviewSheet extends StatefulWidget {
  const _TaskPreviewSheet({
    required this.task,
    required this.onEdit,
    required this.onToggleDone,
    this.onArchive,
    this.onTrash,
  });

  final TaskModel task;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleDone;
  final VoidCallback? onArchive;
  final VoidCallback? onTrash;

  @override
  State<_TaskPreviewSheet> createState() => _TaskPreviewSheetState();
}

class _TaskPreviewSheetState extends State<_TaskPreviewSheet> {
  _TaskPendingAction? _pending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final task = widget.task;
    final hasActions =
        widget.onEdit != null || widget.onArchive != null || widget.onTrash != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CheckCircle(checked: task.done, onTap: widget.onToggleDone),
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
            if (_pending != null) ...[
              const SizedBox(height: 20),
              InlineConfirmCard(
                confirmIcon: _pending == _TaskPendingAction.archive
                    ? LucideIcons.archive
                    : LucideIcons.trash2,
                onConfirm: () {
                  final navigator = Navigator.of(context);
                  if (_pending == _TaskPendingAction.archive) {
                    widget.onArchive?.call();
                  } else {
                    widget.onTrash?.call();
                  }
                  navigator.pop();
                },
                onCancel: () => setState(() => _pending = null),
              ),
            ] else if (hasActions) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.onArchive != null)
                    IconButton(
                      icon: const Icon(LucideIcons.archive, size: 18),
                      tooltip: 'Archive',
                      onPressed: () =>
                          setState(() => _pending = _TaskPendingAction.archive),
                    ),
                  if (widget.onTrash != null)
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 18),
                      tooltip: 'Move to trash',
                      onPressed: () =>
                          setState(() => _pending = _TaskPendingAction.trash),
                    ),
                  if (widget.onEdit != null)
                    TextButton.icon(
                      onPressed: widget.onEdit,
                      icon: const Icon(LucideIcons.pencil, size: 16),
                      label: const Text('Edit'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
