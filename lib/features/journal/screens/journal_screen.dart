import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/isar_service.dart';
import '../../../common/widgets/empty_state.dart';
import '../models/journal_entry.dart';

const _uuid = Uuid();

final journalEntriesProvider = StreamProvider<List<JournalEntry>>((ref) {
  return IsarService.journal.where().sortByDateDesc().watch();
});

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  Future<void> _addEntry() async {
    final now = DateTime.now();
    final entry = JournalEntry()
      ..entryId = _uuid.v4()
      ..date = DateTime(now.year, now.month, now.day)
      ..createdAt = now
      ..updatedAt = now
      ..entryType = 'free'
      ..moodRating = 3
      ..energyRating = 3
      ..moodEmoji = '😐'
      ..tags = []
      ..isSynced = false;

    await IsarService.journal.put(entry);
  }

  void _showEntryEditor(JournalEntry? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JournalEditor(entry: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(journalEntriesProvider);

    return Scaffold(
      backgroundColor: StreakItTheme.black,
      appBar: AppBar(
        title: Text('JOURNAL', style: StreakItTheme.textTheme.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: StreakItTheme.accent),
            onPressed: _addEntry,
          ),
        ],
      ),
      body: entries.when(
        loading: () => const Center(child: CircularProgressIndicator(color: StreakItTheme.accent)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.edit_note,
              title: 'NO ENTRIES',
              subtitle: 'Journal alongside your habits.\nReflect on what\'s working.',
              action: ElevatedButton(onPressed: _addEntry, child: const Text('FIRST ENTRY')),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final entry = list[i];
              return GestureDetector(
                onTap: () => _showEntryEditor(entry),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: StreakItTheme.deepCharcoal,
                    border: Border.all(color: StreakItTheme.darkGray, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(entry.moodEmoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                            style: StreakItTheme.textTheme.bodySmall,
                          ),
                          const Spacer(),
                          _ratingDots(entry.moodRating, 'Mood'),
                          const SizedBox(width: 8),
                          _ratingDots(entry.energyRating, 'Energy'),
                        ],
                      ),
                      if (entry.freeText != null && entry.freeText!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(entry.freeText!, style: StreakItTheme.textTheme.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
                      ],
                      if (entry.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: entry.tags.map((t) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: StreakItTheme.darkGray, width: 1),
                            ),
                            child: Text('#$t', style: TextStyle(fontSize: 10, color: StreakItTheme.mutedGray, fontWeight: FontWeight.w600)),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _ratingDots(int rating, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => Container(
        width: 6,
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        color: i < rating ? StreakItTheme.accent : StreakItTheme.darkGray,
      )),
    );
  }
}

class _JournalEditor extends ConsumerStatefulWidget {
  final JournalEntry? entry;
  const _JournalEditor({this.entry});

  @override
  ConsumerState<_JournalEditor> createState() => _JournalEditorState();
}

class _JournalEditorState extends ConsumerState<_JournalEditor> {
  late final TextEditingController _textCtrl;
  late int _mood;
  late int _energy;
  static const _moods = [
    ('😤', 'Terrible'), ('😞', 'Bad'), ('😐', 'Okay'), ('😊', 'Good'), ('🔥', 'Amazing')
  ];
  static const _energies = [
    ('🔋0', ''), ('🔋1', ''), ('🔋2', ''), ('🔋3', ''), ('⚡', '')
  ];

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.entry?.freeText ?? '');
    _mood = widget.entry?.moodRating ?? 3;
    _energy = widget.entry?.energyRating ?? 3;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final entry = widget.entry;
    if (entry != null) {
      entry.freeText = _textCtrl.text.trim();
      entry.moodRating = _mood;
      entry.energyRating = _energy;
      entry.moodEmoji = _moods[_mood - 1].$1;
      entry.updatedAt = DateTime.now();
      await IsarService.journal.put(entry);
    }
    if (mounted) Navigator.pop(context);
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
            Text('JOURNAL ENTRY', style: StreakItTheme.textTheme.headlineSmall),
            const SizedBox(height: 16),

            // Mood
            Text('MOOD', style: StreakItTheme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) => GestureDetector(
                onTap: () => setState(() => _mood = i + 1),
                child: Container(
                  width: 48, height: 48, margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: _mood == i + 1 ? StreakItTheme.accent.withAlpha(25) : StreakItTheme.charcoal,
                    border: Border.all(color: _mood == i + 1 ? StreakItTheme.accent : StreakItTheme.darkGray, width: _mood == i + 1 ? 2 : 1),
                  ),
                  child: Center(child: Text(_moods[i].$1, style: const TextStyle(fontSize: 20))),
                ),
              )),
            ),
            const SizedBox(height: 16),

            // Energy
            Text('ENERGY', style: StreakItTheme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) => GestureDetector(
                onTap: () => setState(() => _energy = i + 1),
                child: Container(
                  width: 48, height: 4, margin: const EdgeInsets.only(right: 4),
                  color: _energy > i ? StreakItTheme.accent : StreakItTheme.darkGray,
                ),
              )),
            ),
            const SizedBox(height: 16),

            // Free text
            TextField(
              controller: _textCtrl,
              maxLines: 5,
              style: StreakItTheme.textTheme.bodyMedium,
              decoration: const InputDecoration(hintText: 'What\'s on your mind? How did today go?...'),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _save, child: const Text('SAVE')),
            ),
          ],
        ),
      ),
    );
  }
}
