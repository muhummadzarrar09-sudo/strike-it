import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/habit_repository.dart';
import '../../providers/database_providers.dart';
import '../../../domain/notification_service.dart';

/// Onboarding — simple, human, no AI smell.
///
/// User feedback: "D intro is 🤢🤢 — use no fancy things, just classic"
///
/// 3 steps, no swiping, no gradient pages, no marketing copy:
///   Step 0 → What's your name? (optional)
///   Step 1 → What habit do you want to build?
///   Step 2 → When should we remind you? (optional)
///
/// Design rules applied:
///   - Dark/light background only. No gradients.
///   - Left-aligned text throughout.
///   - One action per step.
///   - Back always available (except step 0).
///   - Skip option on every step.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  static const _totalSteps = 3;

  // User inputs
  final _nameCtrl  = TextEditingController();
  final _habitCtrl = TextEditingController();
  TimeOfDay? _reminderTime;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _habitCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingDone, true);
    await prefs.setString(
      AppConstants.prefFirstLaunchDate,
      DateTime.now().toIso8601String(),
    );

    // Persist name for personalised greeting (Bug #4 fix)
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty) {
      await prefs.setString('user_name', name);
    }

    // Save the first habit to the database (Bug #1 fix — it was discarded)
    final habitName = _habitCtrl.text.trim();
    if (habitName.isNotEmpty && mounted) {
      try {
        final repo = ref.read(habitRepositoryProvider);
        final reminderStr = _reminderTime != null
            ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
            : '';

        final habitId = await repo.createHabit(
          name: habitName,
          colorHex: '#F59E0B', // brand amber — default for first habit
          iconId: 'star',
          kind: 'binary',
          frequencyType: 'daily',
          graceDays: 0,
          reminderTimes: reminderStr.isNotEmpty ? [reminderStr] : [],
          sortOrder: 0,
        );

        // Schedule the reminder if one was set (Bug #5 fix — was discarded)
        if (reminderStr.isNotEmpty && mounted) {
          final habits = await repo.getAllActive();
          await ref.read(notificationServiceProvider).rescheduleAll(habits);
        }
      } catch (_) {
        // Non-fatal — user can add habits manually
      }
    }

    if (!mounted) return;
    // Fix 1: prompt for notification permission at natural end of onboarding
    await ref.read(notificationServiceProvider).requestPermission();
    if (!mounted) return;
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No app bar — we handle back manually
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Step indicator (minimal dots) ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  if (_step > 0)
                    GestureDetector(
                      onTap: _back,
                      child: Icon(
                        Icons.arrow_back,
                        color: context.textMuted,
                        size: 20,
                      ),
                    )
                  else
                    const SizedBox(width: 20),
                  const Spacer(),
                  // Step dots
                  Row(
                    children: List.generate(_totalSteps, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(left: 6),
                        width: i == _step ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _step
                              ? context.cs.primary
                              : context.borderColor,
                          borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  // Skip
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Skip',
                      style: AppTypography.labelMedium.copyWith(
                        color: context.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Step content ─────────────────────────────────────────────
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _buildStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _StepName(
          ctrl: _nameCtrl,
          onNext: _next,
        );
      case 1: return _StepHabit(
          ctrl: _habitCtrl,
          onNext: _next,
        );
      case 2: return _StepReminder(
          selected: _reminderTime,
          onTimeSelected: (t) => setState(() => _reminderTime = t),
          onFinish: _finish,
        );
      default: return const SizedBox.shrink();
    }
  }
}

// ── Step 0: Name ───────────────────────────────────────────────────────────

class _StepName extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onNext;

  const _StepName({required this.ctrl, required this.onNext});

  @override
  Widget build(BuildContext context) {
    // Fix 4: vertically centered content, no dead space at top
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "What's your name?",
                    style: AppTypography.headlineLarge.copyWith(
                      color: context.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We'll use it in your daily greeting. Optional.",
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    style: AppTypography.titleLarge.copyWith(
                      color: context.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Your name',
                      hintStyle: AppTypography.titleLarge.copyWith(
                        color: context.textMuted,
                      ),
                    ),
                    onSubmitted: (_) => onNext(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _NextButton(label: 'Continue', onTap: onNext),
        ],
      ),
    );
  }
}

// ── Step 1: First habit ────────────────────────────────────────────────────

class _StepHabit extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onNext;

  const _StepHabit({required this.ctrl, required this.onNext});

  @override
  Widget build(BuildContext context) {
    // Fix 4: vertically centered content
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What habit do you want to build?',
                    style: AppTypography.headlineLarge.copyWith(
                      color: context.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start with one. You can add more later.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppTypography.titleLarge.copyWith(
                      color: context.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Read 20 pages, Morning run…',
                      hintStyle: AppTypography.bodyLarge.copyWith(
                        color: context.textMuted,
                      ),
                    ),
                    onSubmitted: (_) => onNext(),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'Read 20 pages', 'Morning walk', 'Drink water',
                      'Meditate', 'No social media', 'Exercise',
                    ].map((s) => _SuggestionChip(
                      label: s,
                      onTap: () => ctrl.value = TextEditingValue(
                        text: s,
                        selection: TextSelection.collapsed(offset: s.length),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _NextButton(label: 'Continue', onTap: onNext),
        ],
      ),
    );
  }
}

// ── Step 2: Reminder ───────────────────────────────────────────────────────

class _StepReminder extends StatelessWidget {
  final TimeOfDay? selected;
  final ValueChanged<TimeOfDay?> onTimeSelected;
  final VoidCallback onFinish;

  const _StepReminder({
    required this.selected,
    required this.onTimeSelected,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    // Fix 4: vertically centered, no dead space
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'When should we remind you?',
                    style: AppTypography.headlineLarge.copyWith(
                      color: context.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A daily nudge keeps the streak alive.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.textMuted,
                    ),
                  ),
                  const SizedBox(height: 32),

          // Time picker button
          GestureDetector(
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: selected ?? const TimeOfDay(hour: 8, minute: 0),
              );
              if (t != null) onTimeSelected(t);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(
                  color: selected != null
                      ? context.cs.primary
                      : context.borderColor,
                  width: selected != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: selected != null
                        ? context.cs.primary
                        : context.textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Text(
                    selected != null
                        ? selected!.format(context)
                        : 'Choose a time',
                    style: AppTypography.titleMedium.copyWith(
                      color: selected != null
                          ? context.textPrimary
                          : context.textMuted,
                    ),
                  ),
                  if (selected != null) ...[
                    const Spacer(),
                    GestureDetector(
                      onTap: () => onTimeSelected(null),
                      child: Icon(
                        Icons.close,
                        color: context.textMuted,
                        size: 18,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _NextButton(label: "Let's go", onTap: onFinish),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () { onTimeSelected(null); onFinish(); },
              child: Text(
                'Skip reminders',
                style: AppTypography.labelMedium.copyWith(color: context.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────

class _NextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NextButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
          border: Border.all(color: context.borderColor),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: context.textSecondary,
          ),
        ),
      ),
    );
  }
}
