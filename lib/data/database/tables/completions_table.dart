import 'package:drift/drift.dart';
import 'habits_table.dart';

/// Completions table — one row per (habit, date) completion event.
///
/// For binary habits: a row existing = completed for that day.
/// For quantified habits: [count] tracks progress. A habit is "done"
///   when count >= targetCount.
///
/// [date] is stored as ISO date string "YYYY-MM-DD" (no time).
/// This keeps streak math timezone-safe and simple.

class Completions extends Table {
  /// UUID v4 — unique completion id.
  TextColumn get id => text()();

  /// Foreign key to [Habits.id].
  TextColumn get habitId =>
      text().references(Habits, #id, onDelete: KeyAction.cascade)();

  /// Date of completion: "YYYY-MM-DD".
  TextColumn get date => text()();

  /// For quantified habits: how many units completed.
  IntColumn get count => integer().withDefault(const Constant(1))();

  /// Optional note / reflection for this completion.
  TextColumn get note => text().nullable()();

  /// ISO8601 timestamp when this record was inserted.
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  // Unique constraint: only one completion record per habit per day.
  // (We upsert when quantified habits update their count.)
  @override
  List<Set<Column>> get uniqueKeys => [
        {habitId, date}
      ];
}
