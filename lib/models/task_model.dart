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
    this.description = '',
    this.repeat = TaskRepeat.none,
    this.deletedAt,
    this.archivedAt,
  });

  final String id;
  final String title;

  /// When the task is due. Null means "someday" — no date set.
  final DateTime? dueAt;
  final TaskPriority priority;
  final String category;
  final bool done;
  final String description;
  final TaskRepeat repeat;
  final DateTime createdAt;

  /// Drives last-write-wins when a remote copy comes back from sync.
  final DateTime updatedAt;

  /// Non-null when the task has been moved to trash.
  final DateTime? deletedAt;

  /// Non-null when the task has been archived — hidden from the main list
  /// without being deleted, same nullable-timestamp shape as [deletedAt].
  final DateTime? archivedAt;

  bool get isDeleted => deletedAt != null;
  bool get isArchived => archivedAt != null;

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
    String? description,
    TaskRepeat? repeat,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
  }) => TaskModel(
    id: id,
    title: title ?? this.title,
    dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
    priority: priority ?? this.priority,
    category: category ?? this.category,
    done: done ?? this.done,
    description: description ?? this.description,
    repeat: repeat ?? this.repeat,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
    deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'dueAt': dueAt?.toIso8601String(),
    'priority': priority.label,
    'category': category,
    'done': done,
    'description': description,
    'repeat': repeat.label,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'deletedAt': deletedAt?.toIso8601String(),
    'archivedAt': archivedAt?.toIso8601String(),
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
      description: (json['description'] as String?) ?? '',
      repeat: TaskRepeatLabel.fromLabel(json['repeat'] as String?),
      archivedAt: _parseDate(json['archivedAt']),
      createdAt: created,
      updatedAt: _parseDate(json['updatedAt']) ?? created,
      deletedAt: _parseDate(json['deletedAt']),
    );
  }
}

DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
