import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/date_labels.dart';
import '../core/utils/routine_occurrence.dart';

/// One closed day in a routine's history: a status glyph + label ("Early
/// completion" / "Completed" / "Late" / "Not completed") plus the day label
/// and, once completed, the time it was marked — read-only, since a closed
/// day can never be retroactively completed (enforced in
/// `TaskProvider.completeRoutineOccurrence`).
class RoutineDayHistoryRow extends StatelessWidget {
  const RoutineDayHistoryRow({
    super.key,
    required this.dayLabel,
    required this.status,
    required this.completedAt,
  });

  final String dayLabel;
  final RoutineOccurrenceStatus status;
  final DateTime? completedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final brightness = theme.brightness;

    final IconData icon;
    final Color color;
    final String? statusLabel;
    switch (status) {
      case RoutineOccurrenceStatus.completedEarly:
        icon = LucideIcons.checkCircle2;
        color = Colors.green.shade600;
        statusLabel = 'Early completion';
      case RoutineOccurrenceStatus.completedOnTime:
        icon = LucideIcons.checkCircle2;
        color = Colors.green.shade600;
        statusLabel = 'Completed';
      case RoutineOccurrenceStatus.completedLate:
        icon = LucideIcons.checkCircle2;
        color = AppColors.accentInk(AppColors.highlight, brightness);
        statusLabel = 'Late';
      case RoutineOccurrenceStatus.missed:
        icon = LucideIcons.xCircle;
        color = theme.colorScheme.error;
        statusLabel = 'Not completed';
      // Not reached for a genuinely past day (occurrenceStatus always
      // resolves to one of the four cases above once its day has elapsed)
      // — kept only so this switch stays exhaustive.
      case RoutineOccurrenceStatus.notScheduled:
      case RoutineOccurrenceStatus.upcoming:
      case RoutineOccurrenceStatus.dueNow:
      case RoutineOccurrenceStatus.dueLate:
        icon = LucideIcons.clock;
        color = onSurface.withValues(alpha: 0.4);
        statusLabel = null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: AppColors.shadowSm(brightness),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dayLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
              if (statusLabel != null) ...[
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (completedAt != null)
                Text(
                  DateLabels.compactTimeLabel(completedAt!),
                  style: TextStyle(fontSize: 11.5, color: color),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
