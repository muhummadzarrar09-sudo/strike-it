import 'package:flutter_test/flutter_test.dart';
import 'package:streak_it/core/utils/date_utils.dart';

void main() {
  group('StreakDateUtils', () {
    test('today() is at midnight', () {
      final t = StreakDateUtils.today();
      expect(t.hour, 0);
      expect(t.minute, 0);
      expect(t.second, 0);
      expect(t.millisecond, 0);
    });

    test('yesterday() is exactly 1 day before today', () {
      expect(
        StreakDateUtils.today().difference(StreakDateUtils.yesterday()).inDays,
        1,
      );
    });

    test('dateOnly strips all time components', () {
      final dt = DateTime(2025, 6, 15, 14, 30, 22, 500);
      final d = StreakDateUtils.dateOnly(dt);
      expect(d, DateTime(2025, 6, 15));
      expect(d.hour, 0);
      expect(d.millisecond, 0);
    });

    test('isSameDay: same day different time → true', () {
      final a = DateTime(2025, 3, 10, 8, 0);
      final b = DateTime(2025, 3, 10, 23, 59, 59);
      expect(StreakDateUtils.isSameDay(a, b), true);
    });

    test('isSameDay: different days → false', () {
      expect(
        StreakDateUtils.isSameDay(
          DateTime(2025, 3, 10),
          DateTime(2025, 3, 11),
        ),
        false,
      );
    });

    test('isSameDay: different months → false', () {
      expect(
        StreakDateUtils.isSameDay(
          DateTime(2025, 3, 31),
          DateTime(2025, 4, 1),
        ),
        false,
      );
    });

    test('daysBetween returns correct day count', () {
      final from = DateTime(2025, 1, 1);
      final to = DateTime(2025, 1, 11);
      expect(StreakDateUtils.daysBetween(from, to), 10);
    });

    test('daysBetween is 0 for same day', () {
      final d = DateTime(2025, 5, 15);
      expect(StreakDateUtils.daysBetween(d, d), 0);
    });

    test('dateRange length is inclusive on both ends', () {
      final range = StreakDateUtils.dateRange(
        DateTime(2025, 6, 1),
        DateTime(2025, 6, 7),
      );
      expect(range.length, 7);
    });

    test('dateRange first and last are correct', () {
      final range = StreakDateUtils.dateRange(
        DateTime(2025, 6, 1),
        DateTime(2025, 6, 5),
      );
      expect(range.first, DateTime(2025, 6, 1));
      expect(range.last, DateTime(2025, 6, 5));
    });

    test('dateRange all at midnight', () {
      final range = StreakDateUtils.dateRange(
        DateTime(2025, 1, 1),
        DateTime(2025, 1, 3),
      );
      for (final d in range) {
        expect(d.hour, 0);
        expect(d.minute, 0);
      }
    });

    test('toIsoDate pads single-digit month and day', () {
      expect(StreakDateUtils.toIsoDate(DateTime(2025, 1, 5)), '2025-01-05');
    });

    test('toIsoDate → fromIsoDate roundtrip', () {
      final dt = DateTime(2025, 11, 28);
      expect(StreakDateUtils.fromIsoDate(StreakDateUtils.toIsoDate(dt)), dt);
    });

    test('shortWeekday: 1=Mon, 7=Sun', () {
      expect(StreakDateUtils.shortWeekday(1), 'Mon');
      expect(StreakDateUtils.shortWeekday(5), 'Fri');
      expect(StreakDateUtils.shortWeekday(7), 'Sun');
    });

    test('shortMonth: 1=Jan, 12=Dec', () {
      expect(StreakDateUtils.shortMonth(1), 'Jan');
      expect(StreakDateUtils.shortMonth(6), 'Jun');
      expect(StreakDateUtils.shortMonth(12), 'Dec');
    });

    test('fullMonth: 1=January, 12=December', () {
      expect(StreakDateUtils.fullMonth(1), 'January');
      expect(StreakDateUtils.fullMonth(12), 'December');
    });

    test('relativeLabel: today → "Today"', () {
      expect(StreakDateUtils.relativeLabel(StreakDateUtils.today()), 'Today');
    });

    test('relativeLabel: yesterday → "Yesterday"', () {
      expect(
        StreakDateUtils.relativeLabel(StreakDateUtils.yesterday()),
        'Yesterday',
      );
    });

    test('relativeLabel: 3 days ago → "3 days ago"', () {
      final d = DateTime.now().subtract(const Duration(days: 3));
      expect(StreakDateUtils.relativeLabel(d), '3 days ago');
    });

    test('startOfWeek returns Monday', () {
      // 2025-06-11 is a Wednesday
      final wednesday = DateTime(2025, 6, 11);
      final monday = StreakDateUtils.startOfWeek(wednesday);
      expect(monday.weekday, 1);
      expect(monday, DateTime(2025, 6, 9));
    });

    test('startOfMonth returns 1st of month', () {
      final mid = DateTime(2025, 9, 17);
      expect(StreakDateUtils.startOfMonth(mid), DateTime(2025, 9, 1));
    });
  });
}
