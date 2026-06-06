import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricState { unknown, available, unavailable, locked, authenticated }

class BiometricService {
  BiometricService._();
  static final instance = BiometricService._();

  final _auth = LocalAuthentication();
  BiometricState _state = BiometricState.unknown;
  BiometricState get state => _state;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // CHECK AVAILABILITY
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<bool> get isAvailable async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      _state = (canCheck || isDeviceSupported)
          ? BiometricState.available
          : BiometricState.unavailable;
      return _state == BiometricState.available;
    } on PlatformException catch (e) {
      debugPrint('Biometric check failed: $e');
      _state = BiometricState.unavailable;
      return false;
    }
  }

  /// Get list of available biometric types (fingerprint, face, iris)
  Future<List<BiometricType>> getAvailableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // AUTHENTICATE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Show biometric prompt. Returns true if authenticated.
  Future<bool> authenticate({
    required String reason,
    bool stickyAuth = true,
    bool biometricOnly = false,
  }) async {
    try {
      final available = await isAvailable;
      if (!available) {
        debugPrint('🔒 Biometric not available — falling back to unlocked');
        _state = BiometricState.authenticated;
        return true;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
        ),
      );

      _state = authenticated ? BiometricState.authenticated : BiometricState.locked;
      debugPrint(authenticated ? '✅ Biometric OK' : '❌ Biometric denied');
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('Biometric auth error: $e');
      _state = BiometricState.locked;

      // If user cancelled, that's fine — they stay on lock screen
      if (e.code == 'NotAvailable' || e.code == 'PasscodeNotSet') {
        // Device doesn't have lock screen set up — allow access
        _state = BiometricState.authenticated;
        return true;
      }

      return false;
    }
  }

  /// Called when app comes to foreground — re-lock
  void lock() {
    if (_state == BiometricState.authenticated) {
      _state = BiometricState.locked;
    }
  }

  void reset() {
    _state = BiometricState.unknown;
  }
}
