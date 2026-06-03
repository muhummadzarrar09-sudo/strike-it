import 'package:flutter_test/flutter_test.dart';
import 'package:streak_it/core/constants/app_constants.dart';
import 'package:streak_it/core/utils/streak_calculator.dart';

/// XP service logic is thin — it delegates to StreakCalculator for level math.
/// We test the pure math functions here, not SharedPreferences (that's I/O).
void main() {
  group('StreakCalculator — XP boundary values', () {
    test('xpPerCompletion is positive', () {
      expect(AppConstants.xpPerCompletion, greaterThan(0));
    });

    test('milestone bonuses are ordered ascending', () {
      expect(AppConstants.xpStreakBonus7, lessThan(AppConstants.xpStreakBonus21));
      expect(AppConstants.xpStreakBonus21, lessThan(AppConstants.xpStreakBonus30));
      expect(AppConstants.xpStreakBonus30, lessThan(AppConstants.xpStreakBonus66));
      expect(AppConstants.xpStreakBonus66, lessThan(AppConstants.xpStreakBonus100));
    });

    test('level thresholds are strictly ascending', () {
      final thresholds = AppConstants.xpLevelThresholds;
      for (int i = 1; i < thresholds.length; i++) {
        expect(
          thresholds[i],
          greaterThan(thresholds[i - 1]),
          reason: 'threshold[$i] should be > threshold[${i-1}]',
        );
      }
    });

    test('levelForXP returns 1 at 0', () {
      expect(StreakCalculator.levelForXP(0), 1);
    });

    test('levelForXP is monotonically non-decreasing', () {
      int prevLevel = 1;
      for (int xp = 0; xp <= 70000; xp += 1000) {
        final level = StreakCalculator.levelForXP(xp);
        expect(level, greaterThanOrEqualTo(prevLevel));
        prevLevel = level;
      }
    });

    test('xpProgressInLevel is in [0, 1]', () {
      for (int xp = 0; xp <= 70000; xp += 500) {
        final progress = StreakCalculator.xpProgressInLevel(xp);
        expect(progress, greaterThanOrEqualTo(0.0));
        expect(progress, lessThanOrEqualTo(1.0));
      }
    });

    test('xpForCompletion non-milestone returns base XP', () {
      const base = AppConstants.xpPerCompletion;
      // Non-milestone streaks
      for (final streak in [1, 2, 3, 5, 6, 8, 10, 15, 20, 25]) {
        expect(
          StreakCalculator.xpForCompletion(streak),
          base,
          reason: 'streak $streak should give base XP only',
        );
      }
    });

    test('xpForCompletion at milestones includes bonus', () {
      final milestones = {
        7: AppConstants.xpStreakBonus7,
        21: AppConstants.xpStreakBonus21,
        30: AppConstants.xpStreakBonus30,
        66: AppConstants.xpStreakBonus66,
        100: AppConstants.xpStreakBonus100,
      };
      for (final entry in milestones.entries) {
        final expected = AppConstants.xpPerCompletion + entry.value;
        expect(
          StreakCalculator.xpForCompletion(entry.key),
          expected,
          reason: 'milestone ${entry.key} should give $expected XP',
        );
      }
    });
  });
}
