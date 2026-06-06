class StreakEngine {
  StreakEngine._();

  static int calculateCurrentStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));
    final mostRecent = DateTime(dates.first.year, dates.first.month, dates.first.day);
    if (mostRecent != todayDate && mostRecent != yesterday) return 0;
    int streak = 1;
    DateTime expected = mostRecent;
    for (int i = 1; i < dates.length; i++) {
      final current = DateTime(dates[i].year, dates[i].month, dates[i].day);
      final previousDay = expected.subtract(const Duration(days: 1));
      if (current == previousDay) { streak++; expected = current; }
      else if (current == expected) continue;
      else break;
    }
    return streak;
  }

  static int calculateLongestStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final sorted = dates.map((d) => DateTime(d.year, d.month, d.day)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    int longest = 1, currentRun = 1;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i - 1].difference(sorted[i]).inDays == 1) {
        currentRun++;
        if (currentRun > longest) longest = currentRun;
      } else currentRun = 1;
    }
    return longest;
  }

  static Map<DateTime, int> generateHeatmapData(List<DateTime> dates, {int days = 365}) {
    final data = <DateTime, int>{};
    final cutoff = DateTime.now().subtract(Duration(days: days));
    for (final date in dates) {
      if (date.isBefore(cutoff)) continue;
      final day = DateTime(date.year, date.month, date.day);
      data[day] = (data[day] ?? 0) + 1;
    }
    return data;
  }

  static double getCompletionRate(List<DateTime> dates, {required int totalPossibleDays}) {
    if (totalPossibleDays == 0) return 0;
    final uniqueDays = dates.map((d) => DateTime(d.year, d.month, d.day)).toSet().length;
    return (uniqueDays / totalPossibleDays).clamp(0.0, 1.0);
  }

  static bool isPendingToday(DateTime? lastCompletedDate) {
    if (lastCompletedDate == null) return true;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final lastDate = DateTime(lastCompletedDate.year, lastCompletedDate.month, lastCompletedDate.day);
    return lastDate != todayDate;
  }

  /// Returns the weekday (0=Mon..6=Sun) with the most completions.
  /// Returns -1 if no data.
  static int getBestDayOfWeek(List<DateTime> dates) {
    if (dates.isEmpty) return -1;
    final counts = List.filled(7, 0);
    for (final d in dates) {
      // DateTime.weekday: 1=Mon..7=Sun → convert to 0=Mon..6=Sun
      counts[(d.weekday - 1) % 7]++;
    }
    int bestIdx = 0;
    int bestCount = counts[0];
    for (int i = 1; i < 7; i++) {
      if (counts[i] > bestCount) {
        bestCount = counts[i];
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  /// Returns the weekday (0=Mon..6=Sun) with the fewest completions.
  /// Only considers days that have at least one completion.
  /// Returns -1 if no data.
  static int getWorstDayOfWeek(List<DateTime> dates) {
    if (dates.isEmpty) return -1;
    final counts = List.filled(7, 0);
    for (final d in dates) {
      counts[(d.weekday - 1) % 7]++;
    }
    int worstIdx = -1;
    int worstCount = 999999999;
    for (int i = 0; i < 7; i++) {
      if (counts[i] > 0 && counts[i] < worstCount) {
        worstCount = counts[i];
        worstIdx = i;
      }
    }
    // If all days have the same count, return the best day
    if (worstIdx == -1) return getBestDayOfWeek(dates);
    return worstIdx;
  }
}
