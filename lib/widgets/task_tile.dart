import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/constants/app_colors.dart';
import '../models/task_model.dart';
import 'check_circle.dart';
import 'tag_chip.dart';

/// Task row card — `.card.elev-sm` with a checkable circle, title, and meta
/// chips. Reused compactly on Home and fully (with drag handle) on Tasks.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.onToggle,
    this.onTap,
    this.onLongPress,
    this.dense = false,
    this.showDragHandle = false,
    this.titleOverride,
    this.metaOverride,
    this.metaIsAlert = false,
    this.checkedOverride,
  });

  final TaskModel task;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool dense;
  final bool showDragHandle;

  /// Overrides the title text — used for a routine's "Day N · <title>" row.
  final String? titleOverride;

  /// Overrides the date/time meta line — used for a routine's preferred
  /// window ("Due by 8:00 PM") instead of the plain due-date/time label.
  final String? metaOverride;

  /// Only consulted when [metaOverride] is set — whether that override text
  /// should render in the error color (e.g. a routine occurrence that's
  /// overdue for today).
  final bool metaIsAlert;

  /// Overrides the checked state shown by the leading circle — used for a
  /// routine row, whose top-level `task.done` is unused/meaningless.
  final bool? checkedOverride;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final checked = checkedOverride ?? task.done;

    // The shadow belongs on the filled box, not on a transparent child inside
    // it — the previous version drew shadowSm on an inner Container with no
    // color, so the elevation never read.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppColors.shadowSm(theme.brightness),
      ),
      child: Material(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 12 : 14,
              vertical: dense ? 9 : 14,
            ),
            child: Row(
              children: [
                CheckCircle(checked: checked, onTap: onToggle),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titleOverride ?? task.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          color: onSurface,
                          decoration: checked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            metaOverride ??
                                (task.timeLabel.isEmpty
                                    ? task.dateLabel
                                    : '${task.dateLabel} · ${task.timeLabel}'),
                            style: TextStyle(
                              fontSize: 11,
                              color: (metaOverride != null ? metaIsAlert : task.isMissed)
                                  ? theme.colorScheme.error
                                  : onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                          if (!dense) TagChip(task.category),
                          TagChip(
                            task.priority.label,
                            variant: switch (task.priority) {
                              TaskPriority.urgent ||
                              TaskPriority.high => TagVariant.accent,
                              TaskPriority.medium => TagVariant.accent2,
                              TaskPriority.low => TagVariant.neutral,
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (showDragHandle) ...[
                  const SizedBox(width: 8),
                  Icon(
                    LucideIcons.gripVertical,
                    size: 16,
                    color: onSurface.withValues(alpha: 0.3),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
