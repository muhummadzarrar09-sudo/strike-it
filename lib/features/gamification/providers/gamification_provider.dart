import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/isar_service.dart';
import '../../habits/models/habit_checkin.dart';
import '../../auth/models/user_profile.dart';
import '../models/badge.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// USER PROFILE (Gamification part)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  return IsarService.profiles.where().findFirst();
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BADGES
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
final allBadgesProvider = StreamProvider<List<Badge>>((ref) {
  return IsarService.badges.where().watch();
});

final unlockedBadgesProvider = Provider<List<Badge>>((ref) {
  final badges = ref.watch(allBadgesProvider).valueOrNull ?? [];
  return badges.where((b) => b.isUnlocked).toList();
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// XP ENGINE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class XpEngine {
  static const int perCompletion = 10;
  static const int perPerfectDay = 25;
  static const int perStreakMilestone = 50;
  static const List<int> levelThresholds = [100, 250, 500, 1000, 2000, 4000, 8000, 16000, 32000];

  /// Returns the current level. Level 1 = 0-99 XP, Level 2 = 100-249, etc.
  static int levelFromXp(int xp) {
    int level = 1;
    for (final t in levelThresholds) {
      if (xp >= t) level++;
    }
    return level;
  }

  /// XP needed to reach the next level. Returns 0 if at max level.
  static int xpToNextLevel(int xp) {
    final level = levelFromXp(xp);
    final idx = level - 1;
    if (idx >= levelThresholds.length) return 0; // Max level
    return levelThresholds[idx] - xp;
  }

  /// 0.0 to 1.0 progress toward next level.
  static double levelProgress(int xp) {
    final level = levelFromXp(xp);
    final idx = level - 1;
    if (idx >= levelThresholds.length) return 1.0; // Max level
    if (idx == 0) return (xp / levelThresholds[0]).clamp(0.0, 1.0);
    final prev = levelThresholds[idx - 1];
    final next = levelThresholds[idx];
    return ((xp - prev) / (next - prev)).clamp(0.0, 1.0);
  }

  static Future<void> awardXp(int amount) async {
    final profile = await IsarService.profiles.where().findFirst();
    if (profile == null) return;
    profile.totalXp += amount;
    profile.currentLevel = levelFromXp(profile.totalXp);
    profile.updatedAt = DateTime.now();
    await IsarService.profiles.put(profile);

    // Check for level-up badge
    await _checkLevelUp(profile);
  }

  static Future<void> processCheckin(HabitCheckin checkin) async {
    if (!checkin.isCompleted) return;
    await awardXp(perCompletion);
  }

  static Future<void> _checkLevelUp(UserProfile profile) async {
    if (await IsarService.badges.count() == 0) {
      await seedBadges();
    }
  }

  static Future<void> seedBadges() async {
    final badges = [
      ('FIRST STREAK', 'Complete 3 days in a row', '🔥', 3, 1),
      ('WEEK WARRIOR', '7-day streak', '⚡', 7, 2),
      ('HABIT MACHINE', '30-day streak', '💀', 30, 3),
      ('CENTURY', '100-day streak', '👑', 100, 4),
      ('PERFECT WEEK', '7/7 perfect days', '🎯', 1, 1),
      ('LEVEL 5', 'Reach level 5', '📈', 1, 2),
      ('LEVEL 10', 'Reach level 10', '🏆', 1, 3),
    ];

    for (final b in badges) {
      final badge = Badge()
        ..badgeId = _uuid.v4()
        ..name = b.$1
        ..description = b.$2
        ..emoji = b.$3
        ..unlockValue = b.$4
        ..tier = b.$5
        ..category = 'streak'
        ..unlockType = 'streak_count'
        ..isUnlocked = false;
      await IsarService.badges.put(badge);
    }
  }
}
