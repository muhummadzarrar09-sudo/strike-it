/// Lightweight data classes used by the analytics layer.
/// These are NOT Drift table rows — they're computed aggregates
/// returned from DAOs or the analytics service.

/// One row of daily completion data: how many habits were completed on [date].
class DailyCompletionCount {
  final DateTime date;
  final int count;

  const DailyCompletionCount({required this.date, required this.count});
}

/// Aggregated analytics for a single habit over a time period.
class HabitAnalytics {
  final String habitId;
  final String habitName;
  final String colorHex;

  /// Completion rate 0.0–1.0.
  final double completionRate;

  /// Total completions in the period.
  final int totalCompletions;

  /// Total expected completions in the period.
  final int totalExpected;

  /// Completion count per weekday (index 0=Mon, 6=Sun).
  final List<int> byWeekday;

  /// Current streak.
  final int currentStreak;

  /// Best streak.
  final int bestStreak;

  /// Habit score 0–100.
  final double score;

  const HabitAnalytics({
    required this.habitId,
    required this.habitName,
    required this.colorHex,
    required this.completionRate,
    required this.totalCompletions,
    required this.totalExpected,
    required this.byWeekday,
    required this.currentStreak,
    required this.bestStreak,
    required this.score,
  });
}

/// Mood vs. habit correlation data for a single day.
class MoodHabitCorrelation {
  final DateTime date;
  final int mood; // 1–4
  final double completionRate; // 0.0–1.0

  const MoodHabitCorrelation({
    required this.date,
    required this.mood,
    required this.completionRate,
  });
}

/// App-wide overview stats shown on the analytics hub.
class OverallStats {
  /// Total habits being tracked.
  final int totalHabits;

  /// Overall completion rate across all habits in the chosen period.
  final double overallCompletionRate;

  /// Current total XP.
  final int totalXP;

  /// Current user level.
  final int level;

  /// XP progress within the current level (0.0–1.0).
  final double levelProgress;

  /// Best single streak across all habits (habit name + streak count).
  final String? bestStreakHabitName;
  final int bestStreakCount;

  /// Number of habit-days completed in the period.
  final int totalCompletions;

  /// Number of milestones hit all-time.
  final int milestonesHit;

  const OverallStats({
    required this.totalHabits,
    required this.overallCompletionRate,
    required this.totalXP,
    required this.level,
    required this.levelProgress,
    this.bestStreakHabitName,
    required this.bestStreakCount,
    required this.totalCompletions,
    required this.milestonesHit,
  });
}

/// Data point for the heatmap: one per day.
class HeatmapDay {
  final DateTime date;

  /// 0.0–1.0 intensity (fraction of habits completed that day).
  final double intensity;

  /// Actual count of habits completed.
  final int completed;

  const HeatmapDay({
    required this.date,
    required this.intensity,
    required this.completed,
  });
}
