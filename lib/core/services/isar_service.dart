import 'package:flutter/foundation.dart';
import 'package:isar_community/isar_community.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/habits/models/habit.dart';
import '../../features/habits/models/habit_checkin.dart';
import '../../features/journal/models/journal_entry.dart';
import '../../features/auth/models/user_profile.dart';
import '../../features/gamification/models/badge.dart';
import '../constants/app_constants.dart';

class IsarService {
  IsarService._();
  static Isar? _isar;

  static Isar get instance {
    if (_isar == null) throw StateError('Isar not initialized. Call IsarService.init() first.');
    return _isar!;
  }

  static Future<void> init() async {
    if (_isar != null) return;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [HabitSchema, HabitCheckinSchema, JournalEntrySchema, UserProfileSchema, BadgeSchema],
      directory: dir.path,
      name: AppConstants.isarDbName,
      inspector: kDebugMode,
    );
    debugPrint('✅ Isar initialized at: ${dir.path}');
  }

  static Future<void> close() async { await _isar?.close(); _isar = null; }

  static IsarCollection<Habit> get habits => instance.habits;
  static IsarCollection<HabitCheckin> get checkins => instance.habitCheckins;
  static IsarCollection<JournalEntry> get journal => instance.journalEntrys;
  static IsarCollection<UserProfile> get profiles => instance.userProfiles;
  static IsarCollection<Badge> get badges => instance.badges;
}