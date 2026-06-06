import 'package:flutter_test/flutter_test.dart';
import 'package:streak_it/core/services/biometric_service.dart';

/// ═══════════════════════════════════════════════════════════════════
/// BiometricService — Unit Tests (no device biometric needed)
/// ═══════════════════════════════════════════════════════════════════

void main() {
  group('BiometricService', () {
    test('singleton returns same instance', () {
      final a = BiometricService.instance;
      final b = BiometricService.instance;
      expect(identical(a, b), true);
    });

    test('initial state is unknown', () {
      // Reset for test
      BiometricService.instance.reset();
      expect(BiometricService.instance.state, BiometricState.unknown);
    });

    test('lock() only locks if authenticated', () {
      final service = BiometricService.instance;
      service.reset();
      // Lock when unknown — should not change
      service.lock();
      expect(service.state, BiometricState.unknown);
    });

    test('isAvailable returns a bool (runs without crash)', () async {
      final service = BiometricService.instance;
      final result = await service.isAvailable;
      expect(result, isA<bool>());
    });

    test('getAvailableTypes returns list (runs without crash)', () async {
      final types = await BiometricService.instance.getAvailableTypes();
      expect(types, isA<List<BiometricType>>());
    });
  });
}
