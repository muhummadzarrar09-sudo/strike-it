import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/habit_provider.dart';

final _emojiOptions = ['💪', '📖', '🏃', '🧘', '💧', '🥗', '✍️', '🎯', '🌱', '🧠', '🎨', '💤', '🚫', '💰', '🤝', '🍽️'];
final _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

class AddHabitSheet extends ConsumerStatefulWidget {
  const AddHabitSheet({super.key});

  @override
  ConsumerState<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends ConsumerState<AddHabitSheet> {
  final _nameCtrl = TextEditingController();
  String _selectedEmoji = '💪';
  final _selectedDays = <int>{}; // 0=Mon..6=Sun
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _selectedDays.isEmpty) return;
    setState(() => _saving = true);
    await ref.read(habitActionsProvider).createHabit(
      name: name,
      emoji: _selectedEmoji,
      activeDays: _selectedDays.toList()..sort(),
      description: '',
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: StreakItTheme.nearBlack,
        border: Border(top: BorderSide(color: StreakItTheme.darkGray, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text('NEW HABIT', style: StreakItTheme.textTheme.headlineSmall),
            const SizedBox(height: 20),

            // Name
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              style: StreakItTheme.textTheme.titleMedium,
              decoration: const InputDecoration(hintText: 'Habit name...'),
            ),
            const SizedBox(height: 20),

            // Emoji picker
            Text('ICON', style: StreakItTheme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _emojiOptions.map((e) {
                final selected = e == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = e),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: selected ? StreakItTheme.accent.withAlpha(25) : StreakItTheme.charcoal,
                      border: Border.all(color: selected ? StreakItTheme.accent : StreakItTheme.darkGray, width: selected ? 2 : 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 20)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Day selector
            Row(
              children: [
                Text('DAYS', style: StreakItTheme.textTheme.labelMedium),
                const Spacer(),
                if (_selectedDays.length == 7)
                  GestureDetector(
                    onTap: () => setState(() => _selectedDays.clear()),
                    child: Text('Clear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: StreakItTheme.accent)),
                  )
                else
                  GestureDetector(
                    onTap: () => setState(() => _selectedDays.addAll([0, 1, 2, 3, 4, 5, 6])),
                    child: Text('Every day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: StreakItTheme.accent)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(7, (i) {
                final selected = _selectedDays.contains(i);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleDay(i),
                    child: Container(
                      height: 36,
                      margin: EdgeInsets.only(right: i < 6 ? 4 : 0),
                      decoration: BoxDecoration(
                        color: selected ? StreakItTheme.accent : StreakItTheme.charcoal,
                        border: Border.all(color: selected ? StreakItTheme.accent : StreakItTheme.darkGray, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _dayLabels[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : StreakItTheme.mutedGray,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('CREATE HABIT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
