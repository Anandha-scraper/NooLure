import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/utils/date_labels.dart';
import '../models/routine_config.dart';
import '../models/task_model.dart';
import 'segmented_control.dart';

/// Shared due-date/time, priority, and routine-frequency inputs, used by
/// both the add and edit task screens so the two forms stay in sync.
class DueField extends StatelessWidget {
  const DueField({
    super.key,
    required this.dueAt,
    required this.hasDueTime,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? dueAt;
  final bool hasDueTime;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final due = dueAt;

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.calendar,
              size: 18,
              color: onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                due == null
                    ? 'Someday — tap to pick a date'
                    : (hasDueTime
                          ? DateLabels.dayTimeLabel(due)
                          : DateLabels.dayLabel(due)),
                style: TextStyle(
                  fontSize: 14,
                  color: onSurface.withValues(alpha: due == null ? 0.5 : 1),
                ),
              ),
            ),
            if (due != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  LucideIcons.x,
                  size: 18,
                  color: onSurface.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// True when [dueAt] has already passed — day-precise when [hasDueTime] is
/// false (a date-only pick is only "in the past" once its whole day has),
/// exact-instant precise otherwise.
bool isDueDateInPast(DateTime dueAt, bool hasDueTime, {DateTime? now}) {
  final n = now ?? DateTime.now();
  return hasDueTime
      ? dueAt.isBefore(n)
      : DateLabels.dateOnly(dueAt).isBefore(DateLabels.dateOnly(n));
}

class PriorityField extends StatelessWidget {
  const PriorityField({super.key, required this.value, required this.onChanged});

  final TaskPriority value;
  final ValueChanged<TaskPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppSegmentedControl<TaskPriority>(
      value: value,
      onChanged: onChanged,
      options: const [
        (TaskPriority.low, 'Low'),
        (TaskPriority.medium, 'Medium'),
        (TaskPriority.high, 'High'),
        (TaskPriority.urgent, 'Urgent'),
      ],
    );
  }
}

class RoutineFrequencyField extends StatelessWidget {
  const RoutineFrequencyField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final RoutineFrequency value;
  final ValueChanged<RoutineFrequency> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppSegmentedControl<RoutineFrequency>(
      value: value,
      onChanged: onChanged,
      options: const [
        (RoutineFrequency.daily, 'Daily'),
        (RoutineFrequency.custom, 'Custom'),
      ],
    );
  }
}

/// The result of [pickTaskDueDate]: the picked date (always midnight when
/// [hasTime] is false), and whether the user chose to attach a specific time.
typedef DueDatePick = ({DateTime dueAt, bool hasTime});

/// Shows the date picker, then asks whether to attach a specific time —
/// dismissing that ask (or the time picker itself) means "no specific time"
/// rather than silently defaulting to 9:00 AM. Returns null if the user
/// cancelled the date step.
Future<DueDatePick?> pickTaskDueDate(
  BuildContext context,
  DateTime? current, {
  bool currentHasTime = true,
}) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final initial = current ?? now;
  // Past dates aren't offered for new/undated tasks, but an already-overdue
  // task being edited keeps its own date as the lower bound — otherwise
  // initialDate would fall outside [firstDate, lastDate] and throw.
  final firstDate = initial.isBefore(today)
      ? DateTime(initial.year, initial.month, initial.day)
      : today;
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: firstDate,
    lastDate: DateTime(now.year + 5),
  );
  if (date == null || !context.mounted) return null;

  final wantsTime = await _askIncludeTime(context);
  if (!context.mounted || wantsTime == null) return null;

  if (!wantsTime) {
    return (dueAt: DateTime(date.year, date.month, date.day), hasTime: false);
  }

  final time = await showTimePicker(
    context: context,
    initialTime: currentHasTime
        ? TimeOfDay.fromDateTime(current ?? now)
        : const TimeOfDay(hour: 9, minute: 0),
  );
  if (!context.mounted) return null;
  if (time == null) {
    return (dueAt: DateTime(date.year, date.month, date.day), hasTime: false);
  }
  return (
    dueAt: DateTime(date.year, date.month, date.day, time.hour, time.minute),
    hasTime: true,
  );
}

Future<bool?> _askIncludeTime(BuildContext context) => showDialog<bool>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: const Text('Add a time?'),
    content: const Text(
      'Pick a specific time for this due date, or leave it for the whole day.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(false),
        child: const Text('No specific time'),
      ),
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(true),
        child: const Text('Set a time'),
      ),
    ],
  ),
);
