import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/isar_service.dart';
import '../models/habit.dart';
import '../models/habit_checkin.dart';

const _uuid = Uuid();

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ALL HABITS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
final allHabitsProvider = StreamProvider<List<Habit>>((ref) {
  return IsarService.habits.where().sortBySortOrder().watch();
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TODAY'S HABITS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
final todayHabitsProvider = StreamProvider<List<Habit>>((ref) {
  final today = DateTime.now().weekday - 1; // 0=Mon
  return IsarService.habits
      .filter()
      .isActiveEqualTo(true)
      .activeDaysElementEqualTo(today)
      .sortBySortOrder()
      .watch();
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TODAY'S CHECK-INS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
final todayCheckinsProvider = StreamProvider<List<HabitCheckin>>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  return IsarService.checkins
      .filter()
      .dateBetween(today, tomorrow, includeLower: true, includeUpper: false)
      .watch();
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// COMPLETED HABIT IDS FOR TODAY (derived)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
final completedHabitIdsProvider = Provider<Set<String>>((ref) {
  final checkins = ref.watch(todayCheckinsProvider).valueOrNull ?? [];
  return checkins.where((c) => c.isCompleted).map((c) => c.habitId).toSet();
});

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// HABIT ACTIONS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

final habitActionsProvider = Provider<HabitActions>((ref) => HabitActions());

class HabitActions {
  Future<void> createHabit({
    required String name,
    required String emoji,
    required List<int> activeDays,
    String description = '',
    int? reminderHour,
    int? reminderMinute,
  }) async {
    final count = await IsarService.habits.count();
    final habit = Habit()
      ..habitId = _uuid.v4()
      ..name = name
      ..description = description
      ..emoji = emoji
      ..activeDays = activeDays
      ..reminderHour = reminderHour
      ..reminderMinute = reminderMinute
      ..habitType = 'binary'
      ..isActive = true
      ..currentStreak = 0
      ..longestStreak = 0
      ..totalCompletions = 0
      ..xpEarned = 0
      ..isSynced = false
      ..sortOrder = count
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await IsarService.habits.put(habit);
  }

  Future<void> toggleHabitCheckin(Habit habit) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final existing = await IsarService.checkins
        .filter()
        .habitIdEqualTo(habit.habitId)
        .dateBetween(today, tomorrow, includeLower: true, includeUpper: false)
        .findFirst();

    if (existing != null) {
      // Toggle: undo
      existing.isCompleted = !existing.isCompleted;
      await IsarService.checkins.put(existing);
    } else {
      // New check-in
      final checkin = HabitCheckin()
        ..checkinId = _uuid.v4()
        ..habitId = habit.habitId
        ..date = today
        ..createdAt = now
        ..isCompleted = true
        ..isSynced = false;
      await IsarService.checkins.put(checkin);
    }
  }

  Future<void> updateHabit(Habit habit, {String? name, String? emoji, List<int>? activeDays, String? description, int? sortOrder}) async {
    if (name != null) habit.name = name;
    if (emoji != null) habit.emoji = emoji;
    if (activeDays != null) habit.activeDays = activeDays;
    if (description != null) habit.description = description;
    if (sortOrder != null) habit.sortOrder = sortOrder;
    habit.updatedAt = DateTime.now();
    await IsarService.habits.put(habit);
  }

  Future<void> deleteHabit(Habit habit) async {
    await IsarService.habits.delete(habit.id);
  }
}
