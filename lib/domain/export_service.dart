import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/database/app_database.dart';
import '../data/repositories/completion_repository.dart';
import '../data/repositories/habit_repository.dart';

/// Data export / backup / restore service.
///
/// CSV  — one row per (habit, completion date). Safe for spreadsheets.
/// JSON — full app snapshot: habits + completions + tasks + moods.
/// Restore — validates JSON structure BEFORE deleting existing data.
///           Any parse failure throws; existing data is never touched.
class ExportService {
  final AppDatabase _db;
  final HabitRepository _habitRepo;
  final CompletionRepository _completionRepo;

  const ExportService(this._db, this._habitRepo, this._completionRepo);

  // ── CSV Export ─────────────────────────────────────────────────────────

  Future<void> exportCSV() async {
    final habits = await _habitRepo.getAllActive();
    final buf = StringBuffer()
      ..writeln('Habit Name,Date,Completed,Count,Note');

    for (final habit in habits) {
      final completions = await _completionRepo.getForHabit(habit.id);
      for (final c in completions) {
        // Escape commas in user content.
        final name = habit.name.replaceAll('"', '""');
        final note = (c.note ?? '').replaceAll('"', '""');
        buf.writeln('"$name",${c.date},true,${c.count},"$note"');
      }
    }

    final file = await _writeToTemp('streak_it_export.csv', buf.toString());
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Streak It — Habit History',
    );
  }

  // ── JSON Backup ────────────────────────────────────────────────────────

  Future<void> exportBackup() async {
    final habits = [
      ...await _db.habitsDao.getAllActive(),
      ...await _db.habitsDao.getArchived(),
    ];

    final habitList = <Map<String, dynamic>>[];
    for (final h in habits) {
      final completions = await _db.completionsDao.getForHabit(h.id);
      final tasks = await _db.tasksDao.getForHabit(h.id);

      habitList.add({
        'id': h.id,
        'name': h.name,
        'description': h.description,
        'colorHex': h.colorHex,
        'iconId': h.iconId,
        'emoji': h.emoji,
        'kind': h.kind,
        'targetCount': h.targetCount,
        'frequencyType': h.frequencyType,
        'targetDays': h.targetDays,
        'graceDays': h.graceDays,
        'isNegative': h.isNegative,
        'isArchived': h.isArchived,
        'sortOrder': h.sortOrder,
        'createdAt': h.createdAt,
        'reminderTimes': h.reminderTimes,
        'completions': completions
            .map((c) => {
                  'id': c.id,
                  'date': c.date,
                  'count': c.count,
                  'note': c.note,
                  'createdAt': c.createdAt,
                })
            .toList(),
        'tasks': tasks
            .map((t) => {
                  'id': t.id,
                  'title': t.title,
                  'sortOrder': t.sortOrder,
                  'completedDates': t.completedDates,
                })
            .toList(),
      });
    }

    final moods = await _db.moodsDao.getInRange(
      DateTime(2000),
      DateTime(2099),
    );

    final backup = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'habits': habitList,
      'moods': moods
          .map((m) => {
                'id': m.id,
                'habitId': m.habitId,
                'date': m.date,
                'mood': m.mood,
                'note': m.note,
                'createdAt': m.createdAt,
              })
          .toList(),
    };

    final json = const JsonEncoder.withIndent('  ').convert(backup);
    final file = await _writeToTemp('streak_it_backup.json', json);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Streak It — Full Backup',
    );
  }

  // ── JSON Restore ───────────────────────────────────────────────────────

  /// Restores from a JSON backup file.
  ///
  /// SAFETY-FIRST approach:
  ///   1. Read + parse file fully.
  ///   2. Validate version + required fields.
  ///   3. ONLY THEN delete existing data and write new records.
  ///
  /// If any step before step 3 fails, an exception is thrown and existing
  /// data is completely untouched.
  ///
  /// Returns the number of habits restored.
  Future<int> restoreBackup(String filePath) async {
    // ── Step 1: Read ─────────────────────────────────────────────────────
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Backup file not found at: $filePath');
    }
    final raw = await file.readAsString();

    // ── Step 2: Parse and validate ────────────────────────────────────────
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('Backup file is not valid JSON.');
    }

    final version = data['version'];
    if (version is! int || version != 1) {
      throw FormatException(
        'Unsupported backup version: $version. '
        'Only version 1 is supported.',
      );
    }

    final habitsJson = data['habits'];
    if (habitsJson is! List) {
      throw const FormatException('Backup is missing "habits" array.');
    }

    // Validate each habit has the minimum required fields before writing anything.
    for (final h in habitsJson) {
      if (h is! Map<String, dynamic>) {
        throw const FormatException('Invalid habit entry in backup.');
      }
      if (h['id'] is! String || h['name'] is! String || h['createdAt'] is! String) {
        throw const FormatException(
          'A habit entry is missing required fields (id, name, createdAt).',
        );
      }
    }

    // ── Step 3: Destructive write inside a transaction ───────────────────
    // If ANY insert fails, Drift rolls back to the pre-restore state.
    // The user's existing data is never partially overwritten.
    return await _db.transaction<int>(() async {
      await _db.delete(_db.habits).go();

      int count = 0;
      for (final h in habitsJson.cast<Map<String, dynamic>>()) {
        await _db.habitsDao.insertHabit(HabitsCompanion(
          id: Value(h['id'] as String),
          name: Value(h['name'] as String),
          description: Value(h['description'] as String?),
          colorHex: Value(h['colorHex'] as String? ?? '#F59E0B'),
          iconId: Value(h['iconId'] as String? ?? 'star'),
          emoji: Value(h['emoji'] as String?),
          kind: Value(h['kind'] as String? ?? 'binary'),
          targetCount: Value(h['targetCount'] as int? ?? 1),
          frequencyType: Value(h['frequencyType'] as String? ?? 'daily'),
          targetDays: Value(h['targetDays'] as String? ?? ''),
          graceDays: Value(h['graceDays'] as int? ?? 0),
          isNegative: Value(h['isNegative'] as bool? ?? false),
          isArchived: Value(h['isArchived'] as bool? ?? false),
          sortOrder: Value(h['sortOrder'] as int? ?? 0),
          createdAt: Value(h['createdAt'] as String),
          reminderTimes: Value(h['reminderTimes'] as String? ?? ''),
        ));

        final comps = (h['completions'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        for (final c in comps) {
          await _db.completionsDao.markCompleted(CompletionsCompanion(
            id: Value(c['id'] as String),
            habitId: Value(h['id'] as String),
            date: Value(c['date'] as String),
            count: Value(c['count'] as int? ?? 1),
            note: Value(c['note'] as String?),
            createdAt: Value(c['createdAt'] as String),
          ));
        }

        final tasks = (h['tasks'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        for (final t in tasks) {
          await _db.tasksDao.insertTask(HabitTasksCompanion(
            id: Value(t['id'] as String),
            habitId: Value(h['id'] as String),
            title: Value(t['title'] as String),
            sortOrder: Value(t['sortOrder'] as int? ?? 0),
            completedDates: Value(t['completedDates'] as String? ?? ''),
          ));
        }

        count++;
      }

      // Restore moods inside the same transaction.
      final moodsJson = (data['moods'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      for (final m in moodsJson) {
        await _db.moodsDao.upsertMood(MoodEntriesCompanion(
          id: Value(m['id'] as String),
          habitId: Value(m['habitId'] as String),
          date: Value(m['date'] as String),
          mood: Value(m['mood'] as int),
          note: Value(m['note'] as String?),
          createdAt: Value(m['createdAt'] as String),
        ));
      }

      return count;
    }); // end transaction
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Future<File> _writeToTemp(String filename, String content) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content, flush: true);
    return file;
  }
}
