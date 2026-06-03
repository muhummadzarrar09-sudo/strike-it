import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/repositories/completion_repository.dart';
import '../../domain/notification_service.dart';
import '../../domain/xp_service.dart';
import '../../domain/export_service.dart';

// ── Database ───────────────────────────────────────────────────────────────

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.instance;
  ref.onDispose(db.close);
  return db;
});

// ── Repositories ───────────────────────────────────────────────────────────

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository(ref.watch(databaseProvider));
});

final completionRepositoryProvider = Provider<CompletionRepository>((ref) {
  return CompletionRepository(ref.watch(databaseProvider));
});

// ── Services ───────────────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final xpServiceProvider = Provider<XPService>((ref) {
  return XPService();
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(
    ref.watch(databaseProvider),
    ref.watch(habitRepositoryProvider),
    ref.watch(completionRepositoryProvider),
  );
});
