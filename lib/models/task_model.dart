import '../core/utils/date_labels.dart';
import 'routine_config.dart';

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

class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.priority,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.dueAt,
    this.hasDueTime = true,
    this.done = false,
    this.description = '',
    this.completedAt,
    this.routine,
    this.deletedAt,
    this.archivedAt,
  });

  final String id;
  final String title;

  /// When the task is due. Null means "someday" — no date set.
  final DateTime? dueAt;

  /// False means [dueAt] is a date-only pick — no specific time of day.
  final bool hasDueTime;
  final TaskPriority priority;
  final String category;
  final bool done;
  final String description;

  /// Stamped when [done] turns true, cleared when it turns back false —
  /// drives [isCompletedLate].
  final DateTime? completedAt;

  /// Null means an ordinary one-off task. Non-null replaces the old
  /// TaskRepeat field with a real recurring schedule and its own
  /// per-occurrence completion log.
  final RoutineConfig? routine;
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

  /// '9:00 AM', or empty when no due time is set (either no due date at
  /// all, or a date-only pick with [hasDueTime] false).
  String get timeLabel =>
      (dueAt == null || !hasDueTime) ? '' : DateLabels.timeLabel(dueAt!);

  bool get isDueToday =>
      dueAt != null && DateLabels.isSameDay(dueAt!, DateTime.now());

  /// Time-of-day-precise — a task due today at 2pm is overdue at 2:01pm.
  /// Kept as-is for existing uses; [isMissed] below is the day-precise
  /// status that actually drives Home visibility.
  bool get isOverdue =>
      dueAt != null && !done && dueAt!.isBefore(DateTime.now());

  /// The exclusive instant [dueAt]'s calendar day fully elapses.
  DateTime? get _dueDayCutoff => dueAt == null
      ? null
      : DateTime(dueAt!.year, dueAt!.month, dueAt!.day + 1);

  /// A plain (non-routine) task that's still open once its due day has
  /// fully elapsed — day-precise, not time-of-day-precise (see [isOverdue]).
  /// Routines are never "missed" as a whole; only individual occurrences
  /// are (see routine_occurrence.dart).
  bool get isMissed {
    if (routine != null || done || dueAt == null) return false;
    return !DateTime.now().isBefore(_dueDayCutoff!);
  }

  /// True once [completedAt] lands on/after the day-cutoff for [dueAt].
  bool get isCompletedLate {
    if (!done || completedAt == null || dueAt == null) return false;
    return !completedAt!.isBefore(_dueDayCutoff!);
  }

  /// True once a routine's own end date has fully elapsed — the Tasks-page
  /// bucketing signal that moves it from "Routines" to "Completed".
  bool get isRoutineFinished {
    final r = routine;
    if (r == null) return false;
    final cutoff = DateTime(r.endDate.year, r.endDate.month, r.endDate.day + 1);
    return !DateTime.now().isBefore(cutoff);
  }

  TaskModel copyWith({
    String? title,
    DateTime? dueAt,
    bool clearDueAt = false,
    bool? hasDueTime,
    TaskPriority? priority,
    String? category,
    bool? done,
    String? description,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    RoutineConfig? routine,
    bool clearRoutine = false,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
  }) => TaskModel(
    id: id,
    title: title ?? this.title,
    dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
    hasDueTime: hasDueTime ?? this.hasDueTime,
    priority: priority ?? this.priority,
    category: category ?? this.category,
    done: done ?? this.done,
    description: description ?? this.description,
    completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    routine: clearRoutine ? null : (routine ?? this.routine),
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
    deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'dueAt': dueAt?.toIso8601String(),
    'hasDueTime': hasDueTime,
    'priority': priority.label,
    'category': category,
    'done': done,
    'description': description,
    'completedAt': completedAt?.toIso8601String(),
    'routine': routine?.toJson(),
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
      hasDueTime: (json['hasDueTime'] as bool?) ?? true,
      priority: TaskPriorityLabel.fromLabel(json['priority'] as String?),
      category: (json['category'] as String?) ?? 'General',
      done: (json['done'] as bool?) ?? false,
      description: (json['description'] as String?) ?? '',
      completedAt: _parseDate(json['completedAt']),
      routine: json['routine'] == null
          ? null
          : RoutineConfig.fromJson(json['routine'] as Map<String, dynamic>),
      archivedAt: _parseDate(json['archivedAt']),
      createdAt: created,
      updatedAt: _parseDate(json['updatedAt']) ?? created,
      deletedAt: _parseDate(json['deletedAt']),
    );
  }
}

DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
