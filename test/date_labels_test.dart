import 'package:flutter_test/flutter_test.dart';
import 'package:noolure/core/utils/date_labels.dart';

void main() {
  // A fixed "now" so these don't drift with the wall clock.
  final now = DateTime(2026, 7, 13, 14, 30);

  group('dayLabel', () {
    test('names today, tomorrow and yesterday', () {
      expect(DateLabels.dayLabel(DateTime(2026, 7, 13, 9), now: now), 'Today');
      expect(
        DateLabels.dayLabel(DateTime(2026, 7, 14, 23, 59), now: now),
        'Tomorrow',
      );
      expect(
        DateLabels.dayLabel(DateTime(2026, 7, 12), now: now),
        'Yesterday',
      );
    });

    test('falls back to a weekday date inside the year', () {
      expect(DateLabels.dayLabel(DateTime(2026, 3, 3), now: now), 'Tue, Mar 3');
    });

    test('includes the year once the date leaves the current one', () {
      expect(
        DateLabels.dayLabel(DateTime(2027, 3, 3), now: now),
        'Mar 3, 2027',
      );
    });
  });

  group('relativeLabel', () {
    test('collapses anything under a minute to "just now"', () {
      expect(
        DateLabels.relativeLabel(now.subtract(const Duration(seconds: 20)), now: now),
        'just now',
      );
    });

    test('steps through minutes, hours and days', () {
      expect(
        DateLabels.relativeLabel(now.subtract(const Duration(minutes: 5)), now: now),
        '5m ago',
      );
      expect(
        DateLabels.relativeLabel(now.subtract(const Duration(hours: 2)), now: now),
        '2h ago',
      );
      expect(
        DateLabels.relativeLabel(now.subtract(const Duration(days: 3)), now: now),
        '3d ago',
      );
    });

    test('becomes an absolute date past a week', () {
      expect(
        DateLabels.relativeLabel(DateTime(2026, 6, 1), now: now),
        'Jun 1',
      );
    });
  });

  group('nextOccurrence', () {
    test('keeps a birthday still to come this year', () {
      expect(
        DateLabels.nextOccurrence(12, 25, now: now),
        DateTime(2026, 12, 25),
      );
    });

    test('rolls into next year once this year has passed', () {
      expect(DateLabels.nextOccurrence(1, 5, now: now), DateTime(2027, 1, 5));
    });

    test("today's birthday counts as today, not next year", () {
      expect(DateLabels.nextOccurrence(7, 13, now: now), DateTime(2026, 7, 13));
      expect(DateLabels.daysUntilNextOccurrence(7, 13, now: now), 0);
    });
  });

  group('daysUntilLabel', () {
    test('reads naturally near the day', () {
      expect(DateLabels.daysUntilLabel(0), 'Today!');
      expect(DateLabels.daysUntilLabel(1), 'Tomorrow');
      expect(DateLabels.daysUntilLabel(12), 'in 12 days');
    });
  });

  group('initialsOf', () {
    test('takes first and last initials', () {
      expect(DateLabels.initialsOf('Maya Kapoor'), 'MK');
      expect(DateLabels.initialsOf('  ada   lovelace  '), 'AL');
      expect(DateLabels.initialsOf('Prince'), 'P');
      expect(DateLabels.initialsOf(''), '?');
    });
  });
}
