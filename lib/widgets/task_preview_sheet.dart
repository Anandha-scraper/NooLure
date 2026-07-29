import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/text_styles.dart';
import '../core/utils/date_labels.dart';
import '../core/utils/routine_occurrence.dart';
import '../models/routine_config.dart';
import '../models/task_model.dart';
import 'check_circle.dart';
import 'custom_button.dart';
import 'inline_confirm_card.dart';
import 'routine_day_history_row.dart';
import 'tag_chip.dart';

/// Read-only glance at a task — shown on tap, with an "Edit" affordance for
/// anyone who doesn't know (or doesn't want to use) the long-press shortcut.
/// Pass `onEdit: null` to omit that affordance entirely (e.g. Home, where
/// editing is only reachable from the Tasks page). `onArchive`/`onTrash`
/// are likewise optional — when present, tapping either arms an inline
/// icon-split confirm inside the sheet before actually acting.
///
/// `onCompleteRoutineOccurrence` is only relevant when `task.routine != null`
/// — the caller (which already has the provider and its own screen's
/// context) is responsible for calling `TaskProvider.completeRoutineOccurrence`
/// and showing whatever confirmation it wants; this sheet just triggers it
/// and closes itself afterward.
Future<void> showTaskPreview(
  BuildContext context,
  TaskModel task, {
  required VoidCallback? onEdit,
  required VoidCallback? onToggleDone,
  VoidCallback? onArchive,
  VoidCallback? onTrash,
  Future<void> Function()? onCompleteRoutineOccurrence,
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
      onCompleteRoutineOccurrence: onCompleteRoutineOccurrence,
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
    this.onCompleteRoutineOccurrence,
  });

  final TaskModel task;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleDone;
  final VoidCallback? onArchive;
  final VoidCallback? onTrash;
  final Future<void> Function()? onCompleteRoutineOccurrence;

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
    final routine = task.routine;
    final now = DateTime.now();
    final routineStatus = routine == null
        ? null
        : todaysOccurrence(routine, now: now);
    final dayNumber = routine == null ? null : dayNumberFor(routine, now);
    final hasActions =
        widget.onEdit != null || widget.onArchive != null || widget.onTrash != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // A routine isn't a single checkable thing — only its
                // individual day occurrences are — so it gets no checkbox.
                if (routine == null) ...[
                  CheckCircle(checked: task.done, onTap: widget.onToggleDone),
                  const SizedBox(width: 12),
                ],
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
                  routine == null
                      ? (task.timeLabel.isEmpty
                            ? task.dateLabel
                            : '${task.dateLabel} · ${task.timeLabel}')
                      : (dayNumber != null
                            ? routineDayLabel(dayNumber, now)
                            : 'Due ${DateLabels.dayLabel(routine.endDate)}'),
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
            if (routineStatus != null) ...[
              const SizedBox(height: 16),
              Text(
                _routineDetailLine(routine!, routineStatus, dayNumber, now),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: switch (routineStatus) {
                    RoutineOccurrenceStatus.missed ||
                    RoutineOccurrenceStatus.dueLate => theme.colorScheme.error,
                    RoutineOccurrenceStatus.completedLate => AppColors.accentInk(
                      AppColors.highlight,
                      theme.brightness,
                    ),
                    RoutineOccurrenceStatus.completedEarly ||
                    RoutineOccurrenceStatus.completedOnTime =>
                      Colors.green.shade600,
                    _ => onSurface.withValues(alpha: 0.75),
                  },
                ),
              ),
              if ((routineStatus == RoutineOccurrenceStatus.upcoming ||
                      routineStatus == RoutineOccurrenceStatus.dueNow ||
                      routineStatus == RoutineOccurrenceStatus.dueLate) &&
                  widget.onCompleteRoutineOccurrence != null) ...[
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Mark today done',
                  height: 44,
                  onPressed: () async {
                    await widget.onCompleteRoutineOccurrence!();
                    if (mounted) Navigator.of(context).pop();
                  },
                ),
              ],
              if (occurrenceDatesThrough(routine, now).length > 1) ...[
                const SizedBox(height: 16),
                _routineHistoryList(routine, now),
              ],
            ],
            if (_pending != null) ...[
              const SizedBox(height: 20),
              InlineConfirmCard(
                actionIcon: _pending == _TaskPendingAction.archive
                    ? LucideIcons.archive
                    : LucideIcons.trash2,
                actionColor: _pending == _TaskPendingAction.archive
                    ? AppColors.accent2
                    : Theme.of(context).colorScheme.error,
                actionLabel: _pending == _TaskPendingAction.archive
                    ? 'Archive "${task.title}"'
                    : 'Move "${task.title}" to trash',
                height: 78,
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
      ),
    );
  }

  String _routineDetailLine(
    RoutineConfig routine,
    RoutineOccurrenceStatus status,
    int? dayNumber,
    DateTime now,
  ) {
    final completedAt = logEntryFor(routine, now)?.completedAt;
    return [
      if (dayNumber != null)
        'Day $dayNumber of ${totalOccurrenceCount(routine)}',
      _routineStatusLabel(status),
      if (completedAt != null) DateLabels.compactTimeLabel(completedAt),
    ].join(' · ');
  }

  /// Every occurrence day so far (`D1`, `D2`, … through today), read-only —
  /// this is the routine's full history, otherwise only ever shown one day
  /// at a time via [_routineDetailLine] above.
  Widget _routineHistoryList(RoutineConfig routine, DateTime now) {
    final days = occurrenceDatesThrough(routine, now);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final date = days[index];
          final dayNumber = dayNumberFor(routine, date)!;
          return RoutineDayHistoryRow(
            dayLabel: routineDayLabel(dayNumber, date),
            status: occurrenceStatus(routine, date, now: now),
            completedAt: logEntryFor(routine, date)?.completedAt,
          );
        },
      ),
    );
  }

  String _routineStatusLabel(RoutineOccurrenceStatus status) => switch (status) {
    RoutineOccurrenceStatus.notScheduled => 'Not scheduled today',
    RoutineOccurrenceStatus.upcoming => 'Due later today',
    RoutineOccurrenceStatus.dueNow => 'Due today',
    RoutineOccurrenceStatus.dueLate => 'Due late today',
    RoutineOccurrenceStatus.completedEarly => 'Early completion',
    RoutineOccurrenceStatus.completedOnTime => 'Completed',
    RoutineOccurrenceStatus.completedLate => 'Late',
    RoutineOccurrenceStatus.missed => 'Not completed',
  };
}
