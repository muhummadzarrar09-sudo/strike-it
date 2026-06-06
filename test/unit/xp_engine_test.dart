import 'package:flutter_test/flutter_test.dart';
import 'package:streak_it/features/gamification/providers/gamification_provider.dart';

/// ═══════════════════════════════════════════════════════════════════
/// XpEngine — Level/XP Calculation Tests
/// ═══════════════════════════════════════════════════════════════════

void main() {
  group('XpEngine', () {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // LEVEL FROM XP
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    group('levelFromXp', () {
      test('0 XP = level 1', () {
        expect(XpEngine.levelFromXp(0), 1);
      });

      test('50 XP = level 1', () {
        expect(XpEngine.levelFromXp(50), 1);
      });

      test('99 XP = level 1 (boundary)', () {
        expect(XpEngine.levelFromXp(99), 1);
      });

      test('100 XP = level 2 (boundary)', () {
        expect(XpEngine.levelFromXp(100), 2);
      });

      test('249 XP = level 2 (boundary)', () {
        expect(XpEngine.levelFromXp(249), 2);
      });

      test('250 XP = level 3', () {
        expect(XpEngine.levelFromXp(250), 3);
      });

      test('500 XP = level 4', () {
        expect(XpEngine.levelFromXp(500), 4);
      });

      test('1000 XP = level 5', () {
        expect(XpEngine.levelFromXp(1000), 5);
      });

      test('2000 XP = level 6', () {
        expect(XpEngine.levelFromXp(2000), 6);
      });

      test('4000 XP = level 7', () {
        expect(XpEngine.levelFromXp(4000), 7);
      });

      test('8000 XP = level 8', () {
        expect(XpEngine.levelFromXp(8000), 8);
      });

      test('16000 XP = level 9', () {
        expect(XpEngine.levelFromXp(16000), 9);
      });

      test('32000 XP = level 10 (max)', () {
        expect(XpEngine.levelFromXp(32000), 10);
      });

      test('50000 XP = level 10 (beyond max)', () {
        expect(XpEngine.levelFromXp(50000), 10);
      });
    });

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // XP TO NEXT LEVEL
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    group('xpToNextLevel', () {
      test('0 XP → 100 to next', () {
        expect(XpEngine.xpToNextLevel(0), 100);
      });

      test('50 XP → 50 to next', () {
        expect(XpEngine.xpToNextLevel(50), 50);
      });

      test('99 XP → 1 to next', () {
        expect(XpEngine.xpToNextLevel(99), 1);
      });

      test('100 XP (level 2) → 150 to next', () {
        expect(XpEngine.xpToNextLevel(100), 150);
      });

      test('249 XP → 1 to level 3', () {
        expect(XpEngine.xpToNextLevel(249), 1);
      });

      test('at max level (32000) → 0 to next', () {
        expect(XpEngine.xpToNextLevel(32000), 0);
      });

      test('beyond max → 0 to next', () {
        expect(XpEngine.xpToNextLevel(99999), 0);
      });
    });

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // LEVEL PROGRESS
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    group('levelProgress', () {
      test('0 XP = 0.0 progress', () {
        expect(XpEngine.levelProgress(0), 0.0);
      });

      test('50 XP = 0.5 progress', () {
        expect(XpEngine.levelProgress(50), 0.5);
      });

      test('100 XP = 0.0 (just leveled up)', () {
        expect(XpEngine.levelProgress(100), 0.0);
      });

      test('175 XP (level 2, halfway to 3) = 0.5', () {
        // Level 2 thresholds: 100 → 250. 175 is halfway
        expect(XpEngine.levelProgress(175), closeTo(0.5, 0.001));
      });

      test('max level = 1.0', () {
        expect(XpEngine.levelProgress(32000), 1.0);
      });

      test('beyond max = 1.0', () {
        expect(XpEngine.levelProgress(50000), 1.0);
      });
    });
  });
}
