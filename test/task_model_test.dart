import 'package:flutter_test/flutter_test.dart';
import 'package:noolure/models/routine_config.dart';
import 'package:noolure/models/task_model.dart';

TaskModel _task({
  DateTime? dueAt,
  bool done = false,
  DateTime? completedAt,
  RoutineConfig? routine,
}) => TaskModel(
  id: 't1',
  title: 'Call mom',
  priority: TaskPriority.medium,
  category: 'Personal',
  createdAt: DateTime(2026, 7, 1),
  updatedAt: DateTime(2026, 7, 1),
  dueAt: dueAt,
  done: done,
  completedAt: completedAt,
  routine: routine,
);

void main() {
  // isMissed/isCompletedLate/isRoutineFinished all key off the real
  // DateTime.now() (matching the model's actual getter signatures, which
  // take no injectable clock) — every boundary case below is anchored to
  // "today" at test-run time rather than a fixed calendar date, so these
  // stay correct no matter when the suite actually runs.
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  group('isMissed', () {
    test('false while the due day has not fully elapsed, even past the due time', () {
      // Due at the first moment of today: isOverdue would already be true,
      // but isMissed stays false until today's day itself is over.
      final task = _task(dueAt: today.add(const Duration(seconds: 1)));
      expect(task.isMissed, isFalse);
    });

    test('true once the due day has fully elapsed', () {
      final task = _task(dueAt: yesterday.add(const Duration(hours: 23, minutes: 59)));
      expect(task.isMissed, isTrue);
    });

    test('false when done, regardless of how overdue', () {
      final task = _task(dueAt: yesterday, done: true);
      expect(task.isMissed, isFalse);
    });

    test('false when there is no due date', () {
      final task = _task();
      expect(task.isMissed, isFalse);
    });

    test('false for a routine task, no matter how overdue its dueAt is', () {
      final routine = RoutineConfig(
        frequency: RoutineFrequency.daily,
        startDate: yesterday,
        endDate: yesterday,
      );
      final task = _task(dueAt: yesterday, routine: routine);
      expect(task.isMissed, isFalse);
    });
  });

  group('isCompletedLate', () {
    test('false when completed before the due day elapses', () {
      final task = _task(
        dueAt: today,
        done: true,
        completedAt: today.add(const Duration(hours: 10)),
      );
      expect(task.isCompletedLate, isFalse);
    });

    test('true when completed after the due day has elapsed', () {
      final task = _task(
        dueAt: yesterday,
        done: true,
        completedAt: today.add(const Duration(hours: 10)),
      );
      expect(task.isCompletedLate, isTrue);
    });

    test('false when not done', () {
      final task = _task(dueAt: yesterday, completedAt: today);
      expect(task.isCompletedLate, isFalse);
    });

    test('false when there is no due date', () {
      final task = _task(done: true, completedAt: now);
      expect(task.isCompletedLate, isFalse);
    });
  });

  group('isRoutineFinished', () {
    test('false for a plain task', () {
      expect(_task().isRoutineFinished, isFalse);
    });

    test('false while the routine end day has not fully elapsed', () {
      // isRoutineFinished has no injectable "now" (matches the model's real
      // getter signature) — use an end date far in the future relative to
      // whenever this test actually runs, so it's stably false.
      final future = RoutineConfig(
        frequency: RoutineFrequency.daily,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 3650)),
      );
      expect(_task(routine: future).isRoutineFinished, isFalse);
    });

    test('true once the routine end day has fully elapsed', () {
      final routine = RoutineConfig(
        frequency: RoutineFrequency.daily,
        startDate: DateTime(2020, 1, 1),
        endDate: DateTime(2020, 1, 5),
      );
      expect(_task(routine: routine).isRoutineFinished, isTrue);
    });
  });

  group('timeLabel', () {
    test('empty when hasDueTime is false', () {
      final task = TaskModel(
        id: 't1',
        title: 'x',
        priority: TaskPriority.low,
        category: 'General',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueAt: DateTime(2026, 7, 13, 9),
        hasDueTime: false,
      );
      expect(task.timeLabel, '');
    });

    test('non-empty when hasDueTime is true (the default)', () {
      final task = _task(dueAt: DateTime(2026, 7, 13, 9));
      expect(task.timeLabel, isNotEmpty);
    });
  });

  group('JSON round-trip', () {
    test('preserves every field, including a nested routine and its log', () {
      final routine = RoutineConfig(
        frequency: RoutineFrequency.custom,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 20),
        customDates: [DateTime(2026, 7, 5), DateTime(2026, 7, 10)],
        preferredStartMinute: 360,
        preferredEndMinute: 480,
        log: [
          RoutineDayEntry(
            date: DateTime(2026, 7, 5),
            dayNumber: 1,
            completedAt: DateTime(2026, 7, 5, 7),
          ),
        ],
      );
      final task = TaskModel(
        id: 't1',
        title: 'Take tablets',
        priority: TaskPriority.high,
        category: 'Health',
        createdAt: DateTime(2026, 7, 1),
        updatedAt: DateTime(2026, 7, 5),
        dueAt: DateTime(2026, 7, 20),
        hasDueTime: false,
        description: 'daily',
        completedAt: DateTime(2026, 7, 5, 7),
        routine: routine,
      );

      final decoded = TaskModel.fromJson(task.toJson());

      expect(decoded.title, task.title);
      expect(decoded.hasDueTime, isFalse);
      expect(decoded.completedAt, task.completedAt);
      expect(decoded.routine?.frequency, RoutineFrequency.custom);
      expect(decoded.routine?.customDates, task.routine?.customDates);
      expect(decoded.routine?.log.single.dayNumber, 1);
      expect(decoded.routine?.log.single.completedAt, task.routine!.log.single.completedAt);
    });

    test('decodes a pre-migration record (stray repeat key, no new fields)', () {
      final decoded = TaskModel.fromJson({
        'id': 't1',
        'title': 'Old task',
        'dueAt': '2026-07-13T09:00:00.000',
        'priority': 'Medium',
        'category': 'Work',
        'done': false,
        'description': '',
        'repeat': 'Daily', // stray pre-migration key — must be ignored
        'createdAt': '2026-07-01T00:00:00.000',
        'updatedAt': '2026-07-01T00:00:00.000',
      });

      expect(decoded.hasDueTime, isTrue);
      expect(decoded.completedAt, isNull);
      expect(decoded.routine, isNull);
      expect(decoded.title, 'Old task');
    });
  });
}
