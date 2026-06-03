import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../../core/utils/date_utils.dart';

/// Repository for completion records.
///
/// Handles binary toggle and quantified increment logic.
/// All streak/score calculation is done in the domain layer —
/// this repo just reads/writes raw completion data.
class CompletionRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  CompletionRepository(this._db);

  // ── Streams / Queries ──────────────────────────────────────────────────

  Future<Set<DateTime>> getCompletedDates(String habitId) =>
      _db.completionsDao.getCompletedDates(habitId);

  Future<List<Completion>> getForHabit(String habitId) =>
      _db.completionsDao.getForHabit(habitId);

  Stream<List<Completion>> watchForHabit(String habitId) =>
      _db.completionsDao.watchForHabit(habitId);

  Future<Completion?> getForDate(String habitId, DateTime date) =>
      _db.completionsDao.getForDate(habitId, date);

  Stream<List<Completion>> watchAllForDate(DateTime date) =>
      _db.completionsDao.watchAllForDate(date);

  Future<List<Completion>> getForHabitInRange(
    String habitId,
    DateTime from,
    DateTime to,
  ) =>
      _db.completionsDao.getForHabitInRange(habitId, from, to);

  // ── Toggle (binary habits) ─────────────────────────────────────────────

  /// Returns true if the habit ended up completed after toggle,
  /// false if it was un-completed.
  Future<bool> toggleCompletion(String habitId, DateTime date) async {
    final existing = await getForDate(habitId, date);
    if (existing != null) {
      await _db.completionsDao.unmarkCompleted(habitId, date);
      return false;
    } else {
      final now = DateTime.now().toIso8601String();
      await _db.completionsDao.markCompleted(
        CompletionsCompanion(
          id: Value(_uuid.v4()),
          habitId: Value(habitId),
          date: Value(StreakDateUtils.toIsoDate(date)),
          count: const Value(1),
          createdAt: Value(now),
        ),
      );
      return true;
    }
  }

  // ── Quantified habits ──────────────────────────────────────────────────

  /// Increments the count for a quantified habit.
  /// Creates the row if it doesn't exist yet.
  /// Returns the new count.
  Future<int> incrementCount(String habitId, DateTime date) async {
    final existing = await getForDate(habitId, date);
    final newCount = (existing?.count ?? 0) + 1;
    final now = DateTime.now().toIso8601String();
    await _db.completionsDao.updateCount(
      habitId,
      date,
      newCount,
      existing?.id ?? _uuid.v4(),
      existing?.createdAt ?? now,
    );
    return newCount;
  }

  /// Decrements the count. If count reaches 0, removes the record.
  /// Returns the new count.
  Future<int> decrementCount(String habitId, DateTime date) async {
    final existing = await getForDate(habitId, date);
    if (existing == null) return 0;

    final newCount = existing.count - 1;
    if (newCount <= 0) {
      await _db.completionsDao.unmarkCompleted(habitId, date);
      return 0;
    }

    await _db.completionsDao.updateCount(
      habitId,
      date,
      newCount,
      existing.id,
      existing.createdAt,
    );
    return newCount;
  }
}
