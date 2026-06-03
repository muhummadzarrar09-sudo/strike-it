import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/moods_table.dart';
import '../../../core/utils/date_utils.dart';

part 'moods_dao.g.dart';

@DriftAccessor(tables: [MoodEntries])
class MoodsDao extends DatabaseAccessor<AppDatabase> with _$MoodsDaoMixin {
  MoodsDao(super.db);

  // ── Read ───────────────────────────────────────────────────────────────

  // FIX #2 — getForDate now scoped to a specific habitId
  // Previously all habits shared one mood entry per day — wrong.
  Future<MoodEntry?> getForDate(String habitId, DateTime date) {
    final dateStr = StreakDateUtils.toIsoDate(date);
    return (select(moodEntries)
          ..where((m) => m.habitId.equals(habitId) & m.date.equals(dateStr)))
        .getSingleOrNull();
  }

  Future<List<MoodEntry>> getInRange(DateTime from, DateTime to) {
    final fromStr = StreakDateUtils.toIsoDate(from);
    final toStr = StreakDateUtils.toIsoDate(to);
    return (select(moodEntries)
          ..where((m) =>
              m.date.isBiggerOrEqualValue(fromStr) &
              m.date.isSmallerOrEqualValue(toStr))
          ..orderBy([(m) => OrderingTerm.asc(m.date)]))
        .get();
  }

  Stream<List<MoodEntry>> watchRecent(int days) {
    final from = StreakDateUtils.toIsoDate(
      DateTime.now().subtract(Duration(days: days)),
    );
    return (select(moodEntries)
          ..where((m) => m.date.isBiggerOrEqualValue(from))
          ..orderBy([(m) => OrderingTerm.asc(m.date)]))
        .watch();
  }

  // ── Write ──────────────────────────────────────────────────────────────

  Future<void> upsertMood(MoodEntriesCompanion entry) async {
    await into(moodEntries).insertOnConflictUpdate(entry);
  }

  Future<int> deleteMood(String id) {
    return (delete(moodEntries)..where((m) => m.id.equals(id))).go();
  }
}
