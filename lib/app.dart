import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_typography.dart';
import 'core/utils/date_utils.dart';
import 'presentation/providers/habit_providers.dart';
import 'presentation/providers/theme_provider.dart';

class StreakItApp extends ConsumerStatefulWidget {
  const StreakItApp({super.key});

  @override
  ConsumerState<StreakItApp> createState() => _StreakItAppState();
}

class _StreakItAppState extends ConsumerState<StreakItApp>
    with WidgetsBindingObserver {
  bool _locked = false;

  // PATCH A — grace period tracking. null = app hasn't been backgrounded yet.
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLockOnColdStart();
    _requestNotifPermOnce(); // Fix 2: once-only prompt for existing users
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Cold-start lock: read live pref, lock if enabled.
  Future<void> _checkLockOnColdStart() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(AppConstants.prefBiometricEnabled) ?? false;
    if (enabled && mounted) setState(() => _locked = true);
  }

  // Fix 2: fires exactly once for users who completed onboarding before
  // this fix was applied. The boolean guard prevents repeat prompts.
  Future<void> _requestNotifPermOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final asked = prefs.getBool('notif_permission_asked') ?? false;
    if (!asked) {
      await prefs.setBool('notif_permission_asked', true);
      await ref.read(notificationServiceProvider).requestPermission();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // PATCH A — record when app goes to background
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
      return;
    }

    if (state != AppLifecycleState.resumed) return;

    // PATCH D (FIX #4) — midnight date refresh
    final currentDate = StreakDateUtils.toIsoDate(StreakDateUtils.today());
    final storedDate = ref.read(todayDateProvider);
    if (currentDate != storedDate) {
      ref.read(todayDateProvider.notifier).state = currentDate;
    }

    // PATCH A — only lock if:
    //   1. We recorded a background time
    //   2. App was backgrounded for > 30 seconds
    //   3. Biometric is enabled (read live from prefs, not cached field)
    final bg = _backgroundedAt;
    _backgroundedAt = null; // always reset

    if (bg == null) return;
    final elapsed = DateTime.now().difference(bg);
    if (elapsed.inSeconds < 30) return;

    // Read live value so Settings changes are reflected immediately (PATCH A)
    SharedPreferences.getInstance().then((prefs) {
      final enabled = prefs.getBool(AppConstants.prefBiometricEnabled) ?? false;
      if (enabled && mounted) setState(() => _locked = true);
    });
  }

  Future<void> _authenticate() async {
    try {
      final auth = LocalAuthentication();
      final granted = await auth.authenticate(
        localizedReason: 'Unlock Streak It',
        options: const AuthenticationOptions(biometricOnly: false),
      );
      if (granted && mounted) setState(() => _locked = false);
    } catch (_) {
      if (mounted) setState(() => _locked = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    final app = MaterialApp.router(
      title: 'Streak It',
      debugShowCheckedModeBanner: false,
      themeMode: themeState.themeMode,
      theme: themeState.lightTheme,
      darkTheme: themeState.darkTheme,
      routerConfig: router,
    );

    if (_locked) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: themeState.themeMode,
        theme: themeState.lightTheme,
        darkTheme: themeState.darkTheme,
        home: _BiometricLockScreen(onUnlock: _authenticate),
      );
    }

    return app;
  }
}

// ── Biometric lock screen ──────────────────────────────────────────────────

class _BiometricLockScreen extends StatelessWidget {
  final VoidCallback onUnlock;
  const _BiometricLockScreen({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    // PATCH B — theme-responsive (not hardcoded dark)
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔒', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 24),
              Text(
                'Streak It is locked',
                style: AppTypography.headlineSmall.copyWith(
                  color: textTheme.titleMedium?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Authenticate to continue',
                style: AppTypography.bodyMedium.copyWith(
                  color: textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: onUnlock,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
