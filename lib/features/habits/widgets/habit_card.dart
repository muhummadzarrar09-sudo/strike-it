import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../streaks/providers/streak_provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';

class HabitCard extends ConsumerWidget {
  final Habit habit;
  final bool isCompleted;
  const HabitCard({super.key, required this.habit, required this.isCompleted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(habitStreakProvider(habit.habitId)).valueOrNull ?? 0;

    return GestureDetector(
      onTap: () => ref.read(habitActionsProvider).toggleHabitCheckin(habit),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isCompleted ? StreakItTheme.accent.withAlpha(20) : StreakItTheme.deepCharcoal,
          border: Border.all(
            color: isCompleted ? StreakItTheme.accent : StreakItTheme.darkGray,
            width: isCompleted ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted ? StreakItTheme.accent : Colors.transparent,
                border: Border.all(color: isCompleted ? StreakItTheme.accent : StreakItTheme.midGray, width: 2),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(width: 14),
            // Emoji + Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(habit.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          habit.name,
                          style: StreakItTheme.textTheme.titleMedium?.copyWith(
                            color: isCompleted ? StreakItTheme.nearWhite : StreakItTheme.offWhite,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            decorationColor: StreakItTheme.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (habit.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(habit.description, style: StreakItTheme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            // Streak badge
            if (streak > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: streak >= 7 ? StreakItTheme.accent.withAlpha(30) : Colors.transparent,
                  border: Border.all(color: streak >= 7 ? StreakItTheme.accent : StreakItTheme.darkGray, width: 1),
                ),
                child: Text(
                  '$streak 🔥',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: streak >= 7 ? StreakItTheme.accent : StreakItTheme.mutedGray,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}