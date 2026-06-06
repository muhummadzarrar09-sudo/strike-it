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
}