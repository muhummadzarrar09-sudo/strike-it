import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../presentation/screens/achievements/achievements_screen.dart';
import '../../presentation/screens/add_edit_habit/add_edit_habit_screen.dart';
import '../../presentation/screens/analytics/analytics_screen.dart';
import '../../presentation/screens/habit_detail/habit_detail_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';

// ── Route paths ────────────────────────────────────────────────────────────

abstract final class Routes {
  static const splash       = '/';
  static const onboarding   = '/onboarding';
  static const home         = '/home';
  static const habitDetail  = '/home/habit/:id';
  static const addHabit     = '/home/add-habit';
  static const editHabit    = '/home/edit-habit/:id';
  static const analytics    = '/analytics';
  static const achievements = '/achievements';
  static const settings     = '/settings';

  static String habitDetailPath(String id) => '/home/habit/$id';
  static String editHabitPath(String id)   => '/home/edit-habit/$id';
}

// ── Router provider ────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: false,
    routes: [
      // ── Top-level routes (outside shell) ──────────────────────────────
      GoRoute(
        path: Routes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),

      // ── Shell: 4 persistent tabs with independent navigator stacks ─────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          // Branch 0 — Today
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (_, __) => const TodayScreen(),
                routes: [
                  GoRoute(
                    path: 'habit/:id',
                    builder: (_, state) =>
                        HabitDetailScreen(habitId: state.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: 'add-habit',
                    builder: (_, __) => const AddEditHabitScreen(),
                  ),
                  GoRoute(
                    path: 'edit-habit/:id',
                    builder: (_, state) =>
                        AddEditHabitScreen(editHabitId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),

          // Branch 1 — Analytics
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.analytics,
                builder: (_, __) => const AnalyticsScreen(),
              ),
            ],
          ),

          // Branch 2 — Achievements
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.achievements,
                builder: (_, __) => const AchievementsScreen(),
              ),
            ],
          ),

          // Branch 3 — Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (_, __) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
});

// ── Onboarding guard ───────────────────────────────────────────────────────

Future<String> resolveInitialRoute() async {
  final prefs = await SharedPreferences.getInstance();
  final done = prefs.getBool(AppConstants.prefOnboardingDone) ?? false;
  return done ? Routes.home : Routes.onboarding;
}
