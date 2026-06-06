import 'package:isar_community/isar_community.dart';

part 'habit.g.dart';

@collection
class Habit {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String habitId;

  late String name;
  late String description;
  late String emoji;
  late DateTime createdAt;
  late DateTime updatedAt;
  late String habitType; // 'binary' (future: 'numeric', 'timed', 'rating')
  late bool isActive;
  late List<int> activeDays; // [0=Mon..6=Sun]
  late int? reminderHour;
  late int? reminderMinute;
  late int currentStreak;
  late int longestStreak;
  late int totalCompletions;
  late DateTime? lastCompletedDate;
  late int xpEarned;
  late bool isSynced;
  late DateTime? lastSyncedAt;
  late int sortOrder;
}