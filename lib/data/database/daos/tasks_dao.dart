import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tasks_table.dart';
import '../../../core/utils/date_utils.dart';

part 'tasks_dao.g.dart';

@DriftAccessor(tables: [HabitTasks])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(super.db);

  // ── Read ───────────────────────────────────────────────────────────────

  /// All tasks for a habit, ordered by sortOrder.
  Future<List<HabitTask>> getForHabit(String habitId) {
    return (select(habitTasks)
          ..where((t) => t.habitId.equals(habitId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  /// Reactive stream of tasks for a habit.
  Stream<List<HabitTask>> watchForHabit(String habitId) {
    return (select(habitTasks)
          ..where((t) => t.habitId.equals(habitId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  // ── Write ──────────────────────────────────────────────────────────────

  Future<int> insertTask(HabitTasksCompanion task) {
    return into(habitTasks).insert(task);
  }

  Future<bool> updateTask(HabitTasksCompanion task) {
    return update(habitTasks).replace(task);
  }

  Future<int> deleteTask(String taskId) {
    return (delete(habitTasks)..where((t) => t.id.equals(taskId))).go();
  }

  Future<void> deleteAllForHabit(String habitId) async {
    await (delete(habitTasks)..where((t) => t.habitId.equals(habitId))).go();
  }

  /// Toggles a task completion for today.
  /// Updates the [completedDates] string in place.
  Future<void> toggleTaskForDate(String taskId, DateTime date) async {
    final row = await (select(habitTasks)
          ..where((t) => t.id.equals(taskId)))
        .getSingleOrNull();
    if (row == null) return;

    final dateStr = StreakDateUtils.toIsoDate(date);
    final dates = row.completedDates.isEmpty
        ? <String>[]
        : row.completedDates.split(',');

    if (dates.contains(dateStr)) {
      dates.remove(dateStr);
    } else {
      dates.add(dateStr);
    }

    // Prune dates older than 90 days to keep the field lean.
    final cutoff = date.subtract(const Duration(days: 90));
    final cutoffStr = StreakDateUtils.toIsoDate(cutoff);
    dates.removeWhere((d) => d.compareTo(cutoffStr) < 0);

    await (update(habitTasks)..where((t) => t.id.equals(taskId))).write(
      HabitTasksCompanion(completedDates: Value(dates.join(','))),
    );
  }

  /// Returns whether a task was completed on [date].
  static bool isTaskCompletedOn(HabitTask task, DateTime date) {
    if (task.completedDates.isEmpty) return false;
    final dateStr = StreakDateUtils.toIsoDate(date);
    return task.completedDates.split(',').contains(dateStr);
  }
}
