import 'package:flutter/material.dart';

/// Animated 🔥 flame widget — no external packages.
///
/// Uses two AnimationControllers staggered by 200 ms so scale and
/// wobble are out of phase, creating a natural "breathing" flame.
///
/// Scale:  0.88 → 1.0  period 800 ms (inhale/exhale)
/// Wobble: −0.05 → +0.05 turns  period 600 ms (sway)
///
/// Dispose is handled in the State — no memory leaks.
class AnimatedFlame extends StatefulWidget {
  final double size;

  const AnimatedFlame({super.key, this.size = 40});

  @override
  State<AnimatedFlame> createState() => _AnimatedFlameState();
}

class _AnimatedFlameState extends State<AnimatedFlame>
    with TickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late AnimationController _wobbleCtrl;
  late Animation<double> _scale;
  late Animation<double> _wobble;

  @override
  void initState() {
    super.initState();

    // Scale controller — breathing rhythm
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );

    // Wobble controller — sway rhythm, staggered 200 ms
    _wobbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _wobble = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _wobbleCtrl, curve: Curves.easeInOut),
    );

    // Stagger: start wobble 200 ms after scale so they're out of phase
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _wobbleCtrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _wobbleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _wobble,
      child: ScaleTransition(
        scale: _scale,
        child: Text(
          '🔥',
          style: TextStyle(
            fontSize: widget.size,
            // Emoji renders natively on Android — no custom font needed
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
