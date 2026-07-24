import 'package:flutter_test/flutter_test.dart';
import 'package:noolure/models/routine_config.dart';

void main() {
  group('RoutineDayEntry', () {
    test('round-trips through JSON', () {
      final entry = RoutineDayEntry(
        date: DateTime(2026, 7, 5),
        dayNumber: 3,
        completedAt: DateTime(2026, 7, 5, 8, 30),
      );

      final decoded = RoutineDayEntry.fromJson(entry.toJson());

      expect(decoded.date, entry.date);
      expect(decoded.dayNumber, 3);
      expect(decoded.completedAt, entry.completedAt);
      expect(decoded.isDone, isTrue);
    });

    test('a not-yet-completed entry decodes with a null completedAt', () {
      final entry = RoutineDayEntry(date: DateTime(2026, 7, 5), dayNumber: 1);
      final decoded = RoutineDayEntry.fromJson(entry.toJson());
      expect(decoded.completedAt, isNull);
      expect(decoded.isDone, isFalse);
    });
  });

  group('RoutineConfig', () {
    test('round-trips every field, including custom dates and the log', () {
      final config = RoutineConfig(
        frequency: RoutineFrequency.custom,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 20),
        customDates: [DateTime(2026, 7, 5), DateTime(2026, 7, 12)],
        preferredStartMinute: 360,
        preferredEndMinute: 480,
        log: [
          RoutineDayEntry(date: DateTime(2026, 7, 5), dayNumber: 1, completedAt: DateTime(2026, 7, 5, 7)),
        ],
      );

      final decoded = RoutineConfig.fromJson(config.toJson());

      expect(decoded.frequency, RoutineFrequency.custom);
      expect(decoded.startDate, config.startDate);
      expect(decoded.endDate, config.endDate);
      expect(decoded.customDates, config.customDates);
      expect(decoded.preferredStartMinute, 360);
      expect(decoded.preferredEndMinute, 480);
      expect(decoded.log, hasLength(1));
      expect(decoded.log.single.dayNumber, 1);
    });

    test('a daily routine with no custom dates/window round-trips to empty/null defaults', () {
      final config = RoutineConfig(
        frequency: RoutineFrequency.daily,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 14),
      );

      final decoded = RoutineConfig.fromJson(config.toJson());

      expect(decoded.frequency, RoutineFrequency.daily);
      expect(decoded.customDates, isEmpty);
      expect(decoded.preferredStartMinute, isNull);
      expect(decoded.preferredEndMinute, isNull);
      expect(decoded.log, isEmpty);
    });

    test('decodes a map missing customDates/preferredMinutes/log entirely', () {
      final decoded = RoutineConfig.fromJson({
        'frequency': 'Daily',
        'startDate': '2026-07-01T00:00:00.000',
        'endDate': '2026-07-14T00:00:00.000',
      });

      expect(decoded.customDates, isEmpty);
      expect(decoded.preferredStartMinute, isNull);
      expect(decoded.preferredEndMinute, isNull);
      expect(decoded.log, isEmpty);
    });

    test('copyWith clearPreferred*Minute flags null out the window independently', () {
      final config = RoutineConfig(
        frequency: RoutineFrequency.daily,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 14),
        preferredStartMinute: 360,
        preferredEndMinute: 480,
      );

      final clearedStart = config.copyWith(clearPreferredStartMinute: true);
      expect(clearedStart.preferredStartMinute, isNull);
      expect(clearedStart.preferredEndMinute, 480);
    });
  });
}
