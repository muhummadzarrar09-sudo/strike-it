import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/streak_calculator.dart';
import '../../../data/database/app_database.dart';
import '../../providers/habit_providers.dart';
import '../../widgets/animated_flame.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/habit_card.dart';
import '../../widgets/progress_ring.dart';

// ── ARCH #1 — Shell scaffold (holds NavigationBar + branch body) ───────────
// This is what StatefulShellRoute renders. Each tab preserves its own state.

class AppShell extends ConsumerWidget {
  final StatefulNavigationShell shell;
  const AppShell({super.key, required this.shell});

  static const _navItems = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Today',
    ),
    NavigationDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart),
      label: 'Analytics',
    ),
    NavigationDestination(
      icon: Icon(Icons.emoji_events_outlined),
      selectedIcon: Icon(Icons.emoji_events),
      label: 'Achievements',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: shell,
      // FIX 1: only show FAB on Today root — not on sub-routes (detail/add/edit)
      floatingActionButton: shell.currentIndex == 0 &&
              GoRouterState.of(context).matchedLocation == '/home'
          ? _HomeFAB()
          : null,
      // Step 4: refined nav — amber pill, 64px, top separator, zero elevation
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Color(0x14FFFFFF), // 8% white top separator
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          height: 64,
          elevation: 0,
          backgroundColor: const Color(0xFF0D0C11),
          indicatorColor: Color(0xFFE8952A).withValues(alpha: 0.15),
          indicatorShape: const StadiumBorder(),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (index) => shell.goBranch(
            index,
            // go_router 17: renamed from initialLocation
            initialLocationIfNeeded: index == shell.currentIndex,
          ),
          destinations: _navItems,
        ),
      ),
    );
  }
}

// ── Today screen (branch 0 body) ───────────────────────────────────────────

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync   = ref.watch(habitsStreamProvider);
    final todayAsync    = ref.watch(todayCompletionsProvider);
    final progressAsync = ref.watch(todayProgressProvider);
    final accent        = ref.watch(themeProvider).accent.primary;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _Greeting(accent: accent)),

        // Streak hero — first thing the eye goes to
        SliverToBoxAdapter(
          child: habitsAsync.when(
            data: (habits) => _StreakHero(habits: habits, accent: accent),
            loading: () => const _StreakHeroSkeleton(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),

        // Progress bar
        SliverToBoxAdapter(
          child: progressAsync.when(
            data: (p) => _ProgressBar(done: p.$1, total: p.$2, accent: accent),
            loading: () => const SizedBox(height: 72),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),

        // Section label
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 28, AppSpacing.lg, AppSpacing.sm + 2),
            child: Row(
              children: [
                // Step 2: sectionLabel style — uppercase applied to string
                Text(
                  'HABITS',
                  style: AppTypography.sectionLabel.copyWith(
                    color: context.textMuted,
                  ),
                ),
                const Spacer(),
                habitsAsync.when(
                  data: (h) => Text(
                    '${h.length} habit${h.length == 1 ? '' : 's'}',
                    style: AppTypography.sectionLabel.copyWith(
                      color: context.textMuted,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),

        // Habit cards
        habitsAsync.when(
          data: (habits) {
            if (habits.isEmpty) {
              return SliverToBoxAdapter(child: _EmptyState(accent: accent));
            }
            return todayAsync.when(
              data: (completions) {
                // Build countMap: for quantified habits count matters
                final countMap = <String, int>{};
                for (final c in completions) {
                  countMap[c.habitId] = (countMap[c.habitId] ?? 0) + c.count;
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.builder(
                    itemCount: habits.length,
                    itemBuilder: (ctx, i) {
                      final habit = habits[i];
                      final isCompleted = habit.kind == 'quantified'
                          ? (countMap[habit.id] ?? 0) >= habit.targetCount
                          : countMap.containsKey(habit.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: HabitCard(
                          habit: habit,
                          isCompleted: isCompleted,
                          accent: accent,
                        )
                            .animate(delay: (i * 55).ms)
                            .slideY(begin: 0.12, duration: 350.ms, curve: Curves.easeOut)
                            .fade(duration: 300.ms),
                      );
                    },
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) =>
                  SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
            );
          },
          loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator())),
          error: (e, _) =>
              SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// Keep old HomeScreen name as alias so any remaining references compile
typedef HomeScreen = TodayScreen;

// ── Greeting ───────────────────────────────────────────────────────────────

class _Greeting extends StatefulWidget {
  final Color accent;
  const _Greeting({required this.accent});
  @override
  State<_Greeting> createState() => _GreetingState();
}

class _GreetingState extends State<_Greeting>
    with WidgetsBindingObserver {
  String _userName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadName();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // PATCH E — re-read name on resume so Settings changes propagate
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    if (mounted && name.isNotEmpty) setState(() => _userName = name);
  }

  String get _greeting {
    final h = DateTime.now().hour;
    final base = h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';
    return _userName.isNotEmpty ? '$base, $_userName' : base;
  }

  String get _dateLabel {
    final now = DateTime.now();
    return '${StreakDateUtils.shortWeekday(now.weekday)}, '
        '${StreakDateUtils.shortMonth(now.month)} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dateLabel,
                  style: AppTypography.labelSmall.copyWith(
                    color: context.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _greeting,
                  style: AppTypography.headlineMedium.copyWith(
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // FIX 5b: animated flame — taps through to achievements
            GestureDetector(
              onTap: () => context.go('/achievements'),
              child: const AnimatedFlame(size: 32),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Streak hero ────────────────────────────────────────────────────────────

class _StreakHero extends ConsumerWidget {
  final List<Habit> habits;
  final Color accent;
  const _StreakHero({required this.habits, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (habits.isEmpty) return const SizedBox(height: 8);
    return _StreakHeroInner(habits: habits, accent: accent);
  }
}

class _StreakHeroInner extends ConsumerWidget {
  final List<Habit> habits;
  final Color accent;
  const _StreakHeroInner({required this.habits, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakWatchers =
        habits.map((h) => ref.watch(habitStreakProvider(h.id))).toList();

    // FIX #5 — skeleton until all loaded
    if (streakWatchers.any((s) => s.isLoading)) return const _StreakHeroSkeleton();

    int bestStreak = 0;
    bool anyAtRisk = false;
    // UI#7 — only flag at-risk if the SAME habit holding bestStreak is at risk
    for (int i = 0; i < streakWatchers.length; i++) {
      streakWatchers[i].whenData((sr) {
        if (sr.currentStreak > bestStreak) {
          bestStreak = sr.currentStreak;
          anyAtRisk = sr.isAtRisk; // reset to this habit's risk state
        }
      });
    }

    // Step 4: isAtRisk = red (danger), active = amber (brand). Never same color.
    final streakColor = anyAtRisk
        ? AppColors.destructive
        : bestStreak > 0
            ? accent
            : context.textMuted;

    // Fix 2: single cohesive amber card — no disconnected floating elements
    final subtitle = bestStreak == 0
        ? 'Start your first streak today'
        : bestStreak == 1
            ? '1 day — keep going!'
            : anyAtRisk
                ? '$bestStreak days — log today to keep it!'
                : '$bestStreak day streak';

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: anyAtRisk
              ? AppColors.destructive.withValues(alpha: 0.10)
              : AppColors.brandFill,
          borderRadius: BorderRadius.circular(AppTheme.radius16),
          border: Border.all(
            color: anyAtRisk
                ? AppColors.destructive.withValues(alpha: 0.3)
                : AppColors.brand.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Flame icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: anyAtRisk
                    ? AppColors.destructive.withValues(alpha: 0.15)
                    : AppColors.brand.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_fire_department,
                color: anyAtRisk ? AppColors.destructive : AppColors.brand,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            // Number + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$bestStreak',
                    style: AppTypography.statLarge.copyWith(
                      color: anyAtRisk ? AppColors.destructive : AppColors.brand,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: anyAtRisk
                          ? AppColors.destructive.withValues(alpha: 0.8)
                          : context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakHeroSkeleton extends StatelessWidget {
  const _StreakHeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: context.borderColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppTheme.radius16),
        ),
      ),
    );
  }
}

// ── Progress bar ────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int done;
  final int total;
  final Color accent;
  const _ProgressBar({required this.done, required this.total, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    final progress = done / total;
    final allDone = done == total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Row(
        children: [
          ProgressRing(
            progress: progress,
            size: 52,
            strokeWidth: 5,
            color: allDone ? AppColors.success : accent,
            backgroundColor: context.borderColor,
            child: Center(
              child: Text(
                '$done',
                style: AppTypography.statSmall
                    .copyWith(color: allDone ? AppColors.success : accent, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allDone ? 'Perfect day! 🎉' : '$done of $total habits done',
                  style: AppTypography.titleSmall.copyWith(
                    color: allDone ? AppColors.success : context.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: context.borderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      allDone ? AppColors.success : accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final Color accent;
  const _EmptyState({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xxl),
      child: Column(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('No habits yet',
              style: AppTypography.headlineSmall.copyWith(color: context.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first habit.\nStart with just one.',
            style: AppTypography.bodyMedium.copyWith(color: context.textMuted, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── FAB ─────────────────────────────────────────────────────────────────────

class _HomeFAB extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fix 3: round FAB — not a pill. Black icon on amber for contrast.
    return FloatingActionButton(
      onPressed: () => context.push(Routes.addHabit),
      backgroundColor: AppColors.brand,
      foregroundColor: Colors.black,
      elevation: 2,
      child: const Icon(Icons.add, color: Colors.black, size: 24),
    );
  }
}
