import 'package:intl/intl.dart';

/// Human-readable labels derived from real `DateTime`s at render time.
///
/// These used to be stored on the models as plain strings ('Today',
/// 'just now', 'in 12 days'), which froze them at whatever the value was on
/// the day the record was written. Computing them here instead means a task
/// created yesterday stops saying "Today" tomorrow.
class DateLabels {
  DateLabels._();

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// 'Today' / 'Tomorrow' / 'Yesterday', else 'Fri, Mar 3' (plus the year
  /// once the date leaves the current one).
  static String dayLabel(DateTime date, {DateTime? now}) {
    final today = dateOnly(now ?? DateTime.now());
    final day = dateOnly(date);
    final diff = day.difference(today).inDays;

    return switch (diff) {
      0 => 'Today',
      1 => 'Tomorrow',
      -1 => 'Yesterday',
      _ when day.year == today.year => DateFormat('EEE, MMM d').format(day),
      _ => DateFormat('MMM d, y').format(day),
    };
  }

  /// '9:00 AM'
  static String timeLabel(DateTime date) => DateFormat.jm().format(date);

  /// 'Today · 9:00 AM'
  static String dayTimeLabel(DateTime date, {DateTime? now}) =>
      '${dayLabel(date, now: now)} · ${timeLabel(date)}';

  /// Backwards-looking: 'just now' / '5m ago' / '2h ago' / '3d ago', falling
  /// back to an absolute date past a week.
  static String relativeLabel(DateTime date, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final elapsed = ref.difference(date);

    if (elapsed.isNegative) return 'just now';
    if (elapsed.inMinutes < 1) return 'just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
    if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
    if (elapsed.inDays < 7) return '${elapsed.inDays}d ago';
    if (date.year == ref.year) return DateFormat('MMM d').format(date);
    return DateFormat('MMM d, y').format(date);
  }

  /// Forwards-looking: 'Today!' / 'Tomorrow' / 'in 12 days'.
  static String daysUntilLabel(int days) => switch (days) {
    <= 0 => 'Today!',
    1 => 'Tomorrow',
    _ => 'in $days days',
  };

  /// The next time a recurring month/day lands, rolling into next year once
  /// this year's has passed. Feb 29 in a common year is treated as Mar 1.
  static DateTime nextOccurrence(int month, int day, {DateTime? now}) {
    final today = dateOnly(now ?? DateTime.now());
    final thisYear = _clampToMonth(today.year, month, day);
    if (!thisYear.isBefore(today)) return thisYear;
    return _clampToMonth(today.year + 1, month, day);
  }

  static int daysUntilNextOccurrence(int month, int day, {DateTime? now}) {
    final today = dateOnly(now ?? DateTime.now());
    return nextOccurrence(month, day, now: today).difference(today).inDays;
  }

  /// 'March 14'
  static String monthDayLabel(int month, int day) =>
      DateFormat('MMMM d').format(DateTime(2024, month, day));

  /// DateTime(y, 2, 29) silently rolls to Mar 1 in a common year, which is
  /// the behaviour we want for a Feb-29 birthday anyway.
  static DateTime _clampToMonth(int year, int month, int day) =>
      DateTime(year, month, day);

  /// Initials from a display name: 'Maya Kapoor' -> 'MK'.
  static String initialsOf(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
