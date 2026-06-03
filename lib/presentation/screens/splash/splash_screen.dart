import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/animated_flame.dart';
import '../../../domain/notification_service.dart';
import '../../../core/utils/extensions.dart';
import '../../providers/database_providers.dart';

/// Splash screen — shown on app launch.
/// Responsibilities:
///   1. Init notification service
///   2. Determine initial route (onboarding vs home)
///   3. Navigate after a short delay
///
/// No loading spinners. Clean, branded, instant feel.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _init();
  }

  Future<void> _init() async {
    // Run init tasks in parallel.
    await Future.wait([
      _controller.forward(),
      _initNotifications(),
      Future.delayed(const Duration(milliseconds: 1400)), // min splash time
    ]);

    if (!mounted) return;

    final route = await resolveInitialRoute();
    if (!mounted) return;
    context.go(route);
  }

  Future<void> _initNotifications() async {
    try {
      final service = ref.read(notificationServiceProvider);
      await service.initialise();
      // Request permission — Android 13+ requires explicit grant.
      // Without this, notifications are silently dropped (Bug #2 from audit).
      await service.requestPermission();
    } catch (_) {
      // Non-fatal — app works without notifications.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Animated flame logo ──────────────────────────────────
                const AnimatedFlame(size: 64),
                const SizedBox(height: 20),

                // ── App Name ─────────────────────────────────────────────
                Text(
                  'Streak It',
                  style: AppTypography.displayMedium.copyWith(
                    color: context.textPrimary,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Build habits. Break limits.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
