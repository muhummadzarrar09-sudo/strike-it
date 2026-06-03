import 'package:flutter_test/flutter_test.dart';
import 'package:streak_it/domain/achievement_service.dart';

void main() {
  AchievementSnapshot snap({
    int totalHabits = 0,
    int maxCurrentStreak = 0,
    int maxBestStreak = 0,
    int totalCompletions = 0,
    int totalXP = 0,
    int level = 1,
    double overallCompletionRate = 0.0,
    bool completedAllHabitsToday = false,
    int habitsCreatedCount = 0,
    int daysTracking = 0,
  }) =>
      AchievementSnapshot(
        totalHabits: totalHabits,
        maxCurrentStreak: maxCurrentStreak,
        maxBestStreak: maxBestStreak,
        totalCompletions: totalCompletions,
        totalXP: totalXP,
        level: level,
        overallCompletionRate: overallCompletionRate,
        completedAllHabitsToday: completedAllHabitsToday,
        habitsCreatedCount: habitsCreatedCount,
        daysTracking: daysTracking,
      );

  group('AchievementService.evaluate', () {
    test('no achievements with empty snapshot', () {
      final results = AchievementService.evaluate(snap());
      expect(results.values.every((v) => v == false), true);
    });

    test('first_blood unlocked at 1 completion', () {
      final results = AchievementService.evaluate(snap(totalCompletions: 1));
      expect(results['first_blood'], true);
    });

    test('first_blood NOT unlocked at 0 completions', () {
      final results = AchievementService.evaluate(snap(totalCompletions: 0));
      expect(results['first_blood'], false);
    });

    test('streak_7 unlocked at best streak ≥ 7', () {
      final results = AchievementService.evaluate(snap(maxBestStreak: 7));
      expect(results['streak_7'], true);
    });

    test('streak_7 NOT unlocked at best streak = 6', () {
      final results = AchievementService.evaluate(snap(maxBestStreak: 6));
      expect(results['streak_7'], false);
    });

    test('streak_100 unlocked at best streak ≥ 100', () {
      final results = AchievementService.evaluate(snap(maxBestStreak: 100));
      expect(results['streak_100'], true);
    });

    test('completions_200 requires at least 200', () {
      expect(
        AchievementService.evaluate(snap(totalCompletions: 200))['completions_200'],
        true,
      );
      expect(
        AchievementService.evaluate(snap(totalCompletions: 199))['completions_200'],
        false,
      );
    });

    test('consistency_80 at 80% rate', () {
      expect(
        AchievementService.evaluate(snap(overallCompletionRate: 0.80))['consistency_80'],
        true,
      );
      expect(
        AchievementService.evaluate(snap(overallCompletionRate: 0.79))['consistency_80'],
        false,
      );
    });

    test('three_habits unlocked at 3 habits', () {
      expect(
        AchievementService.evaluate(snap(totalHabits: 3))['three_habits'],
        true,
      );
      expect(
        AchievementService.evaluate(snap(totalHabits: 2))['three_habits'],
        false,
      );
    });

    test('perfect_day requires completedAllHabitsToday=true', () {
      expect(
        AchievementService.evaluate(
          snap(completedAllHabitsToday: true),
        )['perfect_day'],
        true,
      );
      expect(
        AchievementService.evaluate(
          snap(completedAllHabitsToday: false),
        )['perfect_day'],
        false,
      );
    });

    test('level_10 requires level >= 10', () {
      expect(
        AchievementService.evaluate(snap(level: 10))['level_10'],
        true,
      );
      expect(
        AchievementService.evaluate(snap(level: 9))['level_10'],
        false,
      );
    });

    test('month_tracking requires 30+ days', () {
      expect(
        AchievementService.evaluate(snap(daysTracking: 30))['month_tracking'],
        true,
      );
      expect(
        AchievementService.evaluate(snap(daysTracking: 29))['month_tracking'],
        false,
      );
    });
  });

  group('AchievementService.unlocked', () {
    test('returns only unlocked achievements', () {
      final unlocked = AchievementService.unlocked(
        snap(totalCompletions: 1, maxBestStreak: 7),
      );
      expect(unlocked.any((a) => a.id == 'first_blood'), true);
      expect(unlocked.any((a) => a.id == 'streak_7'), true);
      expect(unlocked.any((a) => a.id == 'streak_21'), false);
    });
  });

  group('AchievementService.rarityLabel', () {
    test('labels are non-empty for all rarities', () {
      for (final r in AchievementRarity.values) {
        expect(AchievementService.rarityLabel(r).isNotEmpty, true);
      }
    });
  });

  group('AchievementService.all', () {
    test('all achievements have unique ids', () {
      final ids = AchievementService.all.map((a) => a.id).toList();
      final unique = ids.toSet();
      expect(ids.length, unique.length);
    });

    test('all achievements have non-empty title and description', () {
      for (final a in AchievementService.all) {
        expect(a.title.isNotEmpty, true, reason: '${a.id} has empty title');
        expect(
          a.description.isNotEmpty,
          true,
          reason: '${a.id} has empty description',
        );
      }
    });
  });
}
