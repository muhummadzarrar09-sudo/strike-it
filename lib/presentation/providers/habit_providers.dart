import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // StateProvider moved to legacy in Riverpod 3.x

import '../../core/utils/date_utils.dart';
import '../../core/utils/streak_calculator.dart';
import '../../data/database/app_database.dart';
import 'database_providers.dart';

// ── Habit list ─────────────────────────────────────────────────────────────

/// Reactive stream of all active (non-archived) habits.
final habitsStreamProvider = StreamProvider<List<Habit>>((ref) {
  return ref.watch(habitRepositoryProvider).watchAllActive();
});

/// Reactive stream of a single habit by id.
final habitByIdProvider =
    StreamProvider.family<Habit?, String>((ref, id) {
  return ref.watch(habitRepositoryProvider).watchById(id);
});

// ── Completions ────────────────────────────────────────────────────────────

/// Today's completions — reactive. Drives the home screen check states.
/// Date is embedded in the stream — if the app is backgrounded past midnight
/// and the AppLifecycleObserver invalidates this provider, it re-queries today.
final todayDateProvider = StateProvider<String>((ref) {
  return StreakDateUtils.toIsoDate(StreakDateUtils.today());
});

final todayCompletionsProvider = StreamProvider<List<Completion>>((ref) {
  // Watch the date — if it changes (midnight crossed), re-run the query.
  final dateStr = ref.watch(todayDateProvider);
  final today = StreakDateUtils.fromIsoDate(dateStr);
  return ref.watch(completionRepositoryProvider).watchAllForDate(today);
});

/// All completions for a single habit — reactive.
final habitCompletionsProvider =
    StreamProvider.family<List<Completion>, String>((ref, habitId) {
  return ref.watch(completionRepositoryProvider).watchForHabit(habitId);
});

/// One-shot: set of completed dates for streak calculation.
/// Uses ref.read inside an async provider — does NOT cause rebuild loops.
final completedDatesProvider =
    FutureProvider.family<Set<DateTime>, String>((ref, habitId) {
  // ref.read is correct here: we want the current value, not a reactive watch.
  return ref.read(completionRepositoryProvider).getCompletedDates(habitId);
});

// ── Streak computations ────────────────────────────────────────────────────

/// Computed StreakResult for a single habit — now a StreamProvider.
///
/// ARCH #2: Watches BOTH habitByIdProvider (habit config) AND
/// habitCompletionsProvider (completions). Either emitting a new value
/// triggers a re-compute of StreakResult automatically.
/// No manual ref.invalidate() needed anywhere.
final habitStreakProvider =
    StreamProvider.family<StreakResult, String>((ref, habitId) async* {
  const empty = StreakResult(
    currentStreak: 0,
    bestStreak: 0,
    isActiveToday: false,
    isAtRisk: false,
    score: 0.0,
  );

  // Watch habit config stream
  final habitAsync = ref.watch(habitByIdProvider(habitId));
  final habit = habitAsync.value;
  if (habit == null) { yield empty; return; }

  // Watch completions stream — re-runs whenever completions change
  final completionsAsync = ref.watch(habitCompletionsProvider(habitId));
  final completions = completionsAsync.value ?? [];

  final completed = completions
      .map((c) => StreakDateUtils.fromIsoDate(c.date))
      .toSet();

  final targetDays = habit.targetDays.isEmpty
      ? <int>[]
      : habit.targetDays.split(',').map(int.parse).toList();

  yield StreakCalculator.calculate(
    completedDates: completed,
    startDate: DateTime.parse(habit.createdAt),
    graceDays: habit.graceDays,
    targetDays: targetDays,
  );
});

// ── Today's progress ───────────────────────────────────────────────────────

/// (completedCount, totalCount) for today's habits.
/// Drives the progress ring on the home screen.
final todayProgressProvider = Provider<AsyncValue<(int, int)>>((ref) {
  final habits = ref.watch(habitsStreamProvider);
  final completions = ref.watch(todayCompletionsProvider);

  return habits.when(
    data: (habitList) => completions.when(
      data: (completionList) {
        // PATCH C — quantified habits done = count >= targetCount
        final total = habitList.length;
        final countMap = <String, int>{};
        for (final c in completionList) {
          countMap[c.habitId] = (countMap[c.habitId] ?? 0) + c.count;
        }
        final done = habitList.where((h) {
          if (h.kind == 'quantified') {
            return (countMap[h.id] ?? 0) >= h.targetCount;
          }
          return countMap.containsKey(h.id);
        }).length;
        return AsyncData((done, total));
      },
      loading: () => const AsyncLoading(),
      error: AsyncError.new,
    ),
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
  );
});

// ── Onboarding ─────────────────────────────────────────────────────────────

final onboardingDoneProvider = StateProvider<bool>((ref) => false);
