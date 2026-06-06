import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/services/isar_service.dart';
import 'core/services/notification_service.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/onboarding/screens/notification_permission_screen.dart';
import 'features/auth/widgets/biometric_lock_screen.dart';
import 'common/widgets/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Init Isar (offline-first — zero-dependency startup)
  await IsarService.init();

  // 2. Init notifications (channel creation, no permission request yet)
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: StreakItApp()));
}

class StreakItApp extends ConsumerWidget {
  const StreakItApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingDone = ref.watch(isOnboardingCompleteProvider);

    return MaterialApp(
      title: 'Streak It',
      debugShowCheckedModeBanner: false,
      theme: StreakItTheme.darkTheme,
      darkTheme: StreakItTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: onboardingDone.when(
        loading: () => const Scaffold(
          backgroundColor: StreakItTheme.black,
          body: Center(child: CircularProgressIndicator(color: StreakItTheme.accent)),
        ),
        error: (_, __) => const AppShell(),
        data: (done) {
          if (!done) return const OnboardingScreen();
          // Wrap everything in biometric lock + notification permission gate
          return _AppWithPermissions();
        },
      ),
    );
  }
}

/// Handles notification permission → biometric lock → actual app
class _AppWithPermissions extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AppWithPermissions> createState() => _AppWithPermissionsState();
}

class _AppWithPermissionsState extends ConsumerState<_AppWithPermissions> {
  bool _notificationsHandled = false;
  bool _showNotificationPrompt = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    // Check if permission was already granted
    final status = await NotificationService.instance.requestPermission();

    if (!mounted) return;

    if (status == 'granted') {
      setState(() {
        _notificationsHandled = true;
        _showNotificationPrompt = false;
      });
    } else {
      // Show the permission screen
      setState(() {
        _showNotificationPrompt = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show notification permission screen first
    if (_showNotificationPrompt) {
      return NotificationPermissionScreen(
        onComplete: () {
          setState(() {
            _notificationsHandled = true;
            _showNotificationPrompt = false;
          });
        },
      );
    }

    // Still checking
    if (!_notificationsHandled && !_showNotificationPrompt) {
      return const Scaffold(
        backgroundColor: StreakItTheme.black,
        body: Center(child: CircularProgressIndicator(color: StreakItTheme.accent)),
      );
    }

    // Wrap app in biometric lock
    return BiometricLockScreen(
      child: const AppShell(),
    );
  }
}