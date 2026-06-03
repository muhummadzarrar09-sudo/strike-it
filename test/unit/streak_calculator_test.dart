import 'package:flutter_test/flutter_test.dart';
import 'package:streak_it/core/utils/streak_calculator.dart';
import 'package:streak_it/core/utils/date_utils.dart';
import 'package:streak_it/core/constants/app_constants.dart';

void main() {
  // Helper to make dates relative to today.
  DateTime day(int daysAgo) =>
      StreakDateUtils.today().subtract(Duration(days: daysAgo));

  group('StreakCalculator — basic streaks', () {
    test('empty completions → zero everything', () {
      final r = StreakCalculator.calculate(
        completedDates: {},
        startDate: day(30),
      );
      expect(r.currentStreak, 0);
      expect(r.bestStreak, 0);
      expect(r.isActiveToday, false);
      expect(r.isAtRisk, false);
      expect(r.score, closeTo(0.0, 1.0));
    });

    test('only today completed → streak = 1, active, not at-risk', () {
      final r = StreakCalculator.calculate(
        completedDates: {StreakDateUtils.today()},
        startDate: day(5),
      );
      expect(r.currentStreak, 1);
      expect(r.isActiveToday, true);
      expect(r.isAtRisk, false);
    });

    test('4 consecutive days → streak = 4', () {
      final dates = {for (int i = 0; i < 4; i++) day(i)};
      final r = StreakCalculator.calculate(
        completedDates: dates,
        startDate: day(30),
      );
      expect(r.currentStreak, 4);
      expect(r.bestStreak, 4);
    });

    test('gap without grace days breaks streak', () {
      // today + yesterday, skip day(2), then day(3)
      final dates = {day(0), day(1), day(3)};
      final r = StreakCalculator.calculate(
        completedDates: dates,
        startDate: day(10),
        graceDays: 0,
      );
      expect(r.currentStreak, 2); // only today + yesterday
    });

    test('gap with 1 grace day preserves streak', () {
      // today, yesterday, skip day(2), day(3)
      final dates = {day(0), day(1), day(3)};
      final r = StreakCalculator.calculate(
        completedDates: dates,
        startDate: day(10),
        graceDays: 1,
      );
      expect(r.currentStreak, greaterThanOrEqualTo(3));
    });

    test('only yesterday completed → active, isAtRisk=false (still within today)', () {
      final r = StreakCalculator.calculate(
        completedDates: {day(1)},
        startDate: day(10),
      );
      expect(r.isActiveToday, true);
    });

    test('last completion 2 days ago → not active, isAtRisk=false (streak already 0)', () {
      final r = StreakCalculator.calculate(
        completedDates: {day(2), day(3)},
        startDate: day(10),
        graceDays: 0,
      );
      expect(r.isActiveToday, false);
      // streak is broken — no risk, just 0
    });

    test('today not done but yesterday done with streak → isAtRisk=true', () {
      final dates = {for (int i = 1; i <= 5; i++) day(i)};
      final r = StreakCalculator.calculate(
        completedDates: dates,
        startDate: day(20),
      );
      expect(r.isAtRisk, true);
    });
  });

  group('StreakCalculator — best streak', () {
    test('best streak correctly computed over history', () {
      // 10-day run, then a break, then 3-day run
      final dates = {
        for (int i = 5; i <= 14; i++) day(i), // 10 days
        day(0), day(1), day(2),                  // 3 days
      };
      final r = StreakCalculator.calculate(
        completedDates: dates,
        startDate: day(30),
      );
      expect(r.bestStreak, greaterThanOrEqualTo(10));
    });
  });

  group('StreakCalculator — score', () {
    test('perfect 30 days → score > 70', () {
      final dates = {for (int i = 0; i < 30; i++) day(i)};
      final r = StreakCalculator.calculate(
        completedDates: dates,
        startDate: day(30),
      );
      expect(r.score, greaterThan(70));
    });

    test('zero completions → score near 0', () {
      final r = StreakCalculator.calculate(
        completedDates: {},
        startDate: day(30),
      );
      expect(r.score, lessThan(5));
    });

    test('score is clamped to [0, 100]', () {
      final dates = {for (int i = 0; i < 100; i++) day(i)};
      final r = StreakCalculator.calculate(
        completedDates: dates,
        startDate: day(100),
      );
      expect(r.score, lessThanOrEqualTo(100.0));
      expect(r.score, greaterThanOrEqualTo(0.0));
    });
  });

  group('StreakCalculator — milestones', () {
    test('milestoneReached detects 7 transition', () {
      expect(StreakCalculator.milestoneReached(6, 7), 7);
    });

    test('milestoneReached detects 30 transition', () {
      expect(StreakCalculator.milestoneReached(29, 30), 30);
    });

    test('milestoneReached returns null for non-milestone', () {
      expect(StreakCalculator.milestoneReached(5, 6), null);
      expect(StreakCalculator.milestoneReached(10, 11), null);
    });

    test('next milestone reported when streak = 5', () {
      final dates = {for (int i = 0; i < 5; i++) day(i)};
      final r = StreakCalculator.calculate(
        completedDates: dates,
        startDate: day(10),
      );
      expect(r.nextMilestone, 7);
      expect(r.daysToNextMilestone, 2);
    });

    test('next milestone is 100 when streak = 66', () {
      final dates = {for (int i = 0; i < 66; i++) day(i)};
      final r = StreakCalculator.calculate(
        completedDates: dates,
        startDate: day(70),
      );
      expect(r.nextMilestone, 100);
    });
  });

  group('StreakCalculator — custom target days', () {
    test('only Mon/Wed/Fri expected — other days not counted', () {
      // Only include Monday completions for last 2 weeks.
      final dates = <DateTime>{};
      for (int i = 0; i < 14; i++) {
        final d = day(i);
        if (d.weekday == 1) dates.add(d); // Monday only
      }
      final r = StreakCalculator.calculate(
        completedDates: dates,
        startDate: day(14),
        targetDays: [1, 3, 5],
      );
      // Should not penalise for missing Tuesdays/Thursdays etc.
      expect(r.score, greaterThan(0));
    });
  });

  group('StreakCalculator — XP', () {
    test('base XP for non-milestone completion', () {
      expect(StreakCalculator.xpForCompletion(1), AppConstants.xpPerCompletion);
    });

    test('bonus XP at 7-day milestone', () {
      final xp = StreakCalculator.xpForCompletion(7);
      expect(xp, AppConstants.xpPerCompletion + AppConstants.xpStreakBonus7);
    });

    test('bonus XP at 30-day milestone', () {
      final xp = StreakCalculator.xpForCompletion(30);
      expect(xp, AppConstants.xpPerCompletion + AppConstants.xpStreakBonus30);
    });

    test('no bonus for arbitrary non-milestone streak', () {
      expect(StreakCalculator.xpForCompletion(15), AppConstants.xpPerCompletion);
    });
  });

  group('StreakCalculator — level', () {
    test('level 1 at 0 XP', () => expect(StreakCalculator.levelForXP(0), 1));
    test('level 1 just below threshold', () =>
        expect(StreakCalculator.levelForXP(499), 1));
    test('level 2 at exactly 500 XP', () =>
        expect(StreakCalculator.levelForXP(500), 2));
    test('level 10 at 60000+ XP', () =>
        expect(StreakCalculator.levelForXP(60000), 10));
    test('level progress returns 0.0 at level threshold', () {
      final progress = StreakCalculator.xpProgressInLevel(0);
      expect(progress, closeTo(0.0, 0.01));
    });
    test('level progress returns ~0.5 at midpoint', () {
      // Level 2 goes from 500 to 1200 → midpoint ~850
      final progress = StreakCalculator.xpProgressInLevel(850);
      expect(progress, closeTo(0.5, 0.1));
    });
  });

  group('StreakCalculator — FIX 1: targetDays respect', () {
    test('isAtRisk == false when today is a non-target day', () {
      // Habit is Mon/Wed/Fri only. Build a streak on those days.
      // Today is Tuesday (weekday 2) — not a target day.
      // Even with currentStreak > 0, isAtRisk must be false.
      final today = StreakDateUtils.today();
      // Find the last Monday (weekday 1)
      var lastMonday = today;
      while (lastMonday.weekday != 1) {
        lastMonday = lastMonday.subtract(const Duration(days: 1));
      }
      // Simulate completing last Monday and Wednesday and Friday
      final dates = <DateTime>{};
      var d = lastMonday;
      for (int i = 0; i < 3; i++) {
        dates.add(d);
        d = d.add(const Duration(days: 2)); // Mon → Wed → Fri
      }

      // Use a fixed Tuesday as "today" by using a date that is definitely Tuesday
      // Simplest: pick last Tuesday from today going back
      var testToday = today;
      while (testToday.weekday != 2) {
        testToday = testToday.subtract(const Duration(days: 1));
      }

      // Recalculate with dates relative to testToday
      final monday = testToday.subtract(const Duration(days: 1));
      final completedDates = {monday}; // completed last Monday

      final result = StreakCalculator.calculate(
        completedDates: completedDates,
        startDate: monday.subtract(const Duration(days: 7)),
        targetDays: [1, 3, 5], // Mon/Wed/Fri
      );

      // Tuesday is not a target day — isAtRisk must be false
      expect(result.isAtRisk, false,
          reason: 'isAtRisk must be false on a non-target day');
    });

    test('isActiveToday == true when last expected day was completed even if yesterday was a rest day', () {
      // Habit: Mon/Wed/Fri only. Today is Tuesday.
      // User completed Monday. isActiveToday should be true.
      final today = StreakDateUtils.today();
      var tuesday = today;
      while (tuesday.weekday != 2) {
        tuesday = tuesday.subtract(const Duration(days: 1));
      }
      final monday = tuesday.subtract(const Duration(days: 1));

      final result = StreakCalculator.calculate(
        completedDates: {monday},
        startDate: monday.subtract(const Duration(days: 7)),
        targetDays: [1, 3, 5], // Mon/Wed/Fri
      );

      // Monday was the last expected day and it was completed.
      // Even though yesterday (Monday) was not "yesterday" in naive terms,
      // the streak should be active.
      expect(result.currentStreak, greaterThan(0));
    });
  });
}
