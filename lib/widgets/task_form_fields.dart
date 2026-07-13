import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/utils/date_labels.dart';
import '../models/task_model.dart';
import 'segmented_control.dart';

/// Shared due-date/time, priority, and repeat inputs, used by both the add
/// and edit task screens so the two forms stay in sync.
class DueField extends StatelessWidget {
  const DueField({
    super.key,
    required this.dueAt,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? dueAt;
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
                    : DateLabels.dayTimeLabel(due),
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

class RepeatField extends StatelessWidget {
  const RepeatField({super.key, required this.value, required this.onChanged});

  final TaskRepeat value;
  final ValueChanged<TaskRepeat> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppSegmentedControl<TaskRepeat>(
      value: value,
      onChanged: onChanged,
      options: const [
        (TaskRepeat.none, 'Never'),
        (TaskRepeat.daily, 'Daily'),
        (TaskRepeat.weekly, 'Weekly'),
        (TaskRepeat.monthly, 'Monthly'),
      ],
    );
  }
}

/// Shows the date picker then the time picker, returning the combined
/// [DateTime], or null if the user cancelled the date step.
Future<DateTime?> pickTaskDueDate(
  BuildContext context,
  DateTime? current,
) async {
  final now = DateTime.now();
  final date = await showDatePicker(
    context: context,
    initialDate: current ?? now,
    firstDate: DateTime(now.year - 1),
    lastDate: DateTime(now.year + 5),
  );
  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(current ?? now),
  );
  if (!context.mounted) return null;

  return DateTime(date.year, date.month, date.day, time?.hour ?? 9, time?.minute ?? 0);
}
