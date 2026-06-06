import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/streak_provider.dart';

class HeatmapWidget extends ConsumerWidget {
  const HeatmapWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(heatmapDataProvider);

    // Build last 20 weeks of data
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Start from Monday of 20 weeks ago
    final start = today.subtract(const Duration(days: 140));
    // Adjust to Monday
    final startMonday = start.subtract(Duration(days: start.weekday - 1));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StreakItTheme.charcoal,
        border: Border.all(color: StreakItTheme.darkGray, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ...List.generate(20, (week) {
                return Column(
                  children: List.generate(7, (day) {
                    final date = startMonday.add(Duration(days: week * 7 + day));
                    if (date.isAfter(today)) return const SizedBox(width: 10, height: 10);
                    final count = data[date] ?? 0;
                    final color = _colorForCount(count);
                    return Container(
                      width: 9,
                      height: 9,
                      margin: const EdgeInsets.all(1.5),
                      color: color,
                    );
                  }),
                );
              }),
              const SizedBox(width: 8),
              // Legend
              Column(
                children: [
                  _legendBox(StreakItTheme.heatmapColors[0], '0'),
                  _legendBox(StreakItTheme.heatmapColors[1], ''),
                  _legendBox(StreakItTheme.heatmapColors[2], ''),
                  _legendBox(StreakItTheme.heatmapColors[3], ''),
                  _legendBox(StreakItTheme.heatmapColors[4], '+'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'LAST 20 WEEKS',
            style: StreakItTheme.textTheme.bodySmall?.copyWith(color: StreakItTheme.mutedGray),
          ),
        ],
      ),
    );
  }

  Color _colorForCount(int count) {
    if (count == 0) return StreakItTheme.heatmapColors[0];
    if (count == 1) return StreakItTheme.heatmapColors[1];
    if (count == 2) return StreakItTheme.heatmapColors[2];
    if (count == 3) return StreakItTheme.heatmapColors[3];
    return StreakItTheme.heatmapColors[4];
  }

  Widget _legendBox(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, color: color),
          if (label.isNotEmpty) ...[const SizedBox(width: 2), Text(label, style: TextStyle(fontSize: 7, color: StreakItTheme.mutedGray, fontWeight: FontWeight.w600))],
        ],
      ),
    );
  }
}
