import 'package:isar_community/isar_community.dart';
part 'badge.g.dart';

@collection
class Badge {
  Id id = Isar.autoIncrement;
  late String badgeId;
  late String name;
  late String description;
  late String emoji;
  late String category;
  late String unlockType;
  late int unlockValue;
  late bool isUnlocked;
  late DateTime? unlockedAt;
  late int tier; // 1=Bronze, 2=Silver, 3=Gold, 4=Legendary
}