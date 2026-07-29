import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/data/repositories.dart';
import '../core/data/repository.dart';
import '../core/utils/date_labels.dart';
import '../core/utils/routine_occurrence.dart';
import '../models/routine_config.dart';
import '../models/task_model.dart';

/// One row of `TaskProvider.homeTasks` — either an ordinary open task, or a
/// routine's live "today" occurrence. A routine occurrence has no 1:1
/// TaskModel of its own (only `routine.log` entries are ever persisted), so
/// this sealed type keeps that distinction explicit at the type level rather
/// than inventing a synthetic TaskModel that could accidentally be routed
/// through `byId`/`toggleDone` as if it were independently completable.
sealed class HomeTaskDisplay {
  const HomeTaskDisplay();
}

class HomePlainTask extends HomeTaskDisplay {
  const HomePlainTask(this.task);
  final TaskModel task;
}

class HomeRoutineOccurrence extends HomeTaskDisplay {
  const HomeRoutineOccurrence(this.task);
  final TaskModel task;
}

class TaskProvider extends ChangeNotifier {
  TaskProvider({Repository<TaskModel>? repository})
    : _repository = repository ?? Repositories.tasks {
    _apply(_repository.all());
    _subscription = _repository.watch().skip(1).listen(_apply);
  }

  void _apply(List<TaskModel> tasks) {
    _allTasks = tasks;
    _tasks = tasks.where((t) => !t.isDeleted && !t.isArchived).toList()
      ..sort(_byDueThenCreated);
    notifyListeners();
  }

  final Repository<TaskModel> _repository;
  static const _uuid = Uuid();

  StreamSubscription<List<TaskModel>>? _subscription;
  List<TaskModel> _allTasks = [];
  List<TaskModel> _tasks = [];
  String selectedFilter = 'All';

  List<TaskModel> get tasks => List.unmodifiable(_tasks);

  /// Up to 3 rows for Home: ordinary open (not done, not missed) tasks, plus
  /// any routine whose *today* occurrence is still open. A routine task never
  /// also shows as a plain row, and — like a plain task — drops off Home for
  /// the rest of the day the moment today's occurrence is resolved (done or
  /// missed), or if today isn't even a scheduled occurrence day.
  List<HomeTaskDisplay> get homeTasks {
    final now = DateTime.now();
    final result = <HomeTaskDisplay>[];
    for (final t in _tasks) {
      final routine = t.routine;
      if (routine != null) {
        final status = todaysOccurrence(routine, now: now);
        if (status == RoutineOccurrenceStatus.upcoming ||
            status == RoutineOccurrenceStatus.dueNow ||
            status == RoutineOccurrenceStatus.dueLate) {
          result.add(HomeRoutineOccurrence(t));
        }
        continue;
      }
      if (t.done || t.isMissed) continue;
      result.add(HomePlainTask(t));
    }
    return result.length > 3 ? result.sublist(0, 3) : result;
  }

  List<TaskModel> get filteredTasks {
    if (selectedFilter == 'All') return tasks;
    return _tasks
        .where(
          (t) =>
              t.category == selectedFilter ||
              t.priority.label == selectedFilter,
        )
        .toList();
  }

  int get openCount => _tasks.where((t) => !t.done).length;
  int get doneCount => _tasks.where((t) => t.done).length;
  int get dueTodayCount => _tasks.where((t) => !t.done && t.isDueToday).length;
  bool get allDone => _tasks.isNotEmpty && _tasks.every((t) => t.done);

  /// Home's "Today's focus" counts — only what's actually on the plate
  /// today: a plain task due today, or a routine with an occurrence
  /// scheduled today. A routine's `TaskModel.done` never flips, so its
  /// done-ness has to come from today's computed occurrence status.
  int get todayTotalCount {
    final now = DateTime.now();
    return _tasks.where((t) => _isOnToday(t, now)).length;
  }

  int get todayDoneCount {
    final now = DateTime.now();
    return _tasks.where((t) => _isOnToday(t, now) && _isDoneToday(t, now)).length;
  }

  static bool _isOnToday(TaskModel t, DateTime now) => t.routine == null
      ? t.isDueToday
      : todaysOccurrence(t.routine!, now: now) !=
            RoutineOccurrenceStatus.notScheduled;

  static bool _isDoneToday(TaskModel t, DateTime now) {
    final routine = t.routine;
    if (routine == null) return t.done;
    return switch (todaysOccurrence(routine, now: now)) {
      RoutineOccurrenceStatus.completedEarly ||
      RoutineOccurrenceStatus.completedOnTime ||
      RoutineOccurrenceStatus.completedLate => true,
      _ => false,
    };
  }

  TaskModel? byId(String id) {
    for (final t in _tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  void setFilter(String filter) {
    selectedFilter = filter;
    notifyListeners();
  }

  Future<void> toggleDone(String id) async {
    final task = byId(id);
    if (task == null) return;
    final nowDone = !task.done;
    await _repository.save(
      task.copyWith(
        done: nowDone,
        completedAt: nowDone ? DateTime.now() : null,
        clearCompletedAt: !nowDone,
      ),
    );
  }

  Future<void> addTask({
    required String title,
    required TaskPriority priority,
    required String category,
    DateTime? dueAt,
    bool hasDueTime = true,
    String description = '',
    RoutineConfig? routine,
  }) async {
    final now = DateTime.now();
    await _repository.save(
      TaskModel(
        id: _uuid.v4(),
        title: title,
        dueAt: dueAt,
        hasDueTime: hasDueTime,
        priority: priority,
        category: category,
        description: description,
        routine: routine,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> updateTask(TaskModel task) => _repository.save(task);

  /// Marks a routine's occurrence for [date] as completed (on time or late,
  /// determined purely by comparing against the occurrence's own window —
  /// see routine_occurrence.dart) and persists it as a `RoutineDayEntry` in
  /// `task.routine.log`, replacing any existing entry for that date. Returns
  /// the resulting status so the caller can build the right confirmation
  /// text without recomputing it.
  Future<RoutineOccurrenceStatus> completeRoutineOccurrence(
    String taskId,
    DateTime date, {
    DateTime? now,
  }) async {
    final task = byId(taskId);
    if (task == null || task.routine == null) {
      return RoutineOccurrenceStatus.notScheduled;
    }
    final config = task.routine!;
    final dateOnly = DateLabels.dateOnly(date);
    final dayNumber = dayNumberFor(config, dateOnly);
    if (dayNumber == null) return RoutineOccurrenceStatus.notScheduled;

    final completedAt = now ?? DateTime.now();
    // A day that's already fully elapsed is permanently closed — checked
    // against the config *before* adding today's entry, since a log entry
    // would otherwise make this always read back as completed instead.
    if (occurrenceStatus(config, dateOnly, now: completedAt) ==
        RoutineOccurrenceStatus.missed) {
      return RoutineOccurrenceStatus.missed;
    }

    final newEntry = RoutineDayEntry(
      date: dateOnly,
      dayNumber: dayNumber,
      completedAt: completedAt,
    );
    final newLog = [
      for (final e in config.log)
        if (!DateLabels.isSameDay(e.date, dateOnly)) e,
      newEntry,
    ];
    final newConfig = config.copyWith(log: newLog);
    final status = occurrenceStatus(newConfig, dateOnly, now: completedAt);
    await _repository.save(task.copyWith(routine: newConfig));
    return status;
  }

  List<TaskModel> get trashedTasks {
    final trashed = _allTasks.where((t) => t.isDeleted).toList();
    trashed.sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));
    return trashed;
  }

  int get trashCount => _allTasks.where((t) => t.isDeleted).length;

  Future<void> trashTask(String id) async {
    final task = _findInAll(id);
    if (task == null) return;
    await _repository.save(task.copyWith(deletedAt: DateTime.now()));
  }

  Future<void> restoreTask(String id) async {
    final task = _findInAll(id);
    if (task == null) return;
    var restored = task.copyWith(clearDeletedAt: true);
    if (restored.dueAt != null && restored.dueAt!.isBefore(DateTime.now())) {
      restored = restored.copyWith(dueAt: DateTime.now());
    }
    await _repository.save(restored);
  }

  Future<void> permanentlyDeleteTask(String id) => _repository.delete(id);

  Future<void> emptyTrash() async {
    for (final t in trashedTasks) {
      await _repository.delete(t.id);
    }
  }

  List<TaskModel> get archivedTasks {
    final archived = _allTasks
        .where((t) => t.isArchived && !t.isDeleted)
        .toList();
    archived.sort((a, b) => b.archivedAt!.compareTo(a.archivedAt!));
    return archived;
  }

  int get archiveCount =>
      _allTasks.where((t) => t.isArchived && !t.isDeleted).length;

  Future<void> archiveTask(String id) async {
    final task = _findInAll(id);
    if (task == null) return;
    await _repository.save(task.copyWith(archivedAt: DateTime.now()));
  }

  Future<void> unarchiveTask(String id) async {
    final task = _findInAll(id);
    if (task == null) return;
    await _repository.save(task.copyWith(clearArchivedAt: true));
  }

  TaskModel? _findInAll(String id) {
    for (final t in _allTasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Undated tasks sink to the bottom; otherwise soonest first, then newest.
  static int _byDueThenCreated(TaskModel a, TaskModel b) {
    if (a.dueAt == null && b.dueAt == null) {
      return b.createdAt.compareTo(a.createdAt);
    }
    if (a.dueAt == null) return 1;
    if (b.dueAt == null) return -1;
    return a.dueAt!.compareTo(b.dueAt!);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
