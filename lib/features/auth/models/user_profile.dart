import 'package:isar_community/isar_community.dart';

part 'user_profile.g.dart';

@collection
class UserProfile {
  Id id = Isar.autoIncrement;
  late String userId; // Firebase UID or local UUID
  late String displayName;
  late String? timezonePreference;
  late bool onboardingCompleted;
  late String chronotype; // 'early_bird' | 'night_owl' | 'balanced'
  late String motivationStyle; // 'discipline' | 'reward' | 'accountability'
  late List<String> initialGoalCategories;
  late int totalXp;
  late int currentLevel;
  late int streakFlameIntensity;
  late bool notificationsEnabled;
  late bool widgetEnabled;
  late bool syncEnabled; // Opt-in, default false (privacy-first)
  late bool soundEnabled;
  late bool hapticEnabled;
  late DateTime createdAt;
  late DateTime updatedAt;
}