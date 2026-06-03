import 'package:flutter/material.dart';

/// Streak It — Color System v3
///
/// Brand metaphor: fire and momentum. A streak is a flame that must not go out.
/// The accent is amber-500 — the color of honey and candle flame. Not neon,
/// not orange, not yellow. Exactly #F59E0B on a rich blue-black background.
///
/// Two semantic roles only:
///   Amber  = interactive / active / streak (the fire is alive)
///   Green  = completed / done (the goal was met)
/// These must never share the same color. Ever.
abstract final class AppColors {

  // ── BRAND — amber-500 ──────────────────────────────────────────────────────
  // One color. Streak hero, FAB, active nav, tap targets, progress.
  // #F59E0B is exactly amber-500: warm honey, candle flame, NOT neon.

  static const Color brand      = Color(0xFFE8952A); // warm aged gold
  static const Color brandLight = Color(0xFFF0A83A); // one step lighter
  static const Color brandMuted = Color(0xFFC4791F); // pressed state
  static const Color brandFill  = Color(0x1AE8952A); // 10% amber tint

  // ── DARK PALETTE ──────────────────────────────────────────────────────────

  static const Color darkBackground = Color(0xFF0D0C11);
  static const Color darkSurface    = Color(0xFF151319);
  static const Color darkSurface2   = Color(0xFF1C1A21);
  static const Color darkBorder     = Color(0xFF23242D);

  // ── LIGHT PALETTE ─────────────────────────────────────────────────────────

  static const Color lightBackground = Color(0xFFF6F6F9);
  static const Color lightSurface    = Color(0xFFFFFFFF);
  static const Color lightSurface2   = Color(0xFFF0F0F5);
  static const Color lightBorder     = Color(0xFFE3E3EA);

  // ── TEXT ──────────────────────────────────────────────────────────────────

  static const Color textPrimaryDark    = Color(0xFFEEEEF2);
  static const Color textPrimaryLight   = Color(0xFF111116);
  static const Color textSecondaryDark  = Color(0xFF8E8EA8);
  static const Color textSecondaryLight = Color(0xFF4A4A60);
  static const Color textMutedDark      = Color(0xFF5A5A70);
  static const Color textMutedLight     = Color(0xFF8A8A9E);

  // ── SEMANTIC ───────────────────────────────────────────────────────────────
  // Two roles. Distinct. Never interchangeable.

  /// Completion, done states — green-500. Organic, readable, clearly "done".
  static const Color success     = Color(0xFF19C266);
  static const Color successFill = Color(0x1A19C266); // 10% green

  /// Streak-at-risk warnings — burnt amber-dark. Different enough from brand.
  static const Color warning     = Color(0xFFC07D2A);
  static const Color warningFill = Color(0x12C07D2A);

  /// Delete, danger — dark red.
  static const Color destructive     = Color(0xFFC94444);
  static const Color destructiveFill = Color(0x12C94444);

  // ── HABIT CARD COLORS ─────────────────────────────────────────────────────
  // 4 muted tones for habit card icons. Desaturated, considered choices.

  static const Color habitAmber      = Color(0xFFE8952A); // gold — default, matches brand
  static const Color habitForest     = Color(0xFF3A8C65); // forest green
  static const Color habitSlate      = Color(0xFF5A6A9A); // muted slate (softer than old indigo)
  static const Color habitTerracotta = Color(0xFFC0553A); // terracotta

  static const List<Color> habitColors = [
    habitAmber,
    habitForest,
    habitSlate,
    habitTerracotta,
  ];

  // ── HEATMAP ───────────────────────────────────────────────────────────────
  // Amber ramp — darkSurface2 (empty) → brand amber (max intensity).
  // Maps the fire metaphor: more activity = warmer glow.

  static const Color heatmapEmpty = Color(0xFF1C1A21); // darkSurface2
  static const Color heatmapL1    = Color(0xFF3D2E0A); // very faint amber
  static const Color heatmapL2    = Color(0xFF7A5710); // low amber
  static const Color heatmapL3    = Color(0xFFB07D18); // mid amber
  static const Color heatmapL4    = Color(0xFFD99510); // warm amber
  static const Color heatmapL5    = Color(0xFFE8952A); // brand gold — full activity

  // ── GAMIFICATION ──────────────────────────────────────────────────────────

  static const Color levelBronze  = Color(0xFF8C6A3A);
  static const Color levelSilver  = Color(0xFF8A8AA0);
  static const Color levelGold    = Color(0xFFC9A832);
  static const Color levelDiamond = Color(0xFF5B8CB8);

  // ── ACCENT PALETTE ────────────────────────────────────────────────────────
  // Amber is now the default (index 0). Indigo removed.

  static const List<AccentPalette> accentOptions = [
    AccentPalette(
      label: 'Amber',
      primary: brand,
      light: brandLight,
      fill: brandFill,
    ),
    AccentPalette(
      label: 'Forest',
      primary: habitForest,
      light: Color(0xFF4DA87C),
      fill: Color(0x123A8C65),
    ),
    AccentPalette(
      label: 'Slate',
      primary: habitSlate,
      light: Color(0xFF7A8FBF),
      fill: Color(0x125A6A9A),
    ),
    AccentPalette(
      label: 'Terracotta',
      primary: habitTerracotta,
      light: Color(0xFFD46B52),
      fill: Color(0x12C0553A),
    ),
  ];
}

/// A single user-selectable accent — primary + light variant + tint fill.
class AccentPalette {
  final String label;
  final Color primary;
  final Color light;
  final Color fill;

  const AccentPalette({
    required this.label,
    required this.primary,
    required this.light,
    required this.fill,
  });

  static List<AccentPalette> get all => AppColors.accentOptions;
}
