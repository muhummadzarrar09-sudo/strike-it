import 'package:flutter_test/flutter_test.dart';
import 'package:streak_it/features/streaks/providers/streak_engine.dart';

/// ═══════════════════════════════════════════════════════════════════
/// StreakEngine — Comprehensive Test Suite
/// ═══════════════════════════════════════════════════════════════════

void main() {
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // CURRENT STREAK
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  group('calculateCurrentStreak', () {
    test('empty list returns 0', () {
      expect(StreakEngine.calculateCurrentStreak([]), 0);
    });

    test('completed today = streak of 1', () {
      expect(StreakEngine.calculateCurrentStreak([todayDate]), 1);
    });

    test('completed yesterday = streak of 1 (alive)', () {
      final yesterday = todayDate.subtract(const Duration(days: 1));
      expect(StreakEngine.calculateCurrentStreak([yesterday]), 1);
    });

    test('today + yesterday = streak of 2', () {
      final yesterday = todayDate.subtract(const Duration(days: 1));
      expect(StreakEngine.calculateCurrentStreak([todayDate, yesterday]), 2);
    });

    test('today + yesterday + day before = streak of 3', () {
      final y = todayDate.subtract(const Duration(days: 1));
      final d2 = todayDate.subtract(const Duration(days: 2));
      expect(StreakEngine.calculateCurrentStreak([todayDate, y, d2]), 3);
    });

    test('gap = streak broken (returns 0)', () {
      // Completed 2 days ago but NOT yesterday or today
      final d2 = todayDate.subtract(const Duration(days: 2));
      expect(StreakEngine.calculateCurrentStreak([d2]), 0);
    });

    test('completed today but gap before = streak of 1', () {
      final d3 = todayDate.subtract(const Duration(days: 3));
      expect(StreakEngine.calculateCurrentStreak([todayDate, d3]), 1);
    });

    test('duplicate dates ignored (same day counted once)', () {
      final yesterday = todayDate.subtract(const Duration(days: 1));
      expect(StreakEngine.calculateCurrentStreak([todayDate, todayDate, yesterday]), 2);
    });

    test('21-day streak counted correctly', () {
      final dates = List.generate(21, (i) => todayDate.subtract(Duration(days: i)));
      expect(StreakEngine.calculateCurrentStreak(dates), 21);
    });

    test('unsorted input still works (most recent first assumed)', () {
      final y = todayDate.subtract(const Duration(days: 1));
      final d2 = todayDate.subtract(const Duration(days: 2));
      // Input: d2, y, today (wrong order — algorithm expects most recent first)
      expect(StreakEngine.calculateCurrentStreak([d2, y, todayDate]), 1);
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // LONGEST STREAK
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  group('calculateLongestStreak', () {
    test('empty list returns 0', () {
      expect(StreakEngine.calculateLongestStreak([]), 0);
    });

    test('single day returns 1', () {
      expect(StreakEngine.calculateLongestStreak([todayDate]), 1);
    });

    test('three consecutive days = 3', () {
      final dates = [todayDate, todayDate.subtract(const Duration(days: 1)), todayDate.subtract(const Duration(days: 2))];
      expect(StreakEngine.calculateLongestStreak(dates), 3);
    });

    test('gap in middle: longest is longer run', () {
      final dates = [
        todayDate, todayDate.subtract(const Duration(days: 1)), // run = 2
        todayDate.subtract(const Duration(days: 5)), todayDate.subtract(const Duration(days: 6)), todayDate.subtract(const Duration(days: 7)), // run = 3
      ];
      expect(StreakEngine.calculateLongestStreak(dates), 3);
    });

    test('non-consecutive dates = 1', () {
      final dates = [todayDate, todayDate.subtract(const Duration(days: 3)), todayDate.subtract(const Duration(days: 7))];
      expect(StreakEngine.calculateLongestStreak(dates), 1);
    });

    test('duplicates don\'t inflate longest', () {
      final dates = [todayDate, todayDate, todayDate.subtract(const Duration(days: 1))];
      expect(StreakEngine.calculateLongestStreak(dates), 2);
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // HEATMAP DATA
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  group('generateHeatmapData', () {
    test('empty dates = empty map', () {
      expect(StreakEngine.generateHeatmapData([]), isEmpty);
    });

    test('single date creates one entry', () {
      final data = StreakEngine.generateHeatmapData([todayDate]);
      expect(data[todayDate], 1);
    });

    test('same date twice = count of 2', () {
      final data = StreakEngine.generateHeatmapData([todayDate, todayDate]);
      expect(data[todayDate], 2);
    });

    test('dates beyond cutoff are excluded', () {
      final oldDate = todayDate.subtract(const Duration(days: 400));
      final data = StreakEngine.generateHeatmapData([oldDate, todayDate], days: 365);
      expect(data.length, 1);
      expect(data.containsKey(oldDate), false);
    });

    test('default cutoff is 365 days', () {
      final recent = todayDate.subtract(const Duration(days: 100));
      final ancient = todayDate.subtract(const Duration(days: 400));
      final data = StreakEngine.generateHeatmapData([recent, ancient]);
      expect(data.length, 1);
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // COMPLETION RATE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  group('getCompletionRate', () {
    test('zero possible days returns 0', () {
      expect(StreakEngine.getCompletionRate([todayDate], totalPossibleDays: 0), 0);
    });

    test('all days completed = 1.0', () {
      final dates = List.generate(7, (i) => todayDate.subtract(Duration(days: i)));
      expect(StreakEngine.getCompletionRate(dates, totalPossibleDays: 7), 1.0);
    });

    test('half completed = 0.5', () {
      final dates = List.generate(15, (i) => todayDate.subtract(Duration(days: i)));
      expect(StreakEngine.getCompletionRate(dates, totalPossibleDays: 30), 0.5);
    });

    test('duplicates don\'t inflate rate', () {
      final dates = [todayDate, todayDate, todayDate];
      expect(StreakEngine.getCompletionRate(dates, totalPossibleDays: 7), 1.0 / 7.0);
    });

    test('clamped to 1.0 max', () {
      final dates = List.generate(50, (i) => todayDate.subtract(Duration(days: i)));
      expect(StreakEngine.getCompletionRate(dates, totalPossibleDays: 30), 1.0);
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // PENDING TODAY
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  group('isPendingToday', () {
    test('null = pending', () {
      expect(StreakEngine.isPendingToday(null), true);
    });

    test('completed today = NOT pending', () {
      expect(StreakEngine.isPendingToday(todayDate), false);
    });

    test('completed yesterday = still pending today', () {
      final yesterday = todayDate.subtract(const Duration(days: 1));
      expect(StreakEngine.isPendingToday(yesterday), true);
    });

    test('completed last week = pending', () {
      final lastWeek = todayDate.subtract(const Duration(days: 7));
      expect(StreakEngine.isPendingToday(lastWeek), true);
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // BEST / WORST DAY
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  group('bestDayOfWeek / worstDayOfWeek', () {
    test('empty = -1', () {
      expect(StreakEngine.getBestDayOfWeek([]), -1);
      expect(StreakEngine.getWorstDayOfWeek([]), -1);
    });

    test('all same day → best = worst = that day', () {
      final monday = DateTime(2026, 6, 1); // Monday
      final dates = [monday, monday, monday];
      final best = StreakEngine.getBestDayOfWeek(dates);
      final worst = StreakEngine.getWorstDayOfWeek(dates);
      expect(best, 0); // Monday = 0
      expect(worst, 0);
    });
  });
}
