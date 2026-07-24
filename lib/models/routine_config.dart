enum RoutineFrequency { daily, custom }

extension RoutineFrequencyLabel on RoutineFrequency {
  String get label => switch (this) {
    RoutineFrequency.daily => 'Daily',
    RoutineFrequency.custom => 'Custom',
  };

  static RoutineFrequency fromLabel(String? label) =>
      label == 'Custom' ? RoutineFrequency.custom : RoutineFrequency.daily;
}

/// One calendar day's completion record for a routine. Only ever written
/// when the user actually marks that day done (on-time or late) — a day
/// with no entry whose window has elapsed is computed as "missed" live by
/// `routine_occurrence.dart`, never persisted as such.
class RoutineDayEntry {
  const RoutineDayEntry({
    required this.date,
    required this.dayNumber,
    this.completedAt,
  });

  /// Date-only (00:00) — the calendar day this entry belongs to.
  final DateTime date;

  /// 1-based occurrence index (Day 1, Day 2, …).
  final int dayNumber;
  final DateTime? completedAt;

  bool get isDone => completedAt != null;

  RoutineDayEntry copyWith({
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) => RoutineDayEntry(
    date: date,
    dayNumber: dayNumber,
    completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
  );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'dayNumber': dayNumber,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory RoutineDayEntry.fromJson(Map<String, dynamic> json) =>
      RoutineDayEntry(
        date: _parseDate(json['date']) ?? DateTime.now(),
        dayNumber: (json['dayNumber'] as num?)?.toInt() ?? 0,
        completedAt: _parseDate(json['completedAt']),
      );
}

/// A task's routine schedule. [startDate]/[endDate] are snapshotted
/// date-only bounds (the owning task's creation day and due day
/// respectively), so every pure function in `routine_occurrence.dart` only
/// ever needs `(RoutineConfig, DateTime)` — no back-reference to TaskModel.
class RoutineConfig {
  const RoutineConfig({
    required this.frequency,
    required this.startDate,
    required this.endDate,
    this.customDates = const [],
    this.preferredStartMinute,
    this.preferredEndMinute,
    this.log = const [],
  });

  final RoutineFrequency frequency;

  /// Date-only. Ignored for [RoutineFrequency.custom] (kept only so a
  /// frequency switch doesn't lose the original start), but the daily
  /// occurrence range and day-numbering both key off it directly.
  final DateTime startDate;

  /// Date-only — mirrors the owning task's due date. Custom dates must all
  /// fall on/before this day.
  final DateTime endDate;

  /// Date-only, only meaningful for [RoutineFrequency.custom].
  final List<DateTime> customDates;

  /// Minutes since midnight (0-1439), or null for "no preferred window" —
  /// falls back to end-of-calendar-day semantics when unset.
  final int? preferredStartMinute;
  final int? preferredEndMinute;

  final List<RoutineDayEntry> log;

  RoutineConfig copyWith({
    RoutineFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    List<DateTime>? customDates,
    int? preferredStartMinute,
    bool clearPreferredStartMinute = false,
    int? preferredEndMinute,
    bool clearPreferredEndMinute = false,
    List<RoutineDayEntry>? log,
  }) => RoutineConfig(
    frequency: frequency ?? this.frequency,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    customDates: customDates ?? this.customDates,
    preferredStartMinute: clearPreferredStartMinute
        ? null
        : (preferredStartMinute ?? this.preferredStartMinute),
    preferredEndMinute: clearPreferredEndMinute
        ? null
        : (preferredEndMinute ?? this.preferredEndMinute),
    log: log ?? this.log,
  );

  Map<String, dynamic> toJson() => {
    'frequency': frequency.label,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'customDates': customDates.map((d) => d.toIso8601String()).toList(),
    'preferredStartMinute': preferredStartMinute,
    'preferredEndMinute': preferredEndMinute,
    'log': log.map((e) => e.toJson()).toList(),
  };

  factory RoutineConfig.fromJson(Map<String, dynamic> json) => RoutineConfig(
    frequency: RoutineFrequencyLabel.fromLabel(json['frequency'] as String?),
    startDate: _parseDate(json['startDate']) ?? DateTime.now(),
    endDate: _parseDate(json['endDate']) ?? DateTime.now(),
    customDates:
        (json['customDates'] as List<dynamic>?)
            ?.map((d) => DateTime.tryParse(d as String))
            .whereType<DateTime>()
            .toList() ??
        const [],
    preferredStartMinute: (json['preferredStartMinute'] as num?)?.toInt(),
    preferredEndMinute: (json['preferredEndMinute'] as num?)?.toInt(),
    log:
        (json['log'] as List<dynamic>?)
            ?.map((e) => RoutineDayEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );
}

DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
