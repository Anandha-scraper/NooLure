import 'package:flutter_test/flutter_test.dart';
import 'package:noolure/core/utils/routine_occurrence.dart';
import 'package:noolure/models/routine_config.dart';

void main() {
  group('isOccurrenceDate', () {
    test('daily: true within [startDate, endDate], false just outside it', () {
      final config = RoutineConfig(
        frequency: RoutineFrequency.daily,
        startDate: DateTime(2026, 7, 5),
        endDate: DateTime(2026, 7, 10),
      );
      expect(isOccurrenceDate(config, DateTime(2026, 7, 5)), isTrue);
      expect(isOccurrenceDate(config, DateTime(2026, 7, 7)), isTrue);
      expect(isOccurrenceDate(config, DateTime(2026, 7, 10)), isTrue);
      expect(isOccurrenceDate(config, DateTime(2026, 7, 4)), isFalse);
      expect(isOccurrenceDate(config, DateTime(2026, 7, 11)), isFalse);
    });

    test('custom: true only for exact listed dates', () {
      final config = RoutineConfig(
        frequency: RoutineFrequency.custom,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 20),
        customDates: [DateTime(2026, 7, 5), DateTime(2026, 7, 12)],
      );
      expect(isOccurrenceDate(config, DateTime(2026, 7, 5)), isTrue);
      expect(isOccurrenceDate(config, DateTime(2026, 7, 12)), isTrue);
      expect(isOccurrenceDate(config, DateTime(2026, 7, 6)), isFalse);
    });
  });

  group('dayNumberFor', () {
    test('daily: day 1 is startDate, day N is startDate + (N-1) days', () {
      final config = RoutineConfig(
        frequency: RoutineFrequency.daily,
        startDate: DateTime(2026, 7, 5),
        endDate: DateTime(2026, 7, 10),
      );
      expect(dayNumberFor(config, DateTime(2026, 7, 5)), 1);
      expect(dayNumberFor(config, DateTime(2026, 7, 8)), 4);
      expect(dayNumberFor(config, DateTime(2026, 7, 4)), isNull);
    });

    test('custom: day numbers follow sorted order regardless of insertion order', () {
      final config = RoutineConfig(
        frequency: RoutineFrequency.custom,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 20),
        // Deliberately out of chronological order.
        customDates: [DateTime(2026, 7, 12), DateTime(2026, 7, 5), DateTime(2026, 7, 18)],
      );
      expect(dayNumberFor(config, DateTime(2026, 7, 5)), 1);
      expect(dayNumberFor(config, DateTime(2026, 7, 12)), 2);
      expect(dayNumberFor(config, DateTime(2026, 7, 18)), 3);
    });
  });

  group('occurrenceStatus — no preferred window (end-of-day fallback)', () {
    final config = RoutineConfig(
      frequency: RoutineFrequency.daily,
      startDate: DateTime(2026, 7, 5),
      endDate: DateTime(2026, 7, 10),
    );

    test('dueNow any time during the occurrence day when not yet logged', () {
      expect(
        occurrenceStatus(config, DateTime(2026, 7, 5), now: DateTime(2026, 7, 5, 0, 0, 1)),
        RoutineOccurrenceStatus.dueNow,
      );
      expect(
        occurrenceStatus(config, DateTime(2026, 7, 5), now: DateTime(2026, 7, 5, 23, 59)),
        RoutineOccurrenceStatus.dueNow,
      );
    });

    test('missed once the next day begins with nothing logged', () {
      expect(
        occurrenceStatus(config, DateTime(2026, 7, 5), now: DateTime(2026, 7, 6)),
        RoutineOccurrenceStatus.missed,
      );
    });

    test('notScheduled for a date outside the routine range regardless of now', () {
      expect(
        occurrenceStatus(config, DateTime(2026, 7, 11), now: DateTime(2026, 7, 11, 9)),
        RoutineOccurrenceStatus.notScheduled,
      );
    });

    test('completedOnTime/completedLate keyed off the logged completedAt vs. window end', () {
      final onTime = config.copyWith(log: [
        RoutineDayEntry(date: DateTime(2026, 7, 5), dayNumber: 1, completedAt: DateTime(2026, 7, 5, 20)),
      ]);
      expect(
        occurrenceStatus(onTime, DateTime(2026, 7, 5), now: DateTime(2026, 7, 6)),
        RoutineOccurrenceStatus.completedOnTime,
      );

      final late = config.copyWith(log: [
        RoutineDayEntry(date: DateTime(2026, 7, 5), dayNumber: 1, completedAt: DateTime(2026, 7, 6, 9)),
      ]);
      expect(
        occurrenceStatus(late, DateTime(2026, 7, 5), now: DateTime(2026, 7, 6, 9)),
        RoutineOccurrenceStatus.completedLate,
      );
    });
  });

  group('occurrenceStatus — with a preferred window', () {
    // 6:00 PM (1080 min) – 8:00 PM (1200 min)
    final config = RoutineConfig(
      frequency: RoutineFrequency.daily,
      startDate: DateTime(2026, 7, 5),
      endDate: DateTime(2026, 7, 10),
      preferredStartMinute: 18 * 60,
      preferredEndMinute: 20 * 60,
    );

    test('upcoming before the window opens', () {
      expect(
        occurrenceStatus(config, DateTime(2026, 7, 5), now: DateTime(2026, 7, 5, 10)),
        RoutineOccurrenceStatus.upcoming,
      );
    });

    test('dueNow inside the window', () {
      expect(
        occurrenceStatus(config, DateTime(2026, 7, 5), now: DateTime(2026, 7, 5, 19)),
        RoutineOccurrenceStatus.dueNow,
      );
    });

    test('missed after the window closes — same day, not waiting for midnight', () {
      expect(
        occurrenceStatus(config, DateTime(2026, 7, 5), now: DateTime(2026, 7, 5, 21)),
        RoutineOccurrenceStatus.missed,
      );
    });
  });

  group('preferredWindowLabel', () {
    test('null when neither bound is set', () {
      final config = RoutineConfig(
        frequency: RoutineFrequency.daily,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 10),
      );
      expect(preferredWindowLabel(config), isNull);
    });

    test('both bounds set', () {
      final config = RoutineConfig(
        frequency: RoutineFrequency.daily,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 10),
        preferredStartMinute: 6 * 60,
        preferredEndMinute: 8 * 60,
      );
      expect(preferredWindowLabel(config), '6:00 AM – 8:00 AM');
    });

    test('only a start bound', () {
      final config = RoutineConfig(
        frequency: RoutineFrequency.daily,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 10),
        preferredStartMinute: 6 * 60,
      );
      expect(preferredWindowLabel(config), '6:00 AM');
    });

    test('only an end bound', () {
      final config = RoutineConfig(
        frequency: RoutineFrequency.daily,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 10),
        preferredEndMinute: 20 * 60,
      );
      expect(preferredWindowLabel(config), '8:00 PM');
    });
  });

  group('totalOccurrenceCount / completedOccurrenceCount', () {
    test('daily counts inclusive days in range', () {
      final config = RoutineConfig(
        frequency: RoutineFrequency.daily,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 10),
      );
      expect(totalOccurrenceCount(config), 10);
    });

    test('custom counts the picked dates', () {
      final config = RoutineConfig(
        frequency: RoutineFrequency.custom,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 20),
        customDates: [DateTime(2026, 7, 5), DateTime(2026, 7, 12)],
      );
      expect(totalOccurrenceCount(config), 2);
    });

    test('completedOccurrenceCount counts only logged entries', () {
      final config = RoutineConfig(
        frequency: RoutineFrequency.daily,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 10),
        log: [
          RoutineDayEntry(date: DateTime(2026, 7, 1), dayNumber: 1, completedAt: DateTime(2026, 7, 1, 8)),
          RoutineDayEntry(date: DateTime(2026, 7, 2), dayNumber: 2), // no completedAt
        ],
      );
      expect(completedOccurrenceCount(config), 1);
    });
  });
}
