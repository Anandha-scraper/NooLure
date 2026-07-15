import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/data/repositories.dart';
import '../core/data/repository.dart';
import '../models/task_model.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider({Repository<TaskModel>? repository})
    : _repository = repository ?? Repositories.tasks {
    _subscription = _repository.watch().listen((tasks) {
      _allTasks = tasks;
      _tasks = tasks.where((t) => !t.isDeleted).toList()
        ..sort(_byDueThenCreated);
      notifyListeners();
    });
  }

  final Repository<TaskModel> _repository;
  static const _uuid = Uuid();

  StreamSubscription<List<TaskModel>>? _subscription;
  List<TaskModel> _allTasks = [];
  List<TaskModel> _tasks = [];
  String selectedFilter = 'All';

  List<TaskModel> get tasks => List.unmodifiable(_tasks);

  List<TaskModel> get homeTasks =>
      _tasks.where((t) => !t.done).take(3).toList();

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
    await _repository.save(task.copyWith(done: !task.done));
  }

  Future<void> addTask({
    required String title,
    required TaskPriority priority,
    required String category,
    DateTime? dueAt,
    String description = '',
    TaskRepeat repeat = TaskRepeat.none,
  }) async {
    final now = DateTime.now();
    await _repository.save(
      TaskModel(
        id: _uuid.v4(),
        title: title,
        dueAt: dueAt,
        priority: priority,
        category: category,
        description: description,
        repeat: repeat,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> updateTask(TaskModel task) => _repository.save(task);

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
