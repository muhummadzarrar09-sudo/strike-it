import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Streak It — Typography System
///
/// Two font families:
///   Inter        → all UI text
///   SpaceGrotesk → numbers, stats, streak counts (tabular figures)
///
/// Design intent (per user feedback):
///   "D fonts are just one style and even size" — we fix this with
///   dramatic size/weight contrast. Nothing should look the same.
///
///   Hero numbers (streak): 72–80px Bold — dominates the screen
///   Section labels: 11px SemiBold, UPPERCASE, tracked — guide not shout
///   Habit names: 16px SemiBold — readable but not the star
///   Body copy: 14px Regular — muted, informational
///   Captions: 11px Regular — barely there, as it should be
abstract final class AppTypography {

  // ── INTER SCALE ────────────────────────────────────────────────────────

  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.2,
    height: 1.15,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.9,
    height: 1.2,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    height: 1.3,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.35,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.55,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.55,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.5,
  );

  // Labels — used for section headers (UPPERCASE, tracked, small)
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.4,
  );

  /// Section label — "TODAY'S HABITS", "APPEARANCE" etc.
  /// Small, all-caps when used, tracked out, muted — guides not shouts.
  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,   // wider spacing = section label energy
    height: 1.4,
  );

  /// Tiny info — timestamps, secondary hints, barely-there text.
  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.45,
  );

  // ── SPACEGROTESK SCALE (numbers & stats) ───────────────────────────────
  // These are the personality of the app. The streak number should be
  // the first thing the user's eye goes to. Make it impossible to miss.

  /// THE hero number — 72px. Streak count on home screen.
  /// First thing the eye sees. Bold. Violet. Unmissable.
  static const TextStyle statHero = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 72,
    fontWeight: FontWeight.w700,
    letterSpacing: -3.0,
    height: 1.0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Large stat — 48px. Detail screens, achievement cards.
  static const TextStyle statLarge = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -2.0,
    height: 1.05,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Medium stat — 28px. Cards, analytics bars.
  static const TextStyle statMedium = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.0,
    height: 1.1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Small stat — 16px. Inline counts, chart labels.
  static const TextStyle statSmall = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // ── TEXT THEME BUILDER ─────────────────────────────────────────────────

  // ── SEMANTIC ROLE STYLES ─────────────────────────────────────────────────
  // These carry semantic meaning — use by role, not by appearance.

  /// Section divider labels — "HABITS", "TODAY", etc.
  /// Always apply .toUpperCase() to the string in the widget.
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.9,
    height: 1.0,
    color: AppColors.textMutedDark, // caller overrides for light theme
  );

  /// Card primary text — habit names, setting titles.
  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  // caption already exists — confirmed at line 138, no duplicate needed

  // ── TEXT THEME BUILDER ─────────────────────────────────────────────────
  static TextTheme buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge:   displayLarge.copyWith(color: primary),
      displayMedium:  displayMedium.copyWith(color: primary),
      displaySmall:   headlineLarge.copyWith(color: primary),
      headlineLarge:  headlineLarge.copyWith(color: primary),
      headlineMedium: headlineMedium.copyWith(color: primary),
      headlineSmall:  headlineSmall.copyWith(color: primary),
      titleLarge:     titleLarge.copyWith(color: primary),
      titleMedium:    titleMedium.copyWith(color: primary),
      titleSmall:     titleSmall.copyWith(color: primary),
      bodyLarge:      bodyLarge.copyWith(color: primary),
      bodyMedium:     bodyMedium.copyWith(color: primary),
      bodySmall:      bodySmall.copyWith(color: secondary),
      labelLarge:     labelLarge.copyWith(color: primary),
      labelMedium:    labelMedium.copyWith(color: secondary),
      labelSmall:     labelSmall.copyWith(color: secondary),
    );
  }
}
