import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/extensions.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/tasks_dao.dart';
import '../providers/database_providers.dart';

/// Reactive sub-task checklist for a habit.
///
/// Features:
///   - Add tasks inline via text field
///   - Tap to toggle completion for today
///   - Long-press to delete
///   - Completion state persisted per-day in SQLite
///   - Animated entrance/exit for tasks
class TaskChecklist extends ConsumerStatefulWidget {
  final String habitId;
  final Color accentColor;

  const TaskChecklist({
    super.key,
    required this.habitId,
    required this.accentColor,
  });

  @override
  ConsumerState<TaskChecklist> createState() => _TaskChecklistState();
}

class _TaskChecklistState extends ConsumerState<TaskChecklist> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isAddingTask = false;
  final _uuid = const Uuid();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _addTask(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;

    final db = ref.read(databaseProvider);

    // Get current count for sort order.
    final existing = await db.tasksDao.getForHabit(widget.habitId);

    await db.tasksDao.insertTask(
      HabitTasksCompanion(
        id: Value(_uuid.v4()),
        habitId: Value(widget.habitId),
        title: Value(trimmed),
        sortOrder: Value(existing.length),
        completedDates: const Value(''),
      ),
    );

    _controller.clear();
  }

  Future<void> _toggleTask(HabitTask task) async {
    await HapticFeedback.selectionClick();
    final db = ref.read(databaseProvider);
    await db.tasksDao.toggleTaskForDate(task.id, StreakDateUtils.today());
  }

  Future<void> _deleteTask(HabitTask task) async {
    final db = ref.read(databaseProvider);
    await db.tasksDao.deleteTask(task.id);
    if (mounted) context.showSnack('Task removed.');
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final today = StreakDateUtils.today();

    return StreamBuilder<List<HabitTask>>(
      stream: db.tasksDao.watchForHabit(widget.habitId),
      builder: (context, snap) {
        final tasks = snap.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────
            Row(
              children: [
                Text(
                  'Sub-tasks',
                  style: AppTypography.titleSmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                if (tasks.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
                    ),
                    child: Text(
                      '${tasks.where((t) => TasksDao.isTaskCompletedOn(t, today)).length}/${tasks.length}',
                      style: AppTypography.caption.copyWith(
                        color: widget.accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() => _isAddingTask = true);
                    Future.delayed(
                      const Duration(milliseconds: 80),
                      () => _focusNode.requestFocus(),
                    );
                  },
                  child: Icon(
                    Icons.add,
                    color: widget.accentColor,
                    size: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Task list ───────────────────────────────────────────────
            if (tasks.isEmpty && !_isAddingTask)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'No sub-tasks yet. Tap + to add steps.',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.textMuted,
                  ),
                ),
              ),

            ...tasks.asMap().entries.map((entry) {
              final task = entry.value;
              final done = TasksDao.isTaskCompletedOn(task, today);

              return _TaskRow(
                key: ValueKey(task.id),
                task: task,
                isDone: done,
                accentColor: widget.accentColor,
                onToggle: () => _toggleTask(task),
                onDelete: () => _deleteTask(task),
                index: entry.key,
              );
            }),

            // ── Add task input ──────────────────────────────────────────
            if (_isAddingTask)
              Container(
                margin: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.borderColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: AppTypography.bodyMedium.copyWith(
                          color: context.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add a step...',
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: context.textMuted,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (v) async {
                          await _addTask(v);
                          setState(() => _isAddingTask = false);
                        },
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await _addTask(_controller.text);
                        setState(() => _isAddingTask = false);
                      },
                      child: Icon(
                        Icons.check,
                        color: widget.accentColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        _controller.clear();
                        setState(() => _isAddingTask = false);
                      },
                      child: Icon(
                        Icons.close,
                        color: context.textMuted,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ).animate().fade(duration: 200.ms),
          ],
        );
      },
    );
  }
}

class _TaskRow extends StatelessWidget {
  final HabitTask task;
  final bool isDone;
  final Color accentColor;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final int index;

  const _TaskRow({
    super.key,
    required this.task,
    required this.isDone,
    required this.accentColor,
    required this.onToggle,
    required this.onDelete,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _confirmDelete(context),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            // Circle check
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isDone ? accentColor : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone ? accentColor : context.borderColor,
                    width: 1.5,
                  ),
                ),
                child: isDone
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 13,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.title,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDone ? context.textMuted : context.textPrimary,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  decorationColor: context.textMuted,
                ),
              ),
            ),
          ],
        ),
      )
          .animate(delay: (index * 40).ms)
          .slideX(begin: -0.05, duration: 300.ms, curve: Curves.easeOut)
          .fade(duration: 250.ms),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('"${task.title}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: TextButton.styleFrom(
                foregroundColor: AppColors.destructive),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
