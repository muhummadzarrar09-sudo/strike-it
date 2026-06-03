import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:uuid/uuid.dart';

import '../../../core/constants/habit_icons.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/streak_calculator.dart';
import '../../../data/database/app_database.dart';
import '../../providers/database_providers.dart';
import '../../providers/habit_providers.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/task_checklist.dart';

class HabitDetailScreen extends ConsumerWidget {
  final String habitId;
  const HabitDetailScreen({super.key, required this.habitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitAsync = ref.watch(habitByIdProvider(habitId));
    return habitAsync.when(
      data: (habit) {
        if (habit == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Habit not found.')),
          );
        }
        return _DetailView(habit: habit);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _DetailView extends ConsumerWidget {
  final Habit habit;
  const _DetailView({required this.habit});

  Color get _color => habit.colorHex.toColor();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(themeProvider).accent.primary;
    final streakAsync = ref.watch(habitStreakProvider(habit.id));
    final completionsAsync = ref.watch(habitCompletionsProvider(habit.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push(Routes.editHabitPath(habit.id)),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showHabitActions(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Identity card ──────────────────────────────────────────────
          _IdentityCard(habit: habit, color: habit.colorHex.toColor())
              .animate()
              .fade(duration: 350.ms)
              .slideY(begin: 0.08),

          const SizedBox(height: 14),

          // ── Streak stats row ───────────────────────────────────────────
          streakAsync.when(
            data: (streak) => _StreakRow(streak: streak, color: habit.colorHex.toColor())
                .animate(delay: 60.ms)
                .fade(duration: 350.ms)
                .slideY(begin: 0.08),
            loading: () => const SizedBox(height: 100),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 14),

          // ── Score card ─────────────────────────────────────────────────
          streakAsync.when(
            data: (streak) => _ScoreCard(streak: streak, color: habit.colorHex.toColor(), accent: accent)
                .animate(delay: 100.ms)
                .fade(duration: 350.ms),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 14),

          // ── 35-day calendar ────────────────────────────────────────────
          completionsAsync.when(
            data: (comps) {
              final dates =
                  comps.map((c) => StreakDateUtils.fromIsoDate(c.date)).toSet();
              return _MiniCalendar(completedDates: dates, color: habit.colorHex.toColor())
                  .animate(delay: 140.ms)
                  .fade(duration: 350.ms);
            },
            loading: () => const SizedBox(height: 120),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 14),

          // ── Sub-task checklist ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(color: context.borderColor),
            ),
            child: TaskChecklist(
              habitId: habit.id,
              accentColor: _color,
            ),
          ).animate(delay: 180.ms).fade(duration: 350.ms),

          const SizedBox(height: 14),

          // ── Today's mood log ───────────────────────────────────────────
          _MoodSection(habitId: habit.id, accent: accent)
              .animate(delay: 220.ms)
              .fade(duration: 350.ms),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _showHabitActions(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archive habit'),
              subtitle: const Text("Won't appear in Today anymore"),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(habitRepositoryProvider).archiveHabit(habit.id);
                // FIX 3 — cancel orphaned reminders immediately
                final remaining = await ref.read(habitRepositoryProvider).getAllActive();
                await ref.read(notificationServiceProvider).rescheduleAll(remaining);
                if (context.mounted) {
                  context.showSnack("Habit archived. It won't appear in Today.");
                  context.pop();
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.destructive),
              title: Text('Delete permanently',
                  style: TextStyle(color: AppColors.destructive)),
              subtitle: const Text('Cannot be undone'),
              onTap: () async {
                Navigator.pop(context);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete habit?'),
                    content: Text(
                      'Permanently delete "${habit.name}" and all its history. Cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.destructive),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref.read(habitRepositoryProvider).deleteHabit(habit.id);
                  // FIX 3 — cancel orphaned reminders immediately
                  final remaining = await ref.read(habitRepositoryProvider).getAllActive();
                  await ref.read(notificationServiceProvider).rescheduleAll(remaining);
                  if (context.mounted) context.pop();
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Identity Card ──────────────────────────────────────────────────────────

class _IdentityCard extends StatelessWidget {
  final Habit habit;
  final Color color;

  const _IdentityCard({required this.habit, required this.color});

  @override
  Widget build(BuildContext context) {
    final icon = HabitIcons.fromId(habit.iconId);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Center(
              child: habit.emoji != null
                  ? Text(habit.emoji!, style: const TextStyle(fontSize: 26))
                  : Icon(icon.icon, color: color, size: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: AppTypography.headlineSmall.copyWith(
                    color: context.textPrimary,
                  ),
                ),
                if (habit.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 3),
                  Text(
                    habit.description!,
                    style: AppTypography.bodySmall.copyWith(
                        color: context.textMuted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Pill(
                      label: habit.isNegative ? 'Avoid' : 'Build',
                      color: habit.isNegative
                          ? AppColors.destructive
                          : AppColors.success,
                    ),
                    _Pill(
                      label: habit.frequencyType.capitalised,
                      color: color,
                    ),
                    _Pill(
                      label: habit.kind == 'quantified'
                          ? 'Count × ${habit.targetCount}'
                          : 'Binary',
                      color: color,
                    ),
                    if (habit.graceDays > 0)
                      _Pill(
                        label: '${habit.graceDays}d grace',
                        color: AppColors.warning,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Streak Row ─────────────────────────────────────────────────────────────

class _StreakRow extends StatelessWidget {
  final StreakResult streak;
  final Color color;
  const _StreakRow({required this.streak, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Current Streak',
            value: '${streak.currentStreak}',
            unit: 'days',
            icon: Icons.local_fire_department,
            color: streak.isAtRisk ? AppColors.warning : color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Best Streak',
            value: '${streak.bestStreak}',
            unit: 'days',
            icon: Icons.emoji_events,
            color: AppColors.levelGold,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: value,
                style: AppTypography.statLarge.copyWith(color: color),
              ),
              TextSpan(
                text: ' $unit',
                style: AppTypography.bodySmall.copyWith(color: context.textMuted),
              ),
            ]),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: context.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Score Card ─────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final StreakResult streak;
  final Color color;
  final Color accent;

  const _ScoreCard({
    required this.streak,
    required this.color,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final score = streak.score;
    final scoreColor =
        score >= 80 ? AppColors.success : score >= 50 ? color : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          ProgressRing(
            progress: score / 100,
            size: 70,
            strokeWidth: 6,
            color: scoreColor,
            backgroundColor: context.borderColor,
            child: Center(
              child: Text(
                score.round().toString(),
                style: AppTypography.statSmall.copyWith(color: scoreColor),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consistency Score',
                  style: AppTypography.titleMedium.copyWith(
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _desc(score),
                  style: AppTypography.bodySmall.copyWith(
                    color: context.textMuted,
                    height: 1.5,
                  ),
                ),
                if (streak.nextMilestone != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${streak.daysToNextMilestone}d → ${streak.nextMilestone}-day milestone',
                    style: AppTypography.labelSmall.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _desc(double score) {
    if (score >= 90) return 'Exceptional. You\'ve made this a lifestyle.';
    if (score >= 75) return 'Strong momentum. Keep it going.';
    if (score >= 50) return 'Building consistency. Stay the course.';
    if (score >= 25) return 'Early days. Every log moves this score.';
    return 'Just getting started. The first 7 days are hardest.';
  }
}

// ── Mini Calendar ──────────────────────────────────────────────────────────

class _MiniCalendar extends StatelessWidget {
  final Set<DateTime> completedDates;
  final Color color;

  const _MiniCalendar({required this.completedDates, required this.color});

  @override
  Widget build(BuildContext context) {
    final today = StreakDateUtils.today();
    final days = List.generate(35, (i) => today.subtract(Duration(days: 34 - i)));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 5 weeks',
            style: AppTypography.titleSmall.copyWith(color: context.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'].map((d) {
              return SizedBox(
                width: 28,
                child: Text(
                  d,
                  style: AppTypography.caption.copyWith(color: context.textMuted),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: days.length,
            itemBuilder: (context, i) {
              final day = days[i];
              final done = completedDates.any(
                (d) => d.year == day.year && d.month == day.month && d.day == day.day,
              );
              final isToday = day.isToday;
              final isFuture = day.isAfter(today);

              return Tooltip(
                message: '${StreakDateUtils.shortMonth(day.month)} ${day.day}',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  decoration: BoxDecoration(
                    color: done
                        ? color
                        : isFuture
                            ? Colors.transparent
                            : context.surface2Color,
                    borderRadius: BorderRadius.circular(5),
                    border: isToday && !done
                        ? Border.all(color: color, width: 1.5)
                        : null,
                  ),
                  child: done
                      ? Center(
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 9,
                          ),
                        )
                      : isToday
                          ? Center(
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Mood Section ───────────────────────────────────────────────────────────

class _MoodSection extends ConsumerStatefulWidget {
  final String habitId;
  final Color accent;

  const _MoodSection({required this.habitId, required this.accent});

  @override
  ConsumerState<_MoodSection> createState() => _MoodSectionState();
}

class _MoodSectionState extends ConsumerState<_MoodSection> {
  int? _todayMood;
  bool _loading = true;

  static const _moods = [
    (1, '😟', 'Rough'),
    (2, '😐', 'Okay'),
    (3, '😊', 'Good'),
    (4, '🤩', 'Great'),
  ];

  @override
  void initState() {
    super.initState();
    _loadMood();
  }

  Future<void> _loadMood() async {
    final db = ref.read(databaseProvider);
    final entry = await db.moodsDao.getForDate(widget.habitId, StreakDateUtils.today());
    if (mounted) {
      setState(() {
        _todayMood = entry?.mood;
        _loading = false;
      });
    }
  }

  Future<void> _logMood(int mood) async {
    setState(() => _todayMood = mood);
    final db = ref.read(databaseProvider);
    await db.moodsDao.upsertMood(
      MoodEntriesCompanion(
        id: Value(const Uuid().v4()),
        habitId: Value(widget.habitId),
        date: Value(StreakDateUtils.toIsoDate(StreakDateUtils.today())),
        mood: Value(mood),
        createdAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How do you feel today?',
            style: AppTypography.titleSmall.copyWith(color: context.textSecondary),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()))
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _moods.map((m) {
                final selected = _todayMood == m.$1;
                return GestureDetector(
                  onTap: () => _logMood(m.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? widget.accent.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      border: Border.all(
                        color: selected ? widget.accent : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          m.$2,
                          style: TextStyle(
                            fontSize: selected ? 26 : 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.$3,
                          style: AppTypography.caption.copyWith(
                            color: selected
                                ? widget.accent
                                : context.textMuted,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}


