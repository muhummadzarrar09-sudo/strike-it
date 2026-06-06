import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/biometric_service.dart';

class BiometricLockScreen extends ConsumerStatefulWidget {
  final Widget child;
  const BiometricLockScreen({super.key, required this.child});

  @override
  ConsumerState<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen>
    with WidgetsBindingObserver {
  bool _locked = true;
  bool _checking = true;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkBiometrics();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Lock when app goes to background
      setState(() => _locked = true);
    } else if (state == AppLifecycleState.resumed && _locked) {
      // Try to authenticate when coming back
      _authenticate();
    }
  }

  Future<void> _checkBiometrics() async {
    final available = await BiometricService.instance.isAvailable;
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _checking = false;
    });
    if (available) {
      _authenticate();
    } else {
      // No biometric hardware — skip lock entirely
      setState(() => _locked = false);
    }
  }

  Future<void> _authenticate() async {
    if (!_locked) return;

    final ok = await BiometricService.instance.authenticate(
      reason: 'Verify it\'s you to open Streak It',
      stickyAuth: true,
    );

    if (!mounted) return;
    if (ok) {
      setState(() => _locked = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: StreakItTheme.black,
        body: Center(child: CircularProgressIndicator(color: StreakItTheme.accent)),
      );
    }

    if (!_locked) return widget.child;

    return Scaffold(
      backgroundColor: StreakItTheme.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: StreakItTheme.accent, width: 2),
                  ),
                  child: Icon(
                    _biometricAvailable ? Icons.fingerprint : Icons.lock,
                    size: 40,
                    color: StreakItTheme.accent,
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  'STREAK IT',
                  style: StreakItTheme.textTheme.displaySmall?.copyWith(
                    color: StreakItTheme.accent,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  _biometricAvailable
                      ? 'Unlock with fingerprint or face'
                      : 'Tap to open',
                  style: StreakItTheme.textTheme.bodyMedium?.copyWith(
                    color: StreakItTheme.mutedGray,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                if (_biometricAvailable)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _authenticate,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('UNLOCK'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: StreakItTheme.accent,
                        side: const BorderSide(color: StreakItTheme.accent, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _locked = false),
                      child: const Text('OPEN STREAK IT'),
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