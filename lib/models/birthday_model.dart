import '../core/utils/date_labels.dart';

class BirthdayModel {
  const BirthdayModel({
    required this.id,
    required this.name,
    required this.relation,
    required this.month,
    required this.day,
    required this.createdAt,
    required this.updatedAt,
    this.birthYear,
    this.notes = '',
    this.giftIdeas = const [],
    this.reminderDaysBefore = const [7, 0],
  });

  final String id;
  final String name;
  final String relation;

  /// Month/day of the birthday. The year is separate and optional, because
  /// plenty of people know the date but not the year.
  final int month;
  final int day;
  final int? birthYear;

  final String notes;
  final List<String> giftIdeas;

  /// Days before the birthday to remind, e.g. `[7, 0]` = "1 week before" and
  /// "on the day". Purely data — nothing schedules an actual notification
  /// from this yet.
  final List<int> reminderDaysBefore;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get initials => DateLabels.initialsOf(name);

  /// 'March 14'
  String get dateLabel => DateLabels.monthDayLabel(month, day);

  /// The next time this birthday comes round, rolling into next year once
  /// this year's has passed.
  DateTime get nextOccurrence => DateLabels.nextOccurrence(month, day);

  int get daysUntil => DateLabels.daysUntilNextOccurrence(month, day);

  /// 'Today!' / 'Tomorrow' / 'in 12 days' — recomputed, never stored.
  String get daysLabel => DateLabels.daysUntilLabel(daysUntil);

  /// 'Turning 34' when the birth year is known, else ''.
  String get bornLabel {
    final year = birthYear;
    if (year == null) return '';
    return 'Turning ${nextOccurrence.year - year}';
  }

  BirthdayModel copyWith({
    String? name,
    String? relation,
    int? month,
    int? day,
    int? birthYear,
    bool clearBirthYear = false,
    String? notes,
    List<String>? giftIdeas,
    List<int>? reminderDaysBefore,
    DateTime? updatedAt,
  }) => BirthdayModel(
    id: id,
    name: name ?? this.name,
    relation: relation ?? this.relation,
    month: month ?? this.month,
    day: day ?? this.day,
    birthYear: clearBirthYear ? null : (birthYear ?? this.birthYear),
    notes: notes ?? this.notes,
    giftIdeas: giftIdeas ?? this.giftIdeas,
    reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'relation': relation,
    'month': month,
    'day': day,
    'birthYear': birthYear,
    'notes': notes,
    'giftIdeas': giftIdeas,
    'reminderDaysBefore': reminderDaysBefore,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory BirthdayModel.fromJson(Map<String, dynamic> json) {
    final created = _parseDate(json['createdAt']) ?? DateTime.now();
    return BirthdayModel(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      relation: (json['relation'] as String?) ?? '',
      month: (json['month'] as num?)?.toInt() ?? 1,
      day: (json['day'] as num?)?.toInt() ?? 1,
      birthYear: (json['birthYear'] as num?)?.toInt(),
      notes: (json['notes'] as String?) ?? '',
      giftIdeas: [
        for (final g in (json['giftIdeas'] as List<dynamic>? ?? []))
          g.toString(),
      ],
      // Older records only have the two booleans this list replaced —
      // migrate them in place so existing data keeps its reminders.
      reminderDaysBefore: json['reminderDaysBefore'] is List
          ? [
              for (final d in json['reminderDaysBefore'] as List)
                (d as num).toInt(),
            ]
          : [
              if ((json['remindOneWeekBefore'] as bool?) ?? true) 7,
              if ((json['remindOnDay'] as bool?) ?? true) 0,
            ],
      createdAt: created,
      updatedAt: _parseDate(json['updatedAt']) ?? created,
    );
  }
}

DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
