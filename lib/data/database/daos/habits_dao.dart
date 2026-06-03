import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/habits_table.dart';

part 'habits_dao.g.dart';

/// Data Access Object for the Habits table.
///
/// All DB operations for habits live here — never write raw SQL
/// outside of DAOs. This keeps business logic in repositories clean.
@DriftAccessor(tables: [Habits])
class HabitsDao extends DatabaseAccessor<AppDatabase> with _$HabitsDaoMixin {
  HabitsDao(super.db);

  // ── Read Operations ────────────────────────────────────────────────────

  /// Stream of all non-archived habits, ordered by sortOrder.
  Stream<List<Habit>> watchAllActive() {
    return (select(habits)
          ..where((h) => h.isArchived.equals(false))
          ..orderBy([(h) => OrderingTerm.asc(h.sortOrder)]))
        .watch();
  }

  /// One-shot fetch of all non-archived habits.
  Future<List<Habit>> getAllActive() {
    return (select(habits)
          ..where((h) => h.isArchived.equals(false))
          ..orderBy([(h) => OrderingTerm.asc(h.sortOrder)]))
        .get();
  }

  /// Stream of a single habit by id.
  Stream<Habit?> watchById(String id) {
    return (select(habits)..where((h) => h.id.equals(id)))
        .watchSingleOrNull();
  }

  /// One-shot fetch by id.
  Future<Habit?> getById(String id) {
    return (select(habits)..where((h) => h.id.equals(id))).getSingleOrNull();
  }

  /// All archived habits.
  Future<List<Habit>> getArchived() {
    return (select(habits)
          ..where((h) => h.isArchived.equals(true))
          ..orderBy([(h) => OrderingTerm.asc(h.sortOrder)]))
        .get();
  }

  // ── Write Operations ───────────────────────────────────────────────────

  /// Inserts a new habit. Returns the row count (1 on success).
  Future<int> insertHabit(HabitsCompanion habit) {
    return into(habits).insert(habit);
  }

  /// Updates an existing habit.
  Future<bool> updateHabit(HabitsCompanion habit) {
    return update(habits).replace(habit);
  }

  /// Soft-deletes a habit (marks as archived).
  Future<int> archiveHabit(String id) {
    return (update(habits)..where((h) => h.id.equals(id))).write(
      const HabitsCompanion(isArchived: Value(true)),
    );
  }

  /// Permanently deletes a habit and all related rows (cascades via FK).
  Future<int> deleteHabit(String id) {
    return (delete(habits)..where((h) => h.id.equals(id))).go();
  }

  /// Updates the sortOrder for a list of ids. Used for drag-to-reorder.
  Future<void> reorderHabits(List<String> orderedIds) async {
    await batch((b) {
      for (int i = 0; i < orderedIds.length; i++) {
        b.update(
          habits,
          HabitsCompanion(sortOrder: Value(i)),
          where: (h) => h.id.equals(orderedIds[i]),
        );
      }
    });
  }
}
