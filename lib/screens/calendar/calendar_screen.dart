import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/date_labels.dart';
import '../../models/calendar_model.dart';
import '../../providers/calendar_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/segmented_control.dart';

const _weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CalendarProvider>();
    final onSurface = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    final month = provider.displayedMonth;
    final today = provider.today;
    final selected = _selectedDay ?? today;

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = DateTime(month.year, month.month, 1).weekday % 7;
    final totalCells = ((leadingBlanks + daysInMonth) / 7).ceil() * 7;

    final dayEvents = provider.eventsOn(selected);

    return AppScaffold(
      title: 'Calendar',
      drawerRoute: AppRoutes.calendar,
      titleStyle: TextStyles.h2(color: onSurface),
      floatingActionButton: AppFab(
        onPressed: () => _addEvent(context, selected),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.chevronLeft, size: 20),
                tooltip: 'Previous month',
                onPressed: provider.previousMonth,
              ),
              Text(
                DateFormat('MMMM yyyy').format(month),
                style: TextStyles.h4(color: onSurface),
              ),
              IconButton(
                icon: const Icon(LucideIcons.chevronRight, size: 20),
                tooltip: 'Next month',
                onPressed: provider.nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 18),
          AppSegmentedControl<CalendarView>(
            value: provider.selectedView,
            onChanged: provider.setView,
            options: const [
              (CalendarView.month, 'Month'),
              (CalendarView.week, 'Week'),
              (CalendarView.agenda, 'Agenda'),
            ],
          ),
          const SizedBox(height: 18),
          if (provider.selectedView != CalendarView.month)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  '${provider.selectedView == CalendarView.week ? 'Week' : 'Agenda'} view coming soon',
                  style: TextStyle(
                    fontSize: 13,
                    color: onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
          else ...[
            Row(
              children: [
                for (final label in _weekdayLabels)
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, i) {
                final dayNum = i - leadingBlanks + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const SizedBox.shrink();
                }

                final date = DateTime(month.year, month.month, dayNum);
                final isToday = DateLabels.isSameDay(date, today);
                final isSelected = DateLabels.isSameDay(date, selected);
                final hasEvent = provider.hasEvent(date);

                final fill = isToday
                    ? primary
                    : isSelected
                    ? AppColors.softFill(primary, theme.brightness)
                    : null;
                final ink = isToday
                    ? theme.colorScheme.onPrimary
                    : isSelected
                    ? AppColors.softInk(primary, theme.brightness)
                    : onSurface;

                return Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDay = date),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: fill,
                      ),
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '$dayNum',
                            style: TextStyle(fontSize: 13, color: ink),
                          ),
                          if (hasEvent)
                            Positioned(
                              bottom: 2,
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isToday
                                      ? theme.colorScheme.onPrimary
                                      : primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            Divider(color: theme.dividerColor),
            const SizedBox(height: 18),
            Text(
              DateLabels.dayLabel(selected),
              style: TextStyles.sectionLabel(color: onSurface),
            ),
            const SizedBox(height: 12),
            if (dayEvents.isEmpty)
              Text(
                'No events',
                style: TextStyle(
                  fontSize: 13,
                  color: onSurface.withValues(alpha: 0.5),
                ),
              ),
            for (final event in dayEvents)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: _EventRow(
                  event: event,
                  onDelete: () => provider.deleteEvent(event.id),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _addEvent(BuildContext context, DateTime day) async {
    final provider = context.read<CalendarProvider>();
    final controller = TextEditingController();

    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New event · ${DateLabels.dayLabel(day)}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Design review'),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.isEmpty || !mounted) return;

    final time = await showTimePicker(
      context: this.context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (!mounted) return;

    await provider.addEvent(
      title: title,
      startAt: DateTime(
        day.year,
        day.month,
        day.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      ),
      allDay: time == null,
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.onDelete});

  final CalendarEventModel event;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    // Resolved against the live theme rather than baked into the model, so
    // event bars follow the accent setting.
    final color = event.colorKey == 'accent2'
        ? AppColors.accent2
        : theme.colorScheme.primary;

    return Row(
      children: [
        Container(
          width: 5,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.5, color: onSurface),
              ),
              Text(
                event.timeRangeLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(LucideIcons.trash2, size: 16),
          tooltip: 'Delete event',
          color: onSurface.withValues(alpha: 0.5),
          onPressed: onDelete,
        ),
      ],
    );
  }
}
