import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/streak_calculator.dart';
import '../../../data/database/app_database.dart';
import '../../../data/models/analytics_data.dart';
import '../../providers/database_providers.dart';
import '../../providers/habit_providers.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/progress_ring.dart';

/// Analytics Hub — real, data-backed insights.
///
/// Sections:
///   1. Overview stats cards
///   2. 7-day bar chart (daily completion rate)
///   3. Activity heatmap (period days)
///   4. Per-habit completion rate bars
///   5. Best day of week analysis
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _period = 30;

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(themeProvider).accent.primary;
    final habitsAsync = ref.watch(habitsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _period,
                style: AppTypography.labelMedium.copyWith(
                  color: context.textPrimary,
                ),
                dropdownColor: context.surfaceColor,
                items: const [
                  DropdownMenuItem(value: 7, child: Text('7 days')),
                  DropdownMenuItem(value: 30, child: Text('30 days')),
                  DropdownMenuItem(value: 90, child: Text('90 days')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _period = v);
                },
              ),
            ),
          ),
        ],
      ),
      body: habitsAsync.when(
        data: (habits) {
          if (habits.isEmpty) {
            return _EmptyAnalytics();
          }
          return _AnalyticsBody(
            habits: habits,
            period: _period,
            accent: accent,
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Error loading habits: $e')),
      ),
    );
  }
}

// ── Body ───────────────────────────────────────────────────────────────────

/// Typed [List<Habit>] — no more dynamic.
class _AnalyticsBody extends ConsumerWidget {
  final List<Habit> habits;
  final int period;
  final Color accent;

  const _AnalyticsBody({
    required this.habits,
    required this.period,
    required this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = StreakDateUtils.today();
    final from = today.subtract(Duration(days: period - 1));

    // FIX 2 — watch completions so key changes when they emit new data
    final todaySnap = ref.watch(todayCompletionsProvider);

    return FutureBuilder<_AnalyticsData>(
      key: ValueKey('${habits.map((h) => h.id).join()}_${period}_${todaySnap.value?.map((c) => c.id).join() ?? ''}'),
      future: _loadData(ref, from, today),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load analytics.',
              style: AppTypography.bodyMedium.copyWith(color: context.textMuted),
            ),
          );
        }
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();
        // Fix 5: friendly empty state when no check-ins exist yet
        if (data.totalCompletions == 0) return _EmptyAnalytics();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Overview cards ───────────────────────────────────────────
            _SectionTitle('Overview'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniStatCard(
                    label: 'Total Habits',
                    value: '${habits.length}',
                    icon: Icons.checklist,
                    // FIX 4C: neutral — count/icon use textPrimary not brand color
                    color: context.textSecondary,
                  ).animate().fade(duration: 400.ms).slideY(begin: 0.1),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStatCard(
                    label: 'Completion',
                    value: '${(data.completionRate * 100).round()}%',
                    icon: Icons.check_circle_outline,
                    color: AppColors.success,
                  ).animate().fade(duration: 400.ms, delay: 60.ms).slideY(begin: 0.1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniStatCard(
                    label: 'Check-ins',
                    value: '${data.totalCompletions}',
                    icon: Icons.local_fire_department,
                    color: AppColors.warning,
                  ).animate().fade(duration: 400.ms, delay: 120.ms).slideY(begin: 0.1),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStatCard(
                    label: 'Best Streak',
                    value: '${data.bestStreak}d',
                    icon: Icons.emoji_events,
                    color: AppColors.levelGold,
                  ).animate().fade(duration: 400.ms, delay: 180.ms).slideY(begin: 0.1),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Bar chart ────────────────────────────────────────────────
            _SectionTitle('Last ${period <= 14 ? period : 14} days — completion rate'),
            const SizedBox(height: 12),
            data.dailyCounts.isNotEmpty
                ? _WeekBarChart(
                    dailyCounts: data.dailyCounts,
                    accent: accent,
                    totalHabits: habits.length,
                    period: period,
                  ).animate().fade(duration: 500.ms).slideY(begin: 0.1)
                : _EmptyChart(accent: accent),

            const SizedBox(height: 28),

            // ── Heatmap ──────────────────────────────────────────────────
            _SectionTitle('Activity heatmap ($period days)'),
            const SizedBox(height: 12),
            _HeatmapGrid(
              from: from,
              to: today,
              completedDateMap: data.completedDateMap,
              accent: accent,
              totalHabits: habits.length,
            ).animate().fade(duration: 600.ms),

            const SizedBox(height: 28),

            // ── Per-habit bars ───────────────────────────────────────────
            if (data.habitRates.isNotEmpty) ...[
              _SectionTitle('Per-habit completion rate'),
              const SizedBox(height: 12),
              ...data.habitRates.asMap().entries.map((e) {
                return _HabitRateRow(
                  name: e.value.name,
                  rate: e.value.rate,
                  colorHex: e.value.colorHex,
                  accent: accent,
                ).animate(delay: (e.key * 40).ms).fade(duration: 350.ms);
              }),
              const SizedBox(height: 28),
            ],

            // ── Best day of week ─────────────────────────────────────────
            _SectionTitle('Best day of the week'),
            const SizedBox(height: 12),
            _DayOfWeekChart(
              byDay: data.byDay,
              accent: accent,
            ).animate().fade(duration: 500.ms),

            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  Future<_AnalyticsData> _loadData(
    WidgetRef ref,
    DateTime from,
    DateTime to,
  ) async {
    final repo = ref.read(completionRepositoryProvider);
    final db = ref.read(databaseProvider);

    // Aggregate counts per day for the heatmap / bar chart.
    final dailyCounts =
        await db.completionsDao.getDailyCountsInRange(from, to);

    int totalCompletions = 0;
    int bestStreak = 0;
    double totalRate = 0.0;
    final habitRates = <_HabitRate>[];
    final Map<DateTime, int> dateMap = {};
    final List<int> byDay = List.filled(7, 0);

    for (final habit in habits) {
      final completions =
          await repo.getForHabitInRange(habit.id, from, to);
      totalCompletions += completions.length;

      final expected = _expectedDays(habit, from, to);
      final rate = expected > 0
          ? (completions.length / expected).clamp(0.0, 1.0)
          : 0.0;
      totalRate += rate;

      habitRates.add(_HabitRate(
        name: habit.name,
        rate: rate,
        colorHex: habit.colorHex,
      ));

      // Accumulate by weekday and populate the date map.
      for (final c in completions) {
        final d = StreakDateUtils.fromIsoDate(c.date);
        byDay[d.weekday - 1]++;
        dateMap[d] = (dateMap[d] ?? 0) + 1;
      }

      // Compute best streak using the proper engine (includes grace days).
      final allDates =
          await repo.getCompletedDates(habit.id);
      final targetDays = habit.targetDays.isEmpty
          ? <int>[]
          : habit.targetDays.split(',').map(int.parse).toList();

      final result = StreakCalculator.calculate(
        completedDates: allDates,
        startDate: DateTime.parse(habit.createdAt),
        graceDays: habit.graceDays,
        targetDays: targetDays,
      );
      if (result.bestStreak > bestStreak) bestStreak = result.bestStreak;
    }

    habitRates.sort((a, b) => b.rate.compareTo(a.rate));

    final overallRate =
        habits.isEmpty ? 0.0 : totalRate / habits.length;

    return _AnalyticsData(
      completionRate: overallRate,
      totalCompletions: totalCompletions,
      bestStreak: bestStreak,
      dailyCounts: dailyCounts
          .map((d) => _DailyCount(date: d.date, count: d.count))
          .toList(),
      habitRates: habitRates,
      byDay: byDay,
      completedDateMap: dateMap,
    );
  }

  /// Counts the number of expected days for [habit] in [from]..[to].
  int _expectedDays(Habit habit, DateTime from, DateTime to) {
    final targetDays = habit.targetDays.isEmpty
        ? <int>[]
        : habit.targetDays.split(',').map(int.parse).toList();

    int count = 0;
    var cursor = StreakDateUtils.dateOnly(from);
    final end = StreakDateUtils.dateOnly(to);
    while (!cursor.isAfter(end)) {
      if (targetDays.isEmpty || targetDays.contains(cursor.weekday)) {
        count++;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return count;
  }
}

// ── Data models ────────────────────────────────────────────────────────────

class _AnalyticsData {
  final double completionRate;
  final int totalCompletions;
  final int bestStreak;
  final List<_DailyCount> dailyCounts;
  final List<_HabitRate> habitRates;
  final List<int> byDay;
  final Map<DateTime, int> completedDateMap;

  const _AnalyticsData({
    required this.completionRate,
    required this.totalCompletions,
    required this.bestStreak,
    required this.dailyCounts,
    required this.habitRates,
    required this.byDay,
    required this.completedDateMap,
  });
}

class _DailyCount {
  final DateTime date;
  final int count;
  const _DailyCount({required this.date, required this.count});
}

class _HabitRate {
  final String name;
  final double rate;
  final String colorHex;
  const _HabitRate({
    required this.name,
    required this.rate,
    required this.colorHex,
  });
}

// ── Charts ─────────────────────────────────────────────────────────────────

class _WeekBarChart extends StatelessWidget {
  final List<_DailyCount> dailyCounts;
  final Color accent;
  final int totalHabits;
  final int period; // FIX 4 — passed from parent

  const _WeekBarChart({
    required this.dailyCounts,
    required this.accent,
    required this.totalHabits,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final today = StreakDateUtils.today();
    // FIX 4 — cap at 14 bars (beyond that is unreadable on mobile)
    final chartDays = period.clamp(1, 14);
    final days = List.generate(
      chartDays,
      (i) => today.subtract(Duration(days: chartDays - 1 - i)),
    );

    final countMap = <DateTime, int>{
      for (final d in dailyCounts) d.date: d.count,
    };

    // Use list index as x — weekday only makes sense for exactly 7 bars
    final bars = days.asMap().entries.map((entry) {
      final i = entry.key;
      final d = entry.value;
      final count = countMap[d] ?? 0;
      final pct = totalHabits > 0 ? (count / totalHabits).clamp(0.0, 1.0) : 0.0;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: pct,
            // FIX 4A: all bar chart bars are amber — activity data not completion metric
            color: pct >= 0.7
                ? AppColors.brand
                : pct >= 0.4
                    ? AppColors.brand.withValues(alpha: 0.65)
                    : AppColors.brand.withValues(alpha: 0.35),
            width: 28,
            borderRadius: BorderRadius.circular(6),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 1.0,
              color: context.borderColor,
            ),
          ),
        ],
      );
    }).toList();

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: context.borderColor),
      ),
      child: BarChart(
        BarChartData(
          maxY: 1.0,
          barGroups: bars,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                // FIX 4 — show label every ~2 days for readability
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx >= days.length) return const SizedBox.shrink();
                  // Only label every other bar when > 7 bars
                  if (chartDays > 7 && idx % 2 != 0) return const SizedBox.shrink();
                  final d = days[idx];
                  final label = chartDays <= 7
                      ? StreakDateUtils.shortWeekday(d.weekday).substring(0, 2)
                      : '${d.day}';
                  return Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: context.textMuted,
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => context.surfaceColor,
              getTooltipItem: (_, __, rod, ___) => BarTooltipItem(
                '${(rod.toY * 100).round()}%',
                AppTypography.labelSmall.copyWith(
                  color: context.textPrimary,
                ),
              ),
            ),
          ),
        ),
        swapAnimationDuration: const Duration(milliseconds: 600),
        swapAnimationCurve: Curves.easeInOut,
      ),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final Map<DateTime, int> completedDateMap;
  final Color accent;
  final int totalHabits;

  const _HeatmapGrid({
    required this.from,
    required this.to,
    required this.completedDateMap,
    required this.accent,
    required this.totalHabits,
  });

  @override
  Widget build(BuildContext context) {
    final days = StreakDateUtils.dateRange(from, to);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: context.borderColor),
      ),
      child: Wrap(
        spacing: 3,
        runSpacing: 3,
        children: days.map((day) {
          final count = completedDateMap[day] ?? 0;
          final intensity = totalHabits > 0
              ? (count / totalHabits).clamp(0.0, 1.0)
              : 0.0;
          return Tooltip(
            message:
                '${StreakDateUtils.shortMonth(day.month)} ${day.day}: $count completed',
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: _heatColor(intensity, context),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _heatColor(double intensity, BuildContext context) {
    if (intensity <= 0) return context.surface2Color;
    if (intensity < 0.25) return AppColors.heatmapL1;
    if (intensity < 0.50) return AppColors.heatmapL2;
    if (intensity < 0.75) return AppColors.heatmapL3;
    if (intensity < 1.00) return AppColors.heatmapL4;
    return AppColors.heatmapL5;
  }
}

class _DayOfWeekChart extends StatelessWidget {
  final List<int> byDay;
  final Color accent;

  const _DayOfWeekChart({required this.byDay, required this.accent});

  @override
  Widget build(BuildContext context) {
    final maxVal = byDay.isEmpty
        ? 1
        : byDay.reduce((a, b) => a > b ? a : b).clamp(1, 999999);
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: List.generate(7, (i) {
          final count = i < byDay.length ? byDay[i] : 0;
          final frac = count / maxVal;
          final isMax = count == maxVal && count > 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    labels[i],
                    style: AppTypography.labelSmall.copyWith(
                      color: isMax
                          ? context.textPrimary
                          : context.textMuted,
                      fontWeight: isMax
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: frac,
                      minHeight: 8,
                      backgroundColor: context.borderColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        // FIX 4B: amber for all day-of-week bars, including best day
                        isMax
                            ? AppColors.brand
                            : AppColors.brand.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$count',
                  style: AppTypography.statSmall.copyWith(
                    // FIX 4B: amber for best day count
                    color: isMax ? AppColors.brand : context.textMuted,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _HabitRateRow extends StatelessWidget {
  final String name;
  final double rate;
  final String colorHex;
  final Color accent;

  const _HabitRateRow({
    required this.name,
    required this.rate,
    required this.colorHex,
    required this.accent,
  });

  Color get _color => colorHex.toColor();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(rate * 100).round()}%',
                style: AppTypography.statSmall.copyWith(color: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: context.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Utility ────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.titleMedium.copyWith(color: context.textPrimary),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.label,
    required this.value,
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
          Row(children: [Icon(icon, color: color, size: 18)]),
          const SizedBox(height: 8),
          Text(value,
              style: AppTypography.statMedium.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.caption.copyWith(color: context.textMuted)),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final Color accent;
  const _EmptyChart({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: context.borderColor),
      ),
      child: Center(
        child: Text(
          'No data yet — start tracking!',
          style: AppTypography.bodySmall.copyWith(color: context.textMuted),
        ),
      ),
    );
  }
}

class _EmptyAnalytics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Fix 5: friendly empty state — shown when habits exist but no completions yet
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined,
                color: context.textMuted, size: 48),
            const SizedBox(height: 12),
            Text('No data yet',
                style: AppTypography.titleMedium
                    .copyWith(color: context.textPrimary)),
            const SizedBox(height: 6),
            Text(
              'Complete habits to see your stats here.',
              style: AppTypography.bodySmall
                  .copyWith(color: context.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
