import 'package:isar_community/isar_community.dart';

part 'habit_checkin.g.dart';

@collection
class HabitCheckin {
  Id id = Isar.autoIncrement;
  late String checkinId;
  late String habitId;
  late DateTime date;
  late DateTime createdAt;
  late bool isCompleted;
  late String? moodEmoji;
  late int? moodRating;
  late String? reflection;
  late bool isSynced;
}