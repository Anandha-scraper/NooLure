import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/text_styles.dart';
import '../core/utils/date_labels.dart';
import '../models/routine_config.dart';
import 'tag_chip.dart';
import 'task_form_fields.dart';

/// The optional "Routine" section on the add/edit task screens — a toggle
/// that reveals frequency (daily/custom-dates) and an optional preferred
/// daily time window. Fully controlled by the parent screen, same
/// stateless-and-callback-driven shape as [DueField]/[PriorityField].
class RoutineSection extends StatelessWidget {
  const RoutineSection({
    super.key,
    required this.enabled,
    required this.onToggle,
    required this.frequency,
    required this.onFrequencyChanged,
    required this.customDates,
    required this.onCustomDatesChanged,
    required this.preferredStart,
    required this.onPreferredStartChanged,
    required this.preferredEnd,
    required this.onPreferredEndChanged,
    required this.dueAt,
    required this.onMissingDueDate,
  });

  final bool enabled;
  final ValueChanged<bool> onToggle;
  final RoutineFrequency frequency;
  final ValueChanged<RoutineFrequency> onFrequencyChanged;
  final List<DateTime> customDates;
  final ValueChanged<List<DateTime>> onCustomDatesChanged;
  final TimeOfDay? preferredStart;
  final ValueChanged<TimeOfDay?> onPreferredStartChanged;
  final TimeOfDay? preferredEnd;
  final ValueChanged<TimeOfDay?> onPreferredEndChanged;

  /// The task's current due date — for Custom, bounds which dates can be
  /// picked; when null, tapping "+ Add date" (or the toggle itself) defers
  /// to [onMissingDueDate] instead of opening a picker.
  final DateTime? dueAt;
  final VoidCallback onMissingDueDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Routine', style: TextStyles.sectionLabel(color: onSurface)),
            const Spacer(),
            Switch(value: enabled, onChanged: onToggle),
          ],
        ),
        if (enabled) ...[
          const SizedBox(height: 8),
          RoutineFrequencyField(value: frequency, onChanged: onFrequencyChanged),
          if (frequency == RoutineFrequency.custom) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in customDates)
                  TagChip(
                    '${DateLabels.dayLabel(d)} ✕',
                    variant: TagVariant.accent,
                    onTap: () => onCustomDatesChanged(
                      customDates.where((x) => !DateLabels.isSameDay(x, d)).toList(),
                    ),
                  ),
                TagChip(
                  '+ Add date',
                  onTap: () => _addCustomDate(context),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Preferred time (optional)',
            style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TimeChip(
                  label: preferredStart == null
                      ? 'No start time'
                      : 'From ${preferredStart!.format(context)}',
                  onTap: () => _pickTime(context, onPreferredStartChanged),
                  onClear: preferredStart == null
                      ? null
                      : () => onPreferredStartChanged(null),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimeChip(
                  label: preferredEnd == null
                      ? 'No end time'
                      : 'Until ${preferredEnd!.format(context)}',
                  onTap: () => _pickTime(context, onPreferredEndChanged),
                  onClear: preferredEnd == null
                      ? null
                      : () => onPreferredEndChanged(null),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _addCustomDate(BuildContext context) async {
    final due = dueAt;
    if (due == null) {
      onMissingDueDate();
      return;
    }
    final now = DateTime.now();
    final today = DateLabels.dateOnly(now);
    final lastDate = DateLabels.dateOnly(due);
    if (lastDate.isBefore(today)) return; // due date already passed
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: lastDate,
    );
    if (picked == null) return;
    final dateOnly = DateLabels.dateOnly(picked);
    if (customDates.any((d) => DateLabels.isSameDay(d, dateOnly))) return;
    onCustomDatesChanged([...customDates, dateOnly]);
  }

  Future<void> _pickTime(
    BuildContext context,
    ValueChanged<TimeOfDay?> onChanged,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) onChanged(picked);
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.onTap, this.onClear});

  final String label;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 13, color: onSurface.withValues(alpha: 0.85)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(LucideIcons.x, size: 16, color: onSurface.withValues(alpha: 0.6)),
              ),
          ],
        ),
      ),
    );
  }
}
