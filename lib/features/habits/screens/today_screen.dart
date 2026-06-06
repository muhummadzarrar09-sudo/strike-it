import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../common/widgets/empty_state.dart';
import '../widgets/habit_card.dart';
import '../widgets/add_habit_sheet.dart';
import '../providers/habit_provider.dart';
import '../../streaks/widgets/streak_header.dart';
import '../../streaks/widgets/heatmap_widget.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(todayHabitsProvider);
    final completedIds = ref.watch(completedHabitIdsProvider);

    return Scaffold(
      backgroundColor: StreakItTheme.black,
      appBar: AppBar(
        title: Text('TODAY', style: StreakItTheme.textTheme.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: StreakItTheme.accent),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AddHabitSheet(),
            ),
          ),
        ],
      ),
      body: habits.when(
        loading: () => const Center(child: CircularProgressIndicator(color: StreakItTheme.accent)),
        error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: StreakItTheme.error))),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.bolt,
              title: 'NO HABITS TODAY',
              subtitle: 'Tap + to create your first habit.\nThis screen shows what\'s scheduled for today.',
              action: ElevatedButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AddHabitSheet(),
                ),
                child: const Text('CREATE HABIT'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: list.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) return const StreakHeader();
              if (index == 1) return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: HeatmapWidget(),
              );
              final habit = list[index - 2];
              return HabitCard(
                habit: habit,
                isCompleted: completedIds.contains(habit.habitId),
              );
            },
          );
        },
      ),
    );
  }
}
