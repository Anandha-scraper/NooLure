import '../core/utils/date_labels.dart';

enum TaskPriority { low, medium, high, urgent }

extension TaskPriorityLabel on TaskPriority {
  String get label => switch (this) {
    TaskPriority.low => 'Low',
    TaskPriority.medium => 'Medium',
    TaskPriority.high => 'High',
    TaskPriority.urgent => 'Urgent',
  };

  static TaskPriority fromLabel(String? label) => switch (label) {
    'Urgent' => TaskPriority.urgent,
    'High' => TaskPriority.high,
    'Medium' => TaskPriority.medium,
    _ => TaskPriority.low,
  };
}

enum TaskRepeat { none, daily, weekly, monthly, yearly }

extension TaskRepeatLabel on TaskRepeat {
  String get label => switch (this) {
    TaskRepeat.none => 'Does not repeat',
    TaskRepeat.daily => 'Daily',
    TaskRepeat.weekly => 'Weekly',
    TaskRepeat.monthly => 'Monthly',
    TaskRepeat.yearly => 'Yearly',
  };

  static TaskRepeat fromLabel(String? label) => switch (label) {
    'Daily' => TaskRepeat.daily,
    'Weekly' => TaskRepeat.weekly,
    'Monthly' => TaskRepeat.monthly,
    'Yearly' => TaskRepeat.yearly,
    _ => TaskRepeat.none,
  };
}

class SubtaskModel {
  const SubtaskModel({
    required this.id,
    required this.title,
    this.done = false,
  });

  final String id;
  final String title;
  final bool done;

  SubtaskModel copyWith({String? title, bool? done}) =>
      SubtaskModel(id: id, title: title ?? this.title, done: done ?? this.done);

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};

  factory SubtaskModel.fromJson(Map<String, dynamic> json) => SubtaskModel(
    id: json['id'] as String,
    title: (json['title'] as String?) ?? '',
    done: (json['done'] as bool?) ?? false,
  );
}

class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.priority,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.dueAt,
    this.done = false,
    this.subtasks = const [],
    this.repeat = TaskRepeat.none,
  });

  final String id;
  final String title;

  /// When the task is due. Null means "someday" — no date set.
  final DateTime? dueAt;
  final TaskPriority priority;
  final String category;
  final bool done;
  final List<SubtaskModel> subtasks;
  final TaskRepeat repeat;
  final DateTime createdAt;

  /// Drives last-write-wins when a remote copy comes back from sync.
  final DateTime updatedAt;

  /// 'Today' / 'Tomorrow' / 'Fri, Mar 3', recomputed on every build.
  String get dateLabel =>
      dueAt == null ? 'Someday' : DateLabels.dayLabel(dueAt!);

  /// '9:00 AM', or empty when no due time is set.
  String get timeLabel => dueAt == null ? '' : DateLabels.timeLabel(dueAt!);

  bool get isDueToday =>
      dueAt != null && DateLabels.isSameDay(dueAt!, DateTime.now());

  bool get isOverdue =>
      dueAt != null && !done && dueAt!.isBefore(DateTime.now());

  TaskModel copyWith({
    String? title,
    DateTime? dueAt,
    bool clearDueAt = false,
    TaskPriority? priority,
    String? category,
    bool? done,
    List<SubtaskModel>? subtasks,
    TaskRepeat? repeat,
    DateTime? updatedAt,
  }) => TaskModel(
    id: id,
    title: title ?? this.title,
    dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
    priority: priority ?? this.priority,
    category: category ?? this.category,
    done: done ?? this.done,
    subtasks: subtasks ?? this.subtasks,
    repeat: repeat ?? this.repeat,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'dueAt': dueAt?.toIso8601String(),
    'priority': priority.label,
    'category': category,
    'done': done,
    'repeat': repeat.label,
    'subtasks': subtasks.map((s) => s.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final created = _parseDate(json['createdAt']) ?? DateTime.now();
    return TaskModel(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      dueAt: _parseDate(json['dueAt']),
      priority: TaskPriorityLabel.fromLabel(json['priority'] as String?),
      category: (json['category'] as String?) ?? 'General',
      done: (json['done'] as bool?) ?? false,
      repeat: TaskRepeatLabel.fromLabel(json['repeat'] as String?),
      subtasks: [
        for (final s in (json['subtasks'] as List<dynamic>? ?? []))
          SubtaskModel.fromJson(Map<String, dynamic>.from(s as Map)),
      ],
      createdAt: created,
      updatedAt: _parseDate(json['updatedAt']) ?? created,
    );
  }
}

DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
