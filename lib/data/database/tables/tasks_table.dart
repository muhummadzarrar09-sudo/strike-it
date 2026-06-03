import 'package:drift/drift.dart';
import 'habits_table.dart';

/// Sub-tasks for a habit.
///
/// Tasks are optional depth on top of a habit. A habit "Workout" might have
/// sub-tasks: "Stretch", "10 push-ups", "3km run".
///
/// [completedOn] is a comma-separated list of "YYYY-MM-DD" dates when
/// this specific task was ticked off. This avoids a join table while
/// keeping history manageable (we prune dates older than 90 days).

class HabitTasks extends Table {
  /// UUID v4.
  TextColumn get id => text()();

  /// Parent habit.
  TextColumn get habitId =>
      text().references(Habits, #id, onDelete: KeyAction.cascade)();

  /// Task description.
  TextColumn get title => text().withLength(min: 1, max: 200)();

  /// Display order within the habit's task list.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Comma-separated "YYYY-MM-DD" dates this task was completed.
  TextColumn get completedDates => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}
