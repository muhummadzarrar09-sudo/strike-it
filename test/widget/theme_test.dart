import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streak_it/core/theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════════
/// Theme Smoke Tests — ensure design system has no broken references
/// ═══════════════════════════════════════════════════════════════════

void main() {
  group('StreakItTheme', () {
    test('darkTheme builds without errors', () {
      expect(() => StreakItTheme.darkTheme, returnsNormally);
    });

    test('textTheme is non-null for all styles', () {
      final theme = StreakItTheme.textTheme;
      expect(theme.displayLarge, isNotNull);
      expect(theme.displayMedium, isNotNull);
      expect(theme.displaySmall, isNotNull);
      expect(theme.headlineLarge, isNotNull);
      expect(theme.headlineMedium, isNotNull);
      expect(theme.headlineSmall, isNotNull);
      expect(theme.titleLarge, isNotNull);
      expect(theme.titleMedium, isNotNull);
      expect(theme.titleSmall, isNotNull);
      expect(theme.bodyLarge, isNotNull);
      expect(theme.bodyMedium, isNotNull);
      expect(theme.bodySmall, isNotNull);
      expect(theme.labelLarge, isNotNull);
      expect(theme.labelMedium, isNotNull);
      expect(theme.labelSmall, isNotNull);
    });

    test('accent color is the branded #FF4D1C', () {
      expect(StreakItTheme.accent, const Color(0xFFFF4D1C));
    });

    test('background is pure black', () {
      expect(StreakItTheme.black, const Color(0xFF000000));
    });

    test('heatmap has 5 levels', () {
      expect(StreakItTheme.heatmapColors.length, 5);
    });

    test('all named colors are distinct', () {
      final colors = [
        StreakItTheme.black, StreakItTheme.nearBlack, StreakItTheme.deepCharcoal,
        StreakItTheme.charcoal, StreakItTheme.darkGray, StreakItTheme.midGray,
        StreakItTheme.mutedGray, StreakItTheme.lightGray, StreakItTheme.offWhite,
        StreakItTheme.nearWhite, StreakItTheme.white, StreakItTheme.accent,
        StreakItTheme.success, StreakItTheme.warning, StreakItTheme.error,
      ];
      expect(colors.toSet().length, colors.length);
    });

    test('button themes have zero elevation (no shadows)', () {
      final theme = StreakItTheme.darkTheme;
      final elevated = theme.elevatedButtonTheme.style;
      final outlined = theme.outlinedButtonTheme.style;
      expect(elevated?.elevation?.resolve({}), 0);
    });

    test('card theme has zero border radius (brutalist)', () {
      final card = StreakItTheme.darkTheme.cardTheme;
      expect(card.shape, isA<RoundedRectangleBorder>());
      final shape = card.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(0));
    });
  });
}
