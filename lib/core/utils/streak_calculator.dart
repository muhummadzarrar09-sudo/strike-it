import '../constants/app_constants.dart';
import 'date_utils.dart';

/// Result of a streak calculation for a single habit.
class StreakResult {
  final int currentStreak;
  final int bestStreak;
  final bool isActiveToday;
  final bool isAtRisk;
  final double score;
  final int? daysToNextMilestone;
  final int? nextMilestone;

  const StreakResult({
    required this.currentStreak,
    required this.bestStreak,
    required this.isActiveToday,
    required this.isAtRisk,
    required this.score,
    this.daysToNextMilestone,
    this.nextMilestone,
  });
}

abstract final class StreakCalculator {
  static StreakResult calculate({
    required Set<DateTime> completedDates,
    required DateTime startDate,
    int graceDays = 0,
    List<int> targetDays = const [],
  }) {
    final today = StreakDateUtils.today();
    final start = StreakDateUtils.dateOnly(startDate);

    final completed = completedDates.map(StreakDateUtils.dateOnly).toSet();

    final completedToday = completed.contains(today);

    // ── 1. isActiveToday — respects targetDays (FIX 1) ────────────────
    // Walk backwards to find the most recent expected day and check if
    // it was completed. If targetDays is empty, fall back to the
    // original logic (today or yesterday completed).
    final isActiveToday = _computeIsActiveToday(
      completed: completed,
      start: start,
      today: today,
      graceDays: graceDays,
      targetDays: targetDays,
    );

    // ── 2. Current streak ───────────────────────────────────────────────
    final currentStreak = _countCurrentStreak(
      completed: completed,
      start: start,
      today: today,
      graceDays: graceDays,
      targetDays: targetDays,
    );

    // ── 3. Best streak ──────────────────────────────────────────────────
    final bestStreak = _countBestStreak(
      completed: completed,
      start: start,
      today: today,
      graceDays: graceDays,
      targetDays: targetDays,
      currentStreak: currentStreak,
    );

    // ── 4. Score ────────────────────────────────────────────────────────
    final score = _computeScore(
      completed: completed,
      start: start,
      today: today,
      targetDays: targetDays,
    );

    // ── 5. isAtRisk — only on expected days (FIX 1) ────────────────────
    // Before: !completedToday && currentStreak > 0
    // After:  also require today is an expected day — no ⚠️ on rest days.
    final isAtRisk = !completedToday
        && currentStreak > 0
        && _isExpectedDay(today, targetDays);

    // ── 6. Next milestone ───────────────────────────────────────────────
    int? nextMilestone;
    int? daysToNextMilestone;
    for (final m in AppConstants.streakMilestones) {
      if (currentStreak < m) {
        nextMilestone = m;
        daysToNextMilestone = m - currentStreak;
        break;
      }
    }

    return StreakResult(
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      isActiveToday: isActiveToday,
      isAtRisk: isAtRisk,
      score: score.clamp(0.0, 100.0),
      nextMilestone: nextMilestone,
      daysToNextMilestone: daysToNextMilestone,
    );
  }

  /// FIX 1 — isActiveToday respects targetDays.
  ///
  /// Walks backwards from today up to (graceDays + 1) expected-day slots
  /// and returns true if the most recent expected day was completed.
  /// For empty targetDays (every-day habit) this is equivalent to the
  /// original logic of "completed today or yesterday".
  static bool _computeIsActiveToday({
    required Set<DateTime> completed,
    required DateTime start,
    required DateTime today,
    required int graceDays,
    required List<int> targetDays,
  }) {
    // Fast path: every-day habit — original logic is correct and cheap.
    if (targetDays.isEmpty) {
      return completed.contains(today) ||
          completed.contains(today.subtract(const Duration(days: 1)));
    }

    // Walk back to find the most recent expected day (within grace window).
    // We look at graceDays + 1 missed expected days before giving up.
    int expectedDaysSeen = 0;
    var cursor = today;

    while (!cursor.isBefore(start)) {
      if (_isExpectedDay(cursor, targetDays)) {
        if (completed.contains(cursor)) return true;
        expectedDaysSeen++;
        // If we've checked more expected days than grace allows, stop.
        if (expectedDaysSeen > graceDays + 1) return false;
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return false;
  }

  static int? milestoneReached(int streakBefore, int streakAfter) {
    for (final m in AppConstants.streakMilestones) {
      if (streakBefore < m && streakAfter >= m) return m;
    }
    return null;
  }

  static int xpForCompletion(int newStreak) {
    return AppConstants.xpPerCompletion + (_milestoneXpMap[newStreak] ?? 0);
  }

  static int levelForXP(int totalXP) {
    final t = AppConstants.xpLevelThresholds;
    for (int i = t.length - 1; i >= 0; i--) {
      if (totalXP >= t[i]) return i + 1;
    }
    return 1;
  }

  static double xpProgressInLevel(int totalXP) {
    final t = AppConstants.xpLevelThresholds;
    final level = levelForXP(totalXP);
    if (level >= t.length) return 1.0;
    final levelStart = t[level - 1];
    final levelEnd = t[level];
    if (levelEnd <= levelStart) return 1.0;
    return ((totalXP - levelStart) / (levelEnd - levelStart)).clamp(0.0, 1.0);
  }

  static int _countCurrentStreak({
    required Set<DateTime> completed,
    required DateTime start,
    required DateTime today,
    required int graceDays,
    required List<int> targetDays,
  }) {
    int streak = 0;
    int gracesRemaining = graceDays;
    var cursor = today;

    while (!cursor.isBefore(start)) {
      if (!_isExpectedDay(cursor, targetDays)) {
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }

      if (completed.contains(cursor)) {
        streak++;
        gracesRemaining = graceDays;
      } else if (cursor == today) {
        // Today not yet done — don't consume grace.
      } else if (gracesRemaining > 0) {
        gracesRemaining--;
      } else {
        break;
      }

      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  static int _countBestStreak({
    required Set<DateTime> completed,
    required DateTime start,
    required DateTime today,
    required int graceDays,
    required List<int> targetDays,
    required int currentStreak,
  }) {
    int best = currentStreak;
    int run = 0;
    int gracesRemaining = graceDays;
    var cursor = start;

    while (!cursor.isAfter(today)) {
      if (!_isExpectedDay(cursor, targetDays)) {
        cursor = cursor.add(const Duration(days: 1));
        continue;
      }

      if (completed.contains(cursor)) {
        run++;
        gracesRemaining = graceDays;
        if (run > best) best = run;
      } else if (cursor == today) {
        // incomplete today — don't break
      } else if (gracesRemaining > 0) {
        gracesRemaining--;
      } else {
        run = 0;
        gracesRemaining = graceDays;
      }

      cursor = cursor.add(const Duration(days: 1));
    }

    return best;
  }

  static double _computeScore({
    required Set<DateTime> completed,
    required DateTime start,
    required DateTime today,
    required List<int> targetDays,
  }) {
    double score = 0.0;
    const decay = AppConstants.scoreDecayFactor;
    var cursor = start;

    while (!cursor.isAfter(today)) {
      if (_isExpectedDay(cursor, targetDays)) {
        final done = completed.contains(cursor) ? 1.0 : 0.0;
        score = score * (1.0 - decay) + done * 100.0 * decay;
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return score;
  }

  static bool _isExpectedDay(DateTime date, List<int> targetDays) {
    if (targetDays.isEmpty) return true;
    return targetDays.contains(date.weekday);
  }

  static const Map<int, int> _milestoneXpMap = {
    7: AppConstants.xpStreakBonus7,
    21: AppConstants.xpStreakBonus21,
    30: AppConstants.xpStreakBonus30,
    66: AppConstants.xpStreakBonus66,
    100: AppConstants.xpStreakBonus100,
  };
}
