import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/habits_table.dart';
import 'tables/completions_table.dart';
import 'tables/tasks_table.dart';
import 'tables/moods_table.dart';
import 'daos/habits_dao.dart';
import 'daos/completions_dao.dart';
import 'daos/tasks_dao.dart';
import 'daos/moods_dao.dart';
import '../../core/constants/app_constants.dart';

part 'app_database.g.dart';

/// The top-level Drift database for StreakIt.
///
/// Drift generates the implementation in [app_database.g.dart] via build_runner.
/// Run: flutter pub run build_runner build --delete-conflicting-outputs
///
/// Database is stored at: [app-documents]/streak_it.db
/// It is 100% offline and never synced to a server.
@DriftDatabase(
  tables: [Habits, Completions, HabitTasks, MoodEntries],
  daos: [HabitsDao, CompletionsDao, TasksDao, MoodsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Allow injecting a test executor (e.g. in-memory SQLite for unit tests).
  AppDatabase.forTesting(DatabaseConnection connection) : super(connection);

  @override
  int get schemaVersion => AppConstants.dbVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Future migrations go here. Each version bump should have its own
          // if (from < N) block to allow rolling upgrades from any prior version.
          //
          // Example for future sprint:
          // if (from < 2) {
          //   await m.addColumn(habits, habits.someNewColumn);
          // }
        },
        beforeOpen: (details) async {
          // Enable foreign key enforcement in SQLite.
          await customStatement('PRAGMA foreign_keys = ON');
          // Enable WAL mode for better concurrent read performance.
          await customStatement('PRAGMA journal_mode = WAL');
        },
      );

  // Singleton instance — one DB connection for the app's lifetime.
  // Lazily created on first access; invalidated on close().
  static AppDatabase? _instance;

  /// Returns the singleton database instance, creating it if needed.
  static AppDatabase get instance {
    _instance ??= AppDatabase();
    return _instance!;
  }

  /// Resets the singleton — used in tests and after close().
  @visibleForTesting
  static void resetInstance() => _instance = null;

  /// Closes the connection and clears the singleton so the next
  /// [instance] call will create a fresh connection.
  @override
  Future<void> close() async {
    _instance = null;
    return super.close();
  }
}

/// Opens the SQLite file in the app's documents directory.
QueryExecutor _openConnection() {
  return driftDatabase(
    name: AppConstants.dbName,
    native: DriftNativeOptions(
      databaseDirectory: () async {
        final dir = await getApplicationDocumentsDirectory();
        return dir;
      },
    ),
  );
}
