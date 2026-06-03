import 'package:drift/drift.dart';

/// Habits table definition for Drift ORM.
///
/// A habit is the core entity. Every other table (completions, tasks, moods)
/// references habits by [id] (UUID string).
///
/// Frequency encoding:
///   frequencyType: 'daily' | 'weekdays' | 'weekends' | 'custom'
///   targetDays: comma-separated weekday ints when frequencyType='custom'
///               e.g. "1,3,5" = Mon, Wed, Fri
///
/// Habit kinds:
///   kind: 'binary' (done / not done) | 'quantified' (count-based)
///   For quantified habits, [targetCount] is the goal.
///
/// isNegative: true = the user wants to STOP doing this habit.

class Habits extends Table {
  /// UUID v4 string — primary key.
  TextColumn get id => text()();

  /// Human-readable habit name (max 100 chars).
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Optional longer description / motivation note.
  TextColumn get description => text().nullable()();

  /// Hex color string, e.g. "#7C5CFC".
  TextColumn get colorHex => text().withDefault(const Constant('#F59E0B'))();

  /// Icon id from [HabitIcons.all], e.g. "barbell".
  TextColumn get iconId => text().withDefault(const Constant('star'))();

  /// Emoji override (optional, takes precedence over icon in display).
  TextColumn get emoji => text().nullable()();

  /// 'binary' | 'quantified'
  TextColumn get kind => text().withDefault(const Constant('binary'))();

  /// Target count for quantified habits (ignored for binary).
  IntColumn get targetCount => integer().withDefault(const Constant(1))();

  /// 'daily' | 'weekdays' | 'weekends' | 'custom'
  TextColumn get frequencyType => text().withDefault(const Constant('daily'))();

  /// Comma-separated weekday ints for custom frequency.
  TextColumn get targetDays => text().withDefault(const Constant(''))();

  /// Number of grace days allowed (0–3) before streak breaks.
  IntColumn get graceDays => integer().withDefault(const Constant(0))();

  /// Whether this is a "stop doing" habit.
  BoolColumn get isNegative => boolean().withDefault(const Constant(false))();

  /// Whether the habit is archived (soft delete, not shown in active list).
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  /// Display order — lower = higher in the list.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// ISO8601 string of when this habit was created.
  TextColumn get createdAt => text()();

  /// Reminder times — comma-separated "HH:MM" strings.
  /// e.g. "07:30,20:00" = morning and evening reminder.
  TextColumn get reminderTimes => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}
