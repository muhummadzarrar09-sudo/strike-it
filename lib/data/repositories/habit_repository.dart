import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../../core/utils/date_utils.dart';

/// Repository — single source of truth for habit data.
///
/// All business-layer code talks to this, never to the DAO directly.
/// This keeps the domain layer testable (mock the repo, not the DB).
class HabitRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  HabitRepository(this._db);

  // ── Streams ────────────────────────────────────────────────────────────

  /// Reactive stream of all active habits.
  Stream<List<Habit>> watchAllActive() => _db.habitsDao.watchAllActive();

  /// Reactive stream of a single habit by id.
  Stream<Habit?> watchById(String id) => _db.habitsDao.watchById(id);

  // ── Queries ────────────────────────────────────────────────────────────

  Future<List<Habit>> getAllActive() => _db.habitsDao.getAllActive();

  Future<Habit?> getById(String id) => _db.habitsDao.getById(id);

  // ── Mutations ──────────────────────────────────────────────────────────

  /// Creates a new habit. Returns the generated UUID.
  Future<String> createHabit({
    required String name,
    String? description,
    required String colorHex,
    required String iconId,
    String? emoji,
    required String kind,          // 'binary' | 'quantified'
    int targetCount = 1,
    required String frequencyType, // 'daily' | 'weekdays' | 'weekends' | 'custom'
    List<int> targetDays = const [],
    int graceDays = 0,
    bool isNegative = false,
    List<String> reminderTimes = const [],
    int sortOrder = 0,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await _db.habitsDao.insertHabit(
      HabitsCompanion(
        id: Value(id),
        name: Value(name),
        description: Value(description),
        colorHex: Value(colorHex),
        iconId: Value(iconId),
        emoji: Value(emoji),
        kind: Value(kind),
        targetCount: Value(targetCount),
        frequencyType: Value(frequencyType),
        targetDays: Value(targetDays.join(',')),
        graceDays: Value(graceDays),
        isNegative: Value(isNegative),
        isArchived: const Value(false),
        sortOrder: Value(sortOrder),
        createdAt: Value(now),
        reminderTimes: Value(reminderTimes.join(',')),
      ),
    );
    return id;
  }

  /// Updates an existing habit.
  Future<void> updateHabit({
    required String id,
    String? name,
    String? description,
    String? colorHex,
    String? iconId,
    String? emoji,
    String? kind,
    int? targetCount,
    String? frequencyType,
    List<int>? targetDays,
    int? graceDays,
    bool? isNegative,
    List<String>? reminderTimes,
    int? sortOrder,
  }) async {
    await _db.habitsDao.updateHabit(
      HabitsCompanion(
        id: Value(id),
        name: name != null ? Value(name) : const Value.absent(),
        description: description != null ? Value(description) : const Value.absent(),
        colorHex: colorHex != null ? Value(colorHex) : const Value.absent(),
        iconId: iconId != null ? Value(iconId) : const Value.absent(),
        emoji: emoji != null ? Value(emoji) : const Value.absent(),
        kind: kind != null ? Value(kind) : const Value.absent(),
        targetCount: targetCount != null ? Value(targetCount) : const Value.absent(),
        frequencyType: frequencyType != null ? Value(frequencyType) : const Value.absent(),
        targetDays: targetDays != null ? Value(targetDays.join(',')) : const Value.absent(),
        graceDays: graceDays != null ? Value(graceDays) : const Value.absent(),
        isNegative: isNegative != null ? Value(isNegative) : const Value.absent(),
        reminderTimes: reminderTimes != null ? Value(reminderTimes.join(',')) : const Value.absent(),
        sortOrder: sortOrder != null ? Value(sortOrder) : const Value.absent(),
      ),
    );
  }

  Future<void> archiveHabit(String id) => _db.habitsDao.archiveHabit(id);

  Future<void> deleteHabit(String id) => _db.habitsDao.deleteHabit(id);

  Future<void> reorderHabits(List<String> orderedIds) =>
      _db.habitsDao.reorderHabits(orderedIds);

  // ── Helpers ────────────────────────────────────────────────────────────

  /// Parses the targetDays string back to a list of ints.
  static List<int> parseTargetDays(String raw) {
    if (raw.isEmpty) return [];
    return raw.split(',').map(int.parse).toList();
  }

  /// Builds a reminder times list from the stored string.
  static List<String> parseReminderTimes(String raw) {
    if (raw.isEmpty) return [];
    return raw.split(',');
  }
}
