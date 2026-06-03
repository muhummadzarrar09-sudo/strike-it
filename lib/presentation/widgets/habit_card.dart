import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/habit_icons.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/streak_calculator.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/completion_repository.dart';
import '../../domain/xp_service.dart';
import '../providers/database_providers.dart';
import '../providers/habit_providers.dart';
import 'celebration_overlay.dart';

class HabitCard extends ConsumerStatefulWidget {
  final Habit habit;
  final bool isCompleted;
  final Color accent;

  const HabitCard({
    super.key,
    required this.habit,
    required this.isCompleted,
    required this.accent,
  });

  @override
  ConsumerState<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<HabitCard>
    with TickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;
  // Animation 1: completion pulse — 1.0 → 1.035 → 1.0 in 180ms
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseScale;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeIn),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.035).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // FIX #1 — quantified habits call incrementCount, binary call toggleCompletion
  Future<void> _onCheckTap() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    await HapticFeedback.selectionClick();
    await _pressCtrl.forward();
    await _pressCtrl.reverse();

    try {
      final repo = ref.read(completionRepositoryProvider);
      final today = StreakDateUtils.today();
      bool nowCompleted;

      if (widget.habit.kind == 'quantified') {
        // Increment count; considered "done" when count >= targetCount
        final newCount = await repo.incrementCount(widget.habit.id, today);
        nowCompleted = newCount >= widget.habit.targetCount;
      } else {
        nowCompleted = await repo.toggleCompletion(widget.habit.id, today);
      }

      // Trigger completion pulse — only on complete, NEVER on uncomplete
      if (nowCompleted && mounted) {
        _pulseCtrl.forward().then((_) {
          if (mounted) _pulseCtrl.reverse();
        });
        await _handleCompletion();
      }
    } catch (_) {
      if (mounted) context.showSnack('Could not update habit.', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleCompletion() async {
    final dates = await ref
        .read(completionRepositoryProvider)
        .getCompletedDates(widget.habit.id);
    final targetDays = widget.habit.targetDays.isEmpty
        ? <int>[]
        : widget.habit.targetDays.split(',').map(int.parse).toList();
    final streak = StreakCalculator.calculate(
      completedDates: dates,
      startDate: DateTime.parse(widget.habit.createdAt),
      graceDays: widget.habit.graceDays,
      targetDays: targetDays,
    );
    final award =
        await ref.read(xpServiceProvider).awardForCompletion(streak.currentStreak);

    if (!mounted) return;
    if (award.hasMilestone) {
      await ref.read(notificationServiceProvider).showMilestoneCelebration(
            habitName: widget.habit.name,
            milestone: award.milestone!,
          );
    }
    if (award.leveledUp) {
      await ref.read(notificationServiceProvider).showLevelUp(award.newLevel);
    }
    if (award.hasMilestone || award.leveledUp) {
      await CelebrationOverlay.show(context, award: award, habitName: widget.habit.name);
    }
  }

  // PATCH D — decrement on long-press
  Future<void> _onDecrementTap() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    await HapticFeedback.lightImpact();
    try {
      final repo = ref.read(completionRepositoryProvider);
      await repo.decrementCount(widget.habit.id, StreakDateUtils.today());
    } catch (_) {
      if (mounted) context.showSnack('Could not decrement.', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitColor = widget.habit.colorHex.toColor();
    final icon = HabitIcons.fromId(widget.habit.iconId);
    final streakAsync = ref.watch(habitStreakProvider(widget.habit.id));

    final isQuantified = widget.habit.kind == 'quantified';

    // FIX 3 — use today-only stream (already filtered), no full history load
    final completionsAsync = ref.watch(todayCompletionsProvider);
    final todayCount = completionsAsync.when(
      data: (comps) => comps
          .where((c) => c.habitId == widget.habit.id)
          .fold(0, (sum, c) => sum + c.count),
      loading: () => 0,
      error: (_, __) => 0,
    );

    // Animation 1: pulse wraps OUTSIDE the press-scale so they compose
    return ScaleTransition(
      scale: _pulseScale,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
        onTap: () => context.push(Routes.habitDetailPath(widget.habit.id)),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          // Step 3: cardDecoration with color override for completion state
          decoration: AppTheme.cardDecoration.copyWith(
            color: widget.isCompleted
                ? AppColors.successFill
                : AppTheme.cardDecoration.color,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,  // 16 (was 14 — on-grid)
              vertical: AppSpacing.sm + 4, // 12 (on 4px grid)
            ),
            child: Row(
              children: [
                _IconBadge(
                  habit: widget.habit,
                  color: habitColor,
                  isCompleted: widget.isCompleted,
                  icon: icon,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fix 1: green dot instead of strikethrough
                      Row(
                        children: [
                          if (widget.isCompleted) ...[
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 7),
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                          Expanded(
                            child: Text(
                              widget.habit.name,
                              style: AppTypography.titleMedium.copyWith(
                                color: widget.isCompleted
                                    ? context.textSecondary
                                    : context.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      streakAsync.when(
                        data: (s) => _StreakLine(
                          streak: s,
                          habitColor: habitColor,
                          isNegative: widget.habit.isNegative,
                        ),
                        loading: () => const SizedBox(height: 16),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Quantified habits show a counter button instead of check
                isQuantified
                    ? _CountButton(
                        targetCount: widget.habit.targetCount,
                        currentCount: todayCount,
                        isCompleted: widget.isCompleted,
                        isProcessing: _isProcessing,
                        color: habitColor,
                        onTap: _onCheckTap,
                        onLongPress: _onDecrementTap,
                      )
                    : _CheckButton(
                        isCompleted: widget.isCompleted,
                        isProcessing: _isProcessing,
                        color: habitColor,
                        onTap: _onCheckTap,
                      ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

}

// ── Icon badge ─────────────────────────────────────────────────────────────

class _IconBadge extends StatelessWidget {
  final Habit habit;
  final Color color;
  final bool isCompleted;
  final HabitIconEntry icon;

  const _IconBadge({
    required this.habit,
    required this.color,
    required this.isCompleted,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isCompleted ? color.withValues(alpha: 0.20) : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radius8),
      ),
      child: Center(
        child: habit.emoji != null
            ? Text(habit.emoji!, style: const TextStyle(fontSize: 20))
            : Icon(icon.icon, color: color, size: 20),
      ),
    );
  }
}

// ── Streak sub-line ────────────────────────────────────────────────────────

class _StreakLine extends StatelessWidget {
  final StreakResult streak;
  final Color habitColor;
  final bool isNegative;

  const _StreakLine({
    required this.streak,
    required this.habitColor,
    required this.isNegative,
  });

  @override
  Widget build(BuildContext context) {
    if (streak.currentStreak == 0) {
      return Text(
        isNegative ? 'Stay strong' : 'Start today',
        style: AppTypography.bodySmall.copyWith(color: context.textMuted),
      );
    }
    final color = streak.isAtRisk ? AppColors.warning : habitColor;
    return Row(
      children: [
        Icon(Icons.local_fire_department, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          '${streak.currentStreak} day streak',
          style: AppTypography.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (streak.isAtRisk) ...[
          const SizedBox(width: 4),
          Text('⚠️', style: AppTypography.caption),
        ],
        if (streak.nextMilestone != null && !streak.isAtRisk) ...[
          const SizedBox(width: 6),
          Text(
            '→ ${streak.nextMilestone}d',
            style: AppTypography.caption.copyWith(color: context.textMuted),
          ),
        ],
      ],
    );
  }
}

// ── Check button (binary habits) ───────────────────────────────────────────

class _CheckButton extends StatelessWidget {
  final bool isCompleted;
  final bool isProcessing;
  final Color color;
  final VoidCallback onTap;

  const _CheckButton({
    required this.isCompleted,
    required this.isProcessing,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          // Step 5: green = done, amber = tap-me (semantically distinct)
          color: isCompleted
              ? AppColors.success
              : AppColors.brand,
          shape: BoxShape.circle,
        ),
        child: isProcessing
            ? Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Colors.white,
                  ),
                ),
              )
            : isCompleted
                // Step 5: completed = green checkmark (done state)
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                    .animate()
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      duration: 180.ms,
                      curve: Curves.easeOutBack,
                    )
                // Step 5: incomplete = amber + icon (active/streak state)
                : Icon(Icons.add, color: Colors.white.withValues(alpha: 0.85), size: 16),
      ),
    );
  }
}

// ── Count button (quantified habits) ──────────────────────────────────────

class _CountButton extends StatelessWidget {
  final int targetCount;
  final int currentCount;       // PATCH D — shows progress
  final bool isCompleted;
  final bool isProcessing;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress; // PATCH D — decrement

  const _CountButton({
    required this.targetCount,
    required this.currentCount,
    required this.isCompleted,
    required this.isProcessing,
    required this.color,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // PATCH D — label shows "2/5" progress or "✓" when done
    final label = isCompleted ? '✓' : '$currentCount/$targetCount';
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress, // PATCH D — long-press to decrement
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 36,
        decoration: BoxDecoration(
          color: isCompleted ? color : color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppTheme.radius8),
        ),
        child: isProcessing
            ? Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: isCompleted ? Colors.white : color,
                  ),
                ),
              )
            : Center(
                child: Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: isCompleted ? Colors.white : color,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
      ),
    );
  }
}
