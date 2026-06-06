import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../common/widgets/empty_state.dart';
import '../../streaks/providers/streak_provider.dart';
import '../../habits/providers/habit_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(allHabitsProvider);
    final rate = ref.watch(overallCompletionRateProvider);
    final longest = ref.watch(overallLongestStreakProvider);
    final heatmapData = ref.watch(heatmapDataProvider);

    return Scaffold(
      backgroundColor: StreakItTheme.black,
      appBar: AppBar(
        title: Text('STATS', style: StreakItTheme.textTheme.headlineMedium),
      ),
      body: habits.when(
        loading: () => const Center(child: CircularProgressIndicator(color: StreakItTheme.accent)),
        error: (_, __) => const Center(child: Text('Error')),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.trending_up,
              title: 'NO DATA YET',
              subtitle: 'Start tracking habits to see\nyour analytics here.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // KPI Cards
              Row(
                children: [
                  _kpiCard('COMPLETION', '${(rate * 100).toInt()}%', StreakItTheme.accent),
                  const SizedBox(width: 12),
                  _kpiCard('LONGEST', '$longest', StreakItTheme.nearWhite),
                  const SizedBox(width: 12),
                  _kpiCard('HABITS', '${list.length}', StreakItTheme.offWhite),
                ],
              ),
              const SizedBox(height: 24),

              // Weekly bar chart
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: StreakItTheme.deepCharcoal,
                  border: Border.all(color: StreakItTheme.darkGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('THIS WEEK', style: StreakItTheme.textTheme.labelLarge),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 160,
                      child: _WeeklyBarChart(data: heatmapData),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Top habits
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: StreakItTheme.deepCharcoal,
                  border: Border.all(color: StreakItTheme.darkGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOP HABITS', style: StreakItTheme.textTheme.labelLarge),
                    const SizedBox(height: 12),
                    ...list.take(5).map((h) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(h.emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(h.name, style: StreakItTheme.textTheme.bodyMedium)),
                          Text('${h.currentStreak}d 🔥', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: StreakItTheme.accent)),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _kpiCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: StreakItTheme.deepCharcoal,
          border: Border.all(color: StreakItTheme.darkGray),
        ),
        child: Column(
          children: [
            Text(value, style: StreakItTheme.textTheme.headlineMedium?.copyWith(color: color)),
            const SizedBox(height: 4),
            Text(label, style: StreakItTheme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final Map<DateTime, int> data;
  const _WeeklyBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final spots = <BarChartGroupData>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final day = DateTime(date.year, date.month, date.day);
      final count = data[day]?.toDouble() ?? 0;
      spots.add(BarChartGroupData(
        x: 6 - i,
        barRods: [BarChartRodData(
          toY: count,
          color: count > 0 ? StreakItTheme.accent : StreakItTheme.darkGray,
          width: 20,
          borderRadius: BorderRadius.zero,
        )],
      ));
    }

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(dayLabels[v.toInt()], style: TextStyle(fontSize: 10, color: StreakItTheme.mutedGray, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: spots,
        minY: 0,
      ),
    );
  }
}
