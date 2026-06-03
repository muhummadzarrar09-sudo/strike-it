import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/completions_table.dart';
import '../../models/analytics_data.dart';
import '../../../core/utils/date_utils.dart';

part 'completions_dao.g.dart';

@DriftAccessor(tables: [Completions])
class CompletionsDao extends DatabaseAccessor<AppDatabase>
    with _$CompletionsDaoMixin {
  CompletionsDao(super.db);

  // ── Read ───────────────────────────────────────────────────────────────

  /// All completions for a habit, sorted by date descending.
  Future<List<Completion>> getForHabit(String habitId) {
    return (select(completions)
          ..where((c) => c.habitId.equals(habitId))
          ..orderBy([(c) => OrderingTerm.desc(c.date)]))
        .get();
  }

  /// Stream of completions for a habit — reactive.
  Stream<List<Completion>> watchForHabit(String habitId) {
    return (select(completions)
          ..where((c) => c.habitId.equals(habitId))
          ..orderBy([(c) => OrderingTerm.desc(c.date)]))
        .watch();
  }

  /// Completions for a habit within a date range [from]..[to].
  Future<List<Completion>> getForHabitInRange(
    String habitId,
    DateTime from,
    DateTime to,
  ) {
    final fromStr = StreakDateUtils.toIsoDate(from);
    final toStr = StreakDateUtils.toIsoDate(to);
    return (select(completions)
          ..where((c) =>
              c.habitId.equals(habitId) &
              c.date.isBiggerOrEqualValue(fromStr) &
              c.date.isSmallerOrEqualValue(toStr))
          ..orderBy([(c) => OrderingTerm.asc(c.date)]))
        .get();
  }

  /// Fetch the completion record for a specific habit + date (or null).
  Future<Completion?> getForDate(String habitId, DateTime date) {
    final dateStr = StreakDateUtils.toIsoDate(date);
    return (select(completions)
          ..where((c) =>
              c.habitId.equals(habitId) & c.date.equals(dateStr)))
        .getSingleOrNull();
  }

  /// Returns a Set of DateTime (midnight) for all completed dates of a habit.
  /// Used as input to [StreakCalculator].
  Future<Set<DateTime>> getCompletedDates(String habitId) async {
    final rows = await getForHabit(habitId);
    return rows.map((c) => StreakDateUtils.fromIsoDate(c.date)).toSet();
  }

  /// All completions across all habits for a given date (for the home screen).
  Future<List<Completion>> getAllForDate(DateTime date) {
    final dateStr = StreakDateUtils.toIsoDate(date);
    return (select(completions)..where((c) => c.date.equals(dateStr))).get();
  }

  /// Stream of all completions for today (for reactive home screen).
  Stream<List<Completion>> watchAllForDate(DateTime date) {
    final dateStr = StreakDateUtils.toIsoDate(date);
    return (select(completions)..where((c) => c.date.equals(dateStr))).watch();
  }

  /// Aggregated completion data for analytics: returns one row per date
  /// with the count of habits completed. Date range inclusive.
  Future<List<DailyCompletionCount>> getDailyCountsInRange(
    DateTime from,
    DateTime to,
  ) async {
    final fromStr = StreakDateUtils.toIsoDate(from);
    final toStr = StreakDateUtils.toIsoDate(to);

    // We need GROUP BY date, COUNT(DISTINCT habitId) — use custom query.
    final rows = await customSelect(
      'SELECT date, COUNT(DISTINCT habit_id) as count '
      'FROM completions '
      'WHERE date >= ? AND date <= ? '
      'GROUP BY date '
      'ORDER BY date ASC',
      variables: [Variable.withString(fromStr), Variable.withString(toStr)],
      readsFrom: {completions},
    ).get();

    return rows
        .map((r) => DailyCompletionCount(
              date: StreakDateUtils.fromIsoDate(r.read<String>('date')),
              count: r.read<int>('count'),
            ))
        .toList();
  }

  // ── Write ──────────────────────────────────────────────────────────────

  /// Marks a binary habit as completed today.
  /// If already completed, this is a no-op (unique constraint).
  Future<void> markCompleted(CompletionsCompanion entry) async {
    await into(completions).insertOnConflictUpdate(entry);
  }

  /// Removes a completion for a habit on a specific date (un-check).
  Future<int> unmarkCompleted(String habitId, DateTime date) {
    final dateStr = StreakDateUtils.toIsoDate(date);
    return (delete(completions)
          ..where((c) =>
              c.habitId.equals(habitId) & c.date.equals(dateStr)))
        .go();
  }

  /// Updates the count for a quantified habit on a given date (upsert).
  Future<void> updateCount(
    String habitId,
    DateTime date,
    int newCount,
    String entryId,
    String createdAt,
  ) async {
    final dateStr = StreakDateUtils.toIsoDate(date);
    await into(completions).insertOnConflictUpdate(
      CompletionsCompanion(
        id: Value(entryId),
        habitId: Value(habitId),
        date: Value(dateStr),
        count: Value(newCount),
        createdAt: Value(createdAt),
      ),
    );
  }

  /// Deletes all completions older than [before] date.
  /// NOT used by default — kept for potential data-pruning feature.
  Future<int> deleteOlderThan(DateTime before) {
    final beforeStr = StreakDateUtils.toIsoDate(before);
    return (delete(completions)
          ..where((c) => c.date.isSmallerThanValue(beforeStr)))
        .go();
  }
}
