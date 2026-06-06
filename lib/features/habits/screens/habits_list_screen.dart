import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../common/widgets/empty_state.dart';
import '../../../common/widgets/section_header.dart';
import '../providers/habit_provider.dart';
import '../widgets/add_habit_sheet.dart';
import '../models/habit.dart';

class HabitsListScreen extends ConsumerWidget {
  const HabitsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(allHabitsProvider);

    return Scaffold(
      backgroundColor: StreakItTheme.black,
      appBar: AppBar(
        title: Text('HABITS', style: StreakItTheme.textTheme.headlineMedium),
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
              icon: Icons.grid_3x3,
              title: 'NO HABITS YET',
              subtitle: 'Create habits from the Today tab\nor tap + here.',
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

          final active = list.where((h) => h.isActive).toList();
          final inactive = list.where((h) => !h.isActive).toList();

          final items = <Widget>[];
          if (active.isNotEmpty) {
            items.add(const SectionHeader(title: 'ACTIVE'));
            items.addAll(active.map((h) => _HabitTile(habit: h)));
          }
          if (inactive.isNotEmpty) {
            items.add(const SectionHeader(title: 'PAUSED'));
            items.addAll(inactive.map((h) => _HabitTile(habit: h)));
          }

          return ListView(padding: const EdgeInsets.only(bottom: 100), children: items);
        },
      ),
    );
  }
}

class _HabitTile extends ConsumerWidget {
  final Habit habit;
  const _HabitTile({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(habit.habitId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: StreakItTheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await ref.read(habitActionsProvider).deleteHabit(habit);
        return true;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: StreakItTheme.deepCharcoal,
          border: Border.all(color: StreakItTheme.darkGray, width: 1),
        ),
        child: Row(
          children: [
            Text(habit.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit.name, style: StreakItTheme.textTheme.titleMedium),
                  Text('${habit.currentStreak}d · ${habit.totalCompletions} total',
                      style: StreakItTheme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: StreakItTheme.mutedGray, size: 20),
          ],
        ),
      ),
    );
  }
}