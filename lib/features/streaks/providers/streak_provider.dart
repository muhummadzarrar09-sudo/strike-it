import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/isar_service.dart';
import 'streak_engine.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ALL CHECK-IN DATES (for streak calculations)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
final allCompletedDatesProvider = FutureProvider<List<DateTime>>((ref) async {
  final checkins = await IsarService.checkins
      .filter()
      .isCompletedEqualTo(true)
      .findAll();
  return checkins.map((c) => c.date).toList();
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// OVERALL STREAK
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
final overallStreakProvider = Provider<int>((ref) {
  final dates = ref.watch(allCompletedDatesProvider).valueOrNull ?? [];
  return StreakEngine.calculateCurrentStreak(dates);
});

final overallLongestStreakProvider = Provider<int>((ref) {
  final dates = ref.watch(allCompletedDatesProvider).valueOrNull ?? [];
  return StreakEngine.calculateLongestStreak(dates);
});

final overallCompletionRateProvider = Provider<double>((ref) {
  final dates = ref.watch(allCompletedDatesProvider).valueOrNull ?? [];
  return StreakEngine.getCompletionRate(dates, totalPossibleDays: 365);
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PER-HABIT STREAK
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
final habitStreakProvider = FutureProvider.family<int, String>((ref, habitId) async {
  final checkins = await IsarService.checkins
      .filter()
      .habitIdEqualTo(habitId)
      .isCompletedEqualTo(true)
      .sortByDateDesc()
      .findAll();
  return StreakEngine.calculateCurrentStreak(checkins.map((c) => c.date).toList());
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// HEATMAP DATA
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
final heatmapDataProvider = Provider<Map<DateTime, int>>((ref) {
  final dates = ref.watch(allCompletedDatesProvider).valueOrNull ?? [];
  return StreakEngine.generateHeatmapData(dates);
});
