import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/database/app_database.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/streak_calculator.dart';
import '../../../domain/achievement_service.dart';
import '../../providers/database_providers.dart';
import '../../providers/habit_providers.dart';
import '../../widgets/progress_ring.dart';

// FIX 2 — ConsumerStatefulWidget caches the future so providers
// emitting new values don't flash the spinner unnecessarily.
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  Future<AchievementSnapshot>? _snapshotFuture;
  String _lastKey = '';

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsStreamProvider);
    final todayAsync = ref.watch(todayCompletionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: habitsAsync.when(
        data: (habits) => todayAsync.when(
          data: (todayCompletions) {
            // Only rebuild the future when inputs actually change
            final newKey = '${habits.map((h) => h.id).join()}_${todayCompletions.map((c) => c.id).join()}';
            if (newKey != _lastKey) {
              _lastKey = newKey;
              _snapshotFuture = _buildSnapshot(ref, habits, todayCompletions);
            }
            return FutureBuilder<AchievementSnapshot>(
              future: _snapshotFuture,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final snapshot = snap.data!;
                final results = AchievementService.evaluate(snapshot);
                final unlockedCount = results.values.where((v) => v).length;

                return _AchievementsBody(
                  snapshot: snapshot,
                  results: results,
                  unlockedCount: unlockedCount,
                  total: AchievementService.all.length,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<AchievementSnapshot> _buildSnapshot(
    WidgetRef ref,
    List<Habit> habits,
    List<Completion> todayCompletions,
  ) async {
    final completionRepo = ref.read(completionRepositoryProvider);
    int totalCompletions = 0;
    int maxCurrentStreak = 0;
    int maxBestStreak = 0;
    // FIX B — countMap for quantified-aware completedAllHabitsToday
    final completedTodayIds = todayCompletions.map((c) => c.habitId).toSet();
    final countMap = <String, int>{};
    for (final c in todayCompletions) {
      countMap[c.habitId] = (countMap[c.habitId] ?? 0) + c.count;
    }

    // FIX C — track actual expected completions for a correct denominator
    final today = StreakDateUtils.today();
    int totalExpected = 0;

    for (final habit in habits) {
      final dates = await completionRepo.getCompletedDates(habit.id);
      totalCompletions += dates.length;

      final targetDays = habit.targetDays.isEmpty
          ? <int>[]
          : habit.targetDays.split(',').map(int.parse).toList();

      // FIX C — count expected days from habit creation to today
      final habitStart = StreakDateUtils.dateOnly(DateTime.parse(habit.createdAt));
      var cursor = habitStart;
      while (!cursor.isAfter(today)) {
        if (targetDays.isEmpty || targetDays.contains(cursor.weekday)) {
          totalExpected++;
        }
        cursor = cursor.add(const Duration(days: 1));
      }

      final streak = StreakCalculator.calculate(
        completedDates: dates,
        startDate: DateTime.parse(habit.createdAt),
        graceDays: habit.graceDays,
        targetDays: targetDays,
      );

      if (streak.currentStreak > maxCurrentStreak) {
        maxCurrentStreak = streak.currentStreak;
      }
      if (streak.bestStreak > maxBestStreak) {
        maxBestStreak = streak.bestStreak;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final firstLaunchStr = prefs.getString(AppConstants.prefFirstLaunchDate);
    final totalXP = prefs.getInt(AppConstants.prefTotalXP) ?? 0;

    int daysTracking = 0;
    if (firstLaunchStr != null) {
      final first = DateTime.parse(firstLaunchStr);
      daysTracking = DateTime.now().difference(first).inDays;
    }

    final level = StreakCalculator.levelForXP(totalXP);
    // FIX C — use actual expected days as denominator
    final overallRate = totalExpected == 0
        ? 0.0
        : (totalCompletions / totalExpected).clamp(0.0, 1.0);

    // FIX B — quantified habits need count >= targetCount to count as done
    final completedAllHabitsToday = habits.isNotEmpty &&
        habits.every((h) {
          if (h.kind == 'quantified') {
            return (countMap[h.id] ?? 0) >= h.targetCount;
          }
          return completedTodayIds.contains(h.id);
        });

    return AchievementSnapshot(
      totalHabits: habits.length,
      maxCurrentStreak: maxCurrentStreak,
      maxBestStreak: maxBestStreak,
      totalCompletions: totalCompletions,
      totalXP: totalXP,
      level: level,
      overallCompletionRate: overallRate,
      completedAllHabitsToday: completedAllHabitsToday,
      habitsCreatedCount: habits.length,
      daysTracking: daysTracking,
    );
  }
}

class _AchievementsBody extends StatelessWidget {
  final AchievementSnapshot snapshot;
  final Map<String, bool> results;
  final int unlockedCount;
  final int total;

  const _AchievementsBody({
    required this.snapshot,
    required this.results,
    required this.unlockedCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final level = snapshot.level;
    final xpProgress = StreakCalculator.xpProgressInLevel(snapshot.totalXP);

    final unlocked =
        AchievementService.all.where((a) => results[a.id] == true).toList();
    final locked =
        AchievementService.all.where((a) => results[a.id] != true).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── XP / Level Card ────────────────────────────────────────────
        _LevelCard(
          level: level,
          totalXP: snapshot.totalXP,
          xpProgress: xpProgress,
        ).animate().fade(duration: 400.ms).slideY(begin: 0.1),

        const SizedBox(height: 20),

        // ── Progress ───────────────────────────────────────────────────
        Row(
          children: [
            Text(
              '$unlockedCount / $total achievements',
              style: AppTypography.titleSmall.copyWith(
                color: context.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '${(unlockedCount / total * 100).round()}% complete',
              style: AppTypography.labelMedium.copyWith(
                color: context.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
          child: LinearProgressIndicator(
            value: total > 0 ? unlockedCount / total : 0,
            minHeight: 6,
            backgroundColor: context.borderColor,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
          ),
        ),

        const SizedBox(height: 24),

        // ── Unlocked ───────────────────────────────────────────────────
        if (unlocked.isNotEmpty) ...[
          Text(
            'Unlocked (${unlocked.length})',
            style: AppTypography.titleMedium.copyWith(
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...unlocked.asMap().entries.map((entry) {
            return _AchievementTile(
              achievement: entry.value,
              isUnlocked: true,
            )
                .animate(delay: (entry.key * 50).ms)
                .fade(duration: 350.ms)
                .slideX(begin: -0.05);
          }),
          const SizedBox(height: 24),
        ],

        // ── Locked ─────────────────────────────────────────────────────
        if (locked.isNotEmpty) ...[
          Text(
            'Locked (${locked.length})',
            style: AppTypography.titleMedium.copyWith(
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...locked.map((a) => _AchievementTile(
                achievement: a,
                isUnlocked: false,
              )),
        ],
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  final int level;
  final int totalXP;
  final double xpProgress;

  const _LevelCard({
    required this.level,
    required this.totalXP,
    required this.xpProgress,
  });

  Color get _levelColor {
    if (level >= 10) return AppColors.levelDiamond;
    if (level >= 7) return AppColors.levelGold;
    if (level >= 4) return AppColors.levelSilver;
    return AppColors.levelBronze;
  }

  String get _levelLabel {
    if (level >= 10) return '💎 Diamond';
    if (level >= 7) return '🥇 Gold';
    if (level >= 4) return '🥈 Silver';
    return '🥉 Bronze';
  }

  @override
  Widget build(BuildContext context) {
    final nextThreshold = level < AppConstants.xpLevelThresholds.length
        ? AppConstants.xpLevelThresholds[level]
        : AppConstants.xpLevelThresholds.last;
    final currentThreshold = AppConstants.xpLevelThresholds[
        (level - 1).clamp(0, AppConstants.xpLevelThresholds.length - 1)];
    final xpInLevel = totalXP - currentThreshold;
    final xpNeeded = nextThreshold - currentThreshold;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Step 7: flat surface, amber border — no gradient anywhere
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          ProgressRing(
            progress: xpProgress,
            size: 80,
            strokeWidth: 6,
            // Step 7: amber for XP progress ring
            color: AppColors.brand,
            backgroundColor: context.borderColor,
            child: Center(
              child: Text(
                'L$level',
                style: AppTypography.statSmall.copyWith(color: AppColors.brand),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _levelLabel,
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${totalXP.xpFormatted} XP total',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$xpInLevel / $xpNeeded XP to next level',
                  style: AppTypography.labelSmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;

  const _AchievementTile({
    required this.achievement,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    // Step 7: two-state only. Green = unlocked. Grey = locked. No rarity rainbow.
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnlocked
            ? AppColors.successFill
            : context.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(
          color: isUnlocked
              ? AppColors.success.withValues(alpha: 0.3)
              : context.borderColor,
          width: isUnlocked ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Emoji badge
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              // Step 7: green tint unlocked, grey locked
              color: isUnlocked
                  ? AppColors.successFill
                  : context.surface2Color,
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Center(
              child: Text(
                isUnlocked ? achievement.emoji : '🔒',
                style: TextStyle(
                  fontSize: 22,
                  color: isUnlocked ? null : context.textMuted,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      achievement.title,
                      style: AppTypography.titleSmall.copyWith(
                        color: isUnlocked
                            ? context.textPrimary
                            : context.textMuted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        // Step 7: amber pill for unlocked, grey for locked
                        color: isUnlocked
                            ? AppColors.brandFill
                            : context.surface2Color,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusCircle),
                      ),
                      child: Text(
                        AchievementService.rarityLabel(achievement.rarity),
                        style: AppTypography.caption.copyWith(
                          color: isUnlocked ? AppColors.brand : context.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: isUnlocked ? context.textSecondary : context.textMuted,
                  ),
                ),
              ],
            ),
          ),

          if (isUnlocked)
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 20,
            ),
        ],
      ),
    );
  }
}
