import '../../models/routine_config.dart';
import 'date_labels.dart';

enum RoutineOccurrenceStatus {
  /// [date] isn't a valid occurrence day for this routine at all.
  notScheduled,

  /// Occurrence day; the preferred window (if any) hasn't started yet.
  upcoming,

  /// Occurrence day; within the window (or no window is set), not done yet.
  dueNow,

  /// Occurrence day; the preferred window has closed but the calendar day
  /// hasn't — still completable (as "late"), not yet permanently missed.
  dueLate,

  /// Occurrence day, marked done before the preferred window even opened.
  /// Unreachable unless [RoutineConfig.preferredStartMinute] is set — with no
  /// preferred start the window opens at midnight, which no real completion
  /// timestamp can precede.
  completedEarly,
  completedOnTime,
  completedLate,

  /// Occurrence day; the calendar day itself elapsed with nothing logged —
  /// permanently closed, can never be completed retroactively.
  missed,
}

bool isOccurrenceDate(RoutineConfig config, DateTime date) {
  final d = DateLabels.dateOnly(date);
  return switch (config.frequency) {
    RoutineFrequency.daily =>
      !d.isBefore(config.startDate) && !d.isAfter(config.endDate),
    RoutineFrequency.custom => config.customDates.any(
      (c) => DateLabels.isSameDay(c, d),
    ),
  };
}

/// 1-based occurrence index for [date], or null if it isn't an occurrence
/// day at all. For daily routines this is the day count since [RoutineConfig.startDate];
/// for custom routines it's the date's position in the sorted custom-dates list.
int? dayNumberFor(RoutineConfig config, DateTime date) {
  final d = DateLabels.dateOnly(date);
  if (!isOccurrenceDate(config, d)) return null;
  return switch (config.frequency) {
    RoutineFrequency.daily => d.difference(config.startDate).inDays + 1,
    RoutineFrequency.custom => () {
      final sorted = [...config.customDates]..sort();
      return sorted.indexWhere((c) => DateLabels.isSameDay(c, d)) + 1;
    }(),
  };
}

RoutineDayEntry? logEntryFor(RoutineConfig config, DateTime date) {
  for (final e in config.log) {
    if (DateLabels.isSameDay(e.date, date)) return e;
  }
  return null;
}

/// Start of [date]'s window: [RoutineConfig.preferredStartMinute] if set,
/// else midnight.
DateTime occurrenceWindowStart(RoutineConfig config, DateTime date) {
  final d = DateLabels.dateOnly(date);
  return config.preferredStartMinute == null
      ? d
      : d.add(Duration(minutes: config.preferredStartMinute!));
}

/// Exclusive end-of-window cutoff: [RoutineConfig.preferredEndMinute] if
/// set, else the start of the next calendar day (end-of-day fallback).
DateTime occurrenceWindowEnd(RoutineConfig config, DateTime date) {
  final d = DateLabels.dateOnly(date);
  return config.preferredEndMinute == null
      ? d.add(const Duration(days: 1))
      : d.add(Duration(minutes: config.preferredEndMinute!));
}

RoutineOccurrenceStatus occurrenceStatus(
  RoutineConfig config,
  DateTime date, {
  DateTime? now,
}) {
  final d = DateLabels.dateOnly(date);
  if (!isOccurrenceDate(config, d)) return RoutineOccurrenceStatus.notScheduled;

  final entry = logEntryFor(config, d);
  final windowStart = occurrenceWindowStart(config, d);
  final windowEnd = occurrenceWindowEnd(config, d);

  if (entry?.completedAt != null) {
    final completedAt = entry!.completedAt!;
    if (completedAt.isBefore(windowStart)) {
      return RoutineOccurrenceStatus.completedEarly;
    }
    return completedAt.isBefore(windowEnd)
        ? RoutineOccurrenceStatus.completedOnTime
        : RoutineOccurrenceStatus.completedLate;
  }

  final nowResolved = now ?? DateTime.now();
  final dayEnd = d.add(const Duration(days: 1));
  if (nowResolved.isBefore(windowStart)) return RoutineOccurrenceStatus.upcoming;
  // Anchored to the calendar day, not the preferred window — a day only
  // becomes permanently missed once it fully elapses, not the moment the
  // window closes (when no window is set, windowEnd already equals dayEnd,
  // so this collapses to the same instant, same as before).
  if (!nowResolved.isBefore(dayEnd)) return RoutineOccurrenceStatus.missed;
  if (!nowResolved.isBefore(windowEnd)) return RoutineOccurrenceStatus.dueLate;
  return RoutineOccurrenceStatus.dueNow;
}

RoutineOccurrenceStatus todaysOccurrence(RoutineConfig config, {DateTime? now}) {
  final n = now ?? DateTime.now();
  return occurrenceStatus(config, n, now: n);
}

/// Every occurrence date from the routine's start through [through]
/// (inclusive), sorted ascending — the day-by-day history a UI iterates to
/// show "D1, D2, …" up to today.
List<DateTime> occurrenceDatesThrough(RoutineConfig config, DateTime through) {
  final limit = DateLabels.dateOnly(through);
  return switch (config.frequency) {
    RoutineFrequency.daily => [
      for (
        var d = config.startDate;
        !d.isAfter(limit) && !d.isAfter(config.endDate);
        d = d.add(const Duration(days: 1))
      )
        d,
    ],
    RoutineFrequency.custom =>
      ([...config.customDates]..sort())
          .where((c) => !DateLabels.dateOnly(c).isAfter(limit))
          .toList(),
  };
}

/// 'D1 - 05/07' — the day-number + date label used in the Home history list.
String routineDayLabel(int dayNumber, DateTime date) =>
    'D$dayNumber - ${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}';

/// null when no window is set, else e.g. '6:00 AM – 8:00 PM' (or just one
/// side if only a start or only an end was picked).
String? preferredWindowLabel(RoutineConfig config) {
  if (config.preferredStartMinute == null && config.preferredEndMinute == null) {
    return null;
  }
  final start = config.preferredStartMinute == null
      ? null
      : _minuteLabel(config.preferredStartMinute!);
  final end = config.preferredEndMinute == null
      ? null
      : _minuteLabel(config.preferredEndMinute!);
  if (start != null && end != null) return '$start – $end';
  return start ?? end;
}

String _minuteLabel(int minute) =>
    DateLabels.timeLabel(DateTime(2024, 1, 1, minute ~/ 60, minute % 60));

int totalOccurrenceCount(RoutineConfig config) => switch (config.frequency) {
  RoutineFrequency.daily => config.endDate.difference(config.startDate).inDays + 1,
  RoutineFrequency.custom => config.customDates.length,
};

int completedOccurrenceCount(RoutineConfig config) =>
    config.log.where((e) => e.completedAt != null).length;
