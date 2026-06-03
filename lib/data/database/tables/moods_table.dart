import 'package:drift/drift.dart';
import 'habits_table.dart';

/// Mood entries — one per (habit, day), optional, user-initiated.
///
/// FIX #2: Added habitId so each habit has its own mood log.
/// Previously the unique key was just {date} — shared across all habits.
/// Now unique key is {habitId, date} — each habit gets its own mood per day.
///
/// Mood values:
///   1 = Bad 😟  2 = Okay 😐  3 = Good 😊  4 = Great 🤩

class MoodEntries extends Table {
  TextColumn get id => text()();

  /// The habit this mood entry belongs to.
  TextColumn get habitId =>
      text().references(Habits, #id, onDelete: KeyAction.cascade)();

  /// Date: "YYYY-MM-DD".
  TextColumn get date => text()();

  /// Mood value 1–4.
  IntColumn get mood => integer()();

  /// Optional journal note.
  TextColumn get note => text().nullable()();

  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {habitId, date}
      ];
}
