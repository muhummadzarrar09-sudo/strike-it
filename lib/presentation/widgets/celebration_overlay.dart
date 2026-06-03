import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/xp_service.dart';

/// Full-screen celebration overlay shown on:
///   - Streak milestones
///   - Level-ups
///   - "All habits done today" perfect day
///
/// Uses a custom particle painter for the confetti burst — no Lottie
/// file dependency (zero asset required, fully procedural).
///
/// Usage:
///   CelebrationOverlay.show(context, award: xpAward);

class CelebrationOverlay extends StatefulWidget {
  final XPAward award;
  final String habitName;
  final VoidCallback? onDismiss;

  const CelebrationOverlay({
    super.key,
    required this.award,
    required this.habitName,
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required XPAward award,
    required String habitName,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'celebration',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, anim, _) => CelebrationOverlay(
        award: award,
        habitName: habitName,
      ),
      transitionBuilder: (ctx, anim, _, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = _generateParticles();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    // Auto-dismiss after 3 seconds.
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  List<_Particle> _generateParticles() {
    final rng = math.Random();
    return List.generate(60, (_) {
      return _Particle(
        x: rng.nextDouble(),
        startY: 0.3 + rng.nextDouble() * 0.2,
        size: 4 + rng.nextDouble() * 8,
        color: AppColors.habitColors[rng.nextInt(AppColors.habitColors.length)],
        speed: 0.4 + rng.nextDouble() * 0.6,
        angle: -math.pi / 2 + (rng.nextDouble() - 0.5) * math.pi * 1.2,
        rotation: rng.nextDouble() * math.pi * 4,
        shape: rng.nextInt(3), // 0=square, 1=circle, 2=star
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // ── Particle canvas ────────────────────────────────────────
            AnimatedBuilder(
              animation: _particleController,
              builder: (_, __) => CustomPaint(
                size: Size(size.width, size.height),
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                ),
              ),
            ),

            // ── Ring burst — milestone only, behind particles, non-blocking
            if (widget.award.milestone != null)
              IgnorePointer(
                child: Center(
                  child: _RingBurst(screenWidth: size.width),
                ),
              ),

            // ── Content card ───────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 36),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.darkBorder,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Big emoji
                    Text(
                      _emoji,
                      style: const TextStyle(fontSize: 56),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.3, 0.3),
                          curve: Curves.easeOutBack,
                          duration: 600.ms,
                        )
                        .fade(duration: 300.ms),

                    const SizedBox(height: 16),

                    Text(
                      _headline,
                      style: AppTypography.headlineLarge.copyWith(
                        color: AppColors.textPrimaryDark,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate(delay: 150.ms)
                        .slideY(begin: 0.3, duration: 400.ms, curve: Curves.easeOut)
                        .fade(duration: 350.ms),

                    const SizedBox(height: 8),

                    Text(
                      widget.habitName,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMutedDark,
                      ),
                      textAlign: TextAlign.center,
                    ).animate(delay: 200.ms).fade(duration: 350.ms),

                    const SizedBox(height: 24),

                    // XP pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.brand, AppColors.brandLight],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('⚡', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            '+${widget.award.total} XP',
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.award.bonus > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              '(+${widget.award.bonus} bonus)',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ).animate(delay: 300.ms).scale(
                          begin: const Offset(0.7, 0.7),
                          curve: Curves.easeOutBack,
                          duration: 500.ms,
                        ),

                    if (widget.award.leveledUp) ...[
                      const SizedBox(height: 14),
                      Text(
                        '🆙 Level ${widget.award.newLevel} reached!',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.levelGold,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                          .animate(delay: 450.ms)
                          .fade(duration: 400.ms)
                          .slideY(begin: 0.2, duration: 400.ms),
                    ],

                    const SizedBox(height: 20),

                    Text(
                      'Tap anywhere to continue',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMutedDark,
                      ),
                    ).animate(delay: 600.ms).fade(duration: 400.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _emoji {
    if (widget.award.leveledUp) return '🆙';
    if (widget.award.milestone != null) {
      const map = {7: '⚡', 21: '🧠', 30: '🔥', 66: '🛸', 100: '💯', 365: '🏆'};
      return map[widget.award.milestone] ?? '🎉';
    }
    return '✅';
  }

  String get _headline {
    if (widget.award.milestone != null) {
      return '${widget.award.milestone}-Day\nStreak!';
    }
    if (widget.award.leveledUp) {
      return 'Level\n${widget.award.newLevel}!';
    }
    return 'Habit\nComplete!';
  }
}

// ── Particle system ────────────────────────────────────────────────────────

class _Particle {
  final double x;
  final double startY;
  final double size;
  final Color color;
  final double speed;
  final double angle;
  final double rotation;
  final int shape;

  const _Particle({
    required this.x,
    required this.startY,
    required this.size,
    required this.color,
    required this.speed,
    required this.angle,
    required this.rotation,
    required this.shape,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  const _ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress * p.speed).clamp(0.0, 1.0);
      if (t <= 0) continue;

      // Physics: ballistic arc outward then gravity pulls down.
      final vx = math.cos(p.angle) * t * size.width * 0.6;
      final vy = math.sin(p.angle) * t * size.height * 0.4 +
          (9.8 * t * t * size.height * 0.3);

      final px = p.x * size.width + vx;
      final py = p.startY * size.height + vy;

      final opacity = (1.0 - t * 0.8).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation * progress * 3);

      switch (p.shape) {
        case 0: // square
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size,
            ),
            paint,
          );
          break;
        case 1: // circle
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
          break;
        case 2: // elongated strip
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size * 0.4,
              height: p.size * 1.8,
            ),
            paint,
          );
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

// ── Ring burst ─────────────────────────────────────────────────────────────
// Three concentric amber rings that radiate outward from center on milestone.
// Fires once, auto-disposes. Never blocks taps (wrapped in IgnorePointer).

class _RingBurst extends StatefulWidget {
  final double screenWidth;
  const _RingBurst({required this.screenWidth});

  @override
  State<_RingBurst> createState() => _RingBurstState();
}

class _RingBurstState extends State<_RingBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: Size(widget.screenWidth, widget.screenWidth),
        painter: _RingBurstPainter(progress: _ctrl.value),
      ),
    );
  }
}

class _RingBurstPainter extends CustomPainter {
  final double progress;
  const _RingBurstPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.6;

    // Three rings at different phases (0, 0.15, 0.30 offset)
    for (int i = 0; i < 3; i++) {
      final phase = (progress - i * 0.15).clamp(0.0, 1.0);
      if (phase <= 0) continue;

      final radius = maxRadius * phase;
      final strokeWidth = (4.0 * (1.0 - phase)).clamp(0.0, 4.0);

      // Opacity fades in the last 40% of the animation
      final fadeStart = 0.6;
      final opacity = phase < fadeStart
          ? 1.0
          : 1.0 - ((phase - fadeStart) / (1.0 - fadeStart));

      // Amber at 60%, 40%, 20% base alpha × fade
      const baseAlphas = [0.6, 0.4, 0.2];
      final alpha = (baseAlphas[i] * opacity).clamp(0.0, 1.0);

      if (strokeWidth < 0.1 || alpha < 0.01) continue;

      final paint = Paint()
        ..color = const Color(0xFFE8952A).withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RingBurstPainter old) => old.progress != progress;
}
