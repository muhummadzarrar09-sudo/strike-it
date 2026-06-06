import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/streak_provider.dart';

class StreakHeader extends ConsumerWidget {
  const StreakHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(overallStreakProvider);
    final longest = ref.watch(overallLongestStreakProvider);
    final rate = ref.watch(overallCompletionRateProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StreakItTheme.deepCharcoal,
        border: Border.all(color: StreakItTheme.darkGray, width: 1),
      ),
      child: Row(
        children: [
          // Streak count (hero number)
          Text(
            '$streak',
            style: StreakItTheme.textTheme.displayLarge?.copyWith(
              color: streak > 0 ? StreakItTheme.accent : StreakItTheme.mutedGray,
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text('DAY\nSTREAK', style: StreakItTheme.textTheme.labelSmall),
          ),
          const Spacer(),
          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('LONGEST: $longest', style: StreakItTheme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Text('${(rate * 100).toInt()}% THIS YEAR', style: StreakItTheme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
