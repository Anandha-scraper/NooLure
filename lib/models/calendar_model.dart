import '../core/utils/date_labels.dart';

enum CalendarView { month, week, agenda }

class CalendarEventModel {
  const CalendarEventModel({
    required this.id,
    required this.title,
    required this.startAt,
    required this.createdAt,
    required this.updatedAt,
    this.endAt,
    this.allDay = false,
    this.colorKey = 'accent',
  });

  final String id;
  final String title;
  final DateTime startAt;
  final DateTime? endAt;
  final bool allDay;

  /// 'accent' | 'accent2' — resolved against the live theme at the usage site
  /// rather than baked into the model, so it follows the accent setting.
  final String colorKey;
  final DateTime createdAt;
  final DateTime updatedAt;

  DateTime get date => DateLabels.dateOnly(startAt);

  /// '9:00 AM – 9:30 AM', '9:00 AM' when open-ended, 'All day' when all-day.
  String get timeRangeLabel {
    if (allDay) return 'All day';
    final start = DateLabels.timeLabel(startAt);
    final end = endAt;
    return end == null ? start : '$start – ${DateLabels.timeLabel(end)}';
  }

  CalendarEventModel copyWith({
    String? title,
    DateTime? startAt,
    DateTime? endAt,
    bool clearEndAt = false,
    bool? allDay,
    String? colorKey,
    DateTime? updatedAt,
  }) => CalendarEventModel(
    id: id,
    title: title ?? this.title,
    startAt: startAt ?? this.startAt,
    endAt: clearEndAt ? null : (endAt ?? this.endAt),
    allDay: allDay ?? this.allDay,
    colorKey: colorKey ?? this.colorKey,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'startAt': startAt.toIso8601String(),
    'endAt': endAt?.toIso8601String(),
    'allDay': allDay,
    'colorKey': colorKey,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    final created = _parseDate(json['createdAt']) ?? DateTime.now();
    return CalendarEventModel(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      startAt: _parseDate(json['startAt']) ?? created,
      endAt: _parseDate(json['endAt']),
      allDay: (json['allDay'] as bool?) ?? false,
      colorKey: (json['colorKey'] as String?) ?? 'accent',
      createdAt: created,
      updatedAt: _parseDate(json['updatedAt']) ?? created,
    );
  }
}

DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
