/// Achievement / badge definitions and unlock logic.
///
/// Achievements are computed purely from app data — no server required.
/// They are re-evaluated whenever the user opens the achievements screen
/// or completes a habit.

enum AchievementRarity { common, rare, epic, legendary }

class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final AchievementRarity rarity;

  /// Condition checker — receives snapshot of app stats.
  final bool Function(AchievementSnapshot snap) isUnlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.rarity,
    required this.isUnlocked,
  });
}

/// Snapshot of stats passed to each achievement's unlock condition.
class AchievementSnapshot {
  final int totalHabits;
  final int maxCurrentStreak;
  final int maxBestStreak;
  final int totalCompletions;
  final int totalXP;
  final int level;
  final double overallCompletionRate; // 0.0–1.0
  final bool completedAllHabitsToday;
  final int habitsCreatedCount;
  final int daysTracking; // days since first habit created

  const AchievementSnapshot({
    required this.totalHabits,
    required this.maxCurrentStreak,
    required this.maxBestStreak,
    required this.totalCompletions,
    required this.totalXP,
    required this.level,
    required this.overallCompletionRate,
    required this.completedAllHabitsToday,
    required this.habitsCreatedCount,
    required this.daysTracking,
  });
}

/// All available achievements in the app.
abstract final class AchievementService {
  static final List<Achievement> all = [
    // ── Streak Milestones ────────────────────────────────────────────────

    Achievement(
      id: 'first_streak',
      title: 'First Blood',
      description: 'Complete a habit for the first time.',
      emoji: '🩸',
      rarity: AchievementRarity.common,
      isUnlocked: (s) => s.totalCompletions >= 1,
    ),

    Achievement(
      id: 'streak_7',
      title: 'Week Warrior',
      description: 'Maintain a 7-day streak on any habit.',
      emoji: '⚡',
      rarity: AchievementRarity.common,
      isUnlocked: (s) => s.maxBestStreak >= 7,
    ),

    Achievement(
      id: 'streak_21',
      title: 'Habit Formed',
      description: '21 days. Science says it\'s official.',
      emoji: '🧠',
      rarity: AchievementRarity.rare,
      isUnlocked: (s) => s.maxBestStreak >= 21,
    ),

    Achievement(
      id: 'streak_30',
      title: 'Iron Will',
      description: '30 consecutive days. You\'re built different.',
      emoji: '🔩',
      rarity: AchievementRarity.rare,
      isUnlocked: (s) => s.maxBestStreak >= 30,
    ),

    Achievement(
      id: 'streak_66',
      title: 'Autopilot',
      description: '66 days — the real habit formation threshold.',
      emoji: '🛸',
      rarity: AchievementRarity.epic,
      isUnlocked: (s) => s.maxBestStreak >= 66,
    ),

    Achievement(
      id: 'streak_100',
      title: 'Centurion',
      description: '100 days without breaking. Legendary.',
      emoji: '💯',
      rarity: AchievementRarity.epic,
      isUnlocked: (s) => s.maxBestStreak >= 100,
    ),

    Achievement(
      id: 'streak_365',
      title: 'A Full Year',
      description: '365 days. You are the discipline.',
      emoji: '🏆',
      rarity: AchievementRarity.legendary,
      isUnlocked: (s) => s.maxBestStreak >= 365,
    ),

    // ── Volume Achievements ───────────────────────────────────────────────

    Achievement(
      id: 'completions_50',
      title: 'Getting Started',
      description: 'Log 50 habit completions.',
      emoji: '🌱',
      rarity: AchievementRarity.common,
      isUnlocked: (s) => s.totalCompletions >= 50,
    ),

    Achievement(
      id: 'completions_200',
      title: 'In the Flow',
      description: 'Log 200 habit completions.',
      emoji: '🌊',
      rarity: AchievementRarity.rare,
      isUnlocked: (s) => s.totalCompletions >= 200,
    ),

    Achievement(
      id: 'completions_500',
      title: 'Half Thousand',
      description: '500 completions. The grind is real.',
      emoji: '💪',
      rarity: AchievementRarity.epic,
      isUnlocked: (s) => s.totalCompletions >= 500,
    ),

    Achievement(
      id: 'completions_1000',
      title: 'Four Digits',
      description: '1,000 completions. Absolute machine.',
      emoji: '🤖',
      rarity: AchievementRarity.legendary,
      isUnlocked: (s) => s.totalCompletions >= 1000,
    ),

    // ── Consistency Achievements ──────────────────────────────────────────

    Achievement(
      id: 'consistency_80',
      title: 'High Performer',
      description: 'Achieve 80%+ overall completion rate.',
      emoji: '📈',
      rarity: AchievementRarity.rare,
      isUnlocked: (s) => s.overallCompletionRate >= 0.80,
    ),

    Achievement(
      id: 'consistency_95',
      title: 'Near Perfect',
      description: '95%+ completion rate. Basically flawless.',
      emoji: '✨',
      rarity: AchievementRarity.epic,
      isUnlocked: (s) => s.overallCompletionRate >= 0.95,
    ),

    // ── Collection Achievements ───────────────────────────────────────────

    Achievement(
      id: 'three_habits',
      title: 'Triathlete',
      description: 'Track 3 habits simultaneously.',
      emoji: '🎯',
      rarity: AchievementRarity.common,
      isUnlocked: (s) => s.totalHabits >= 3,
    ),

    Achievement(
      id: 'five_habits',
      title: 'System Builder',
      description: 'Track 5 habits at once.',
      emoji: '⚙️',
      rarity: AchievementRarity.rare,
      isUnlocked: (s) => s.totalHabits >= 5,
    ),

    Achievement(
      id: 'ten_habits',
      title: 'Habit Stack',
      description: '10 active habits. You\'ve built a system.',
      emoji: '🏗️',
      rarity: AchievementRarity.epic,
      isUnlocked: (s) => s.totalHabits >= 10,
    ),

    // ── Special Achievements ───────────────────────────────────────────────

    Achievement(
      id: 'perfect_day',
      title: 'Perfect Day',
      description: 'Complete every single habit in one day.',
      emoji: '🌟',
      rarity: AchievementRarity.rare,
      isUnlocked: (s) => s.completedAllHabitsToday,
    ),

    Achievement(
      id: 'level_5',
      title: 'Level Up ×5',
      description: 'Reach level 5.',
      emoji: '⬆️',
      rarity: AchievementRarity.rare,
      isUnlocked: (s) => s.level >= 5,
    ),

    Achievement(
      id: 'level_10',
      title: 'Max Level',
      description: 'Hit the top level. You\'re elite.',
      emoji: '💎',
      rarity: AchievementRarity.legendary,
      isUnlocked: (s) => s.level >= 10,
    ),

    Achievement(
      id: 'month_tracking',
      title: 'Committed',
      description: 'Use the app for 30+ days.',
      emoji: '📅',
      rarity: AchievementRarity.rare,
      isUnlocked: (s) => s.daysTracking >= 30,
    ),

    Achievement(
      id: 'year_tracking',
      title: 'Lifetime Member',
      description: 'A full year of showing up.',
      emoji: '🗓️',
      rarity: AchievementRarity.legendary,
      isUnlocked: (s) => s.daysTracking >= 365,
    ),
  ];

  /// Evaluates all achievements against a snapshot.
  /// Returns a map of achievement id → isUnlocked.
  static Map<String, bool> evaluate(AchievementSnapshot snapshot) {
    return {for (final a in all) a.id: a.isUnlocked(snapshot)};
  }

  /// Returns only unlocked achievements.
  static List<Achievement> unlocked(AchievementSnapshot snapshot) {
    return all.where((a) => a.isUnlocked(snapshot)).toList();
  }

  /// Rarity label string.
  static String rarityLabel(AchievementRarity r) {
    switch (r) {
      case AchievementRarity.common: return 'Common';
      case AchievementRarity.rare: return 'Rare';
      case AchievementRarity.epic: return 'Epic';
      case AchievementRarity.legendary: return 'Legendary';
    }
  }

  /// Rarity color for badge borders.
  static int rarityColorValue(AchievementRarity r) {
    switch (r) {
      case AchievementRarity.common: return 0xFF6B6B85;
      case AchievementRarity.rare: return 0xFF38BDF8;
      case AchievementRarity.epic: return 0xFFF59E0B;
      case AchievementRarity.legendary: return 0xFFFFD700;
    }
  }
}
