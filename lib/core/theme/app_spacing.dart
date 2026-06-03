import 'package:flutter/material.dart';

/// Streak It — Spacing token system.
///
/// All values are on the 4px grid. Use these exclusively
/// for padding, margin, and gap values — never raw literals.
///
/// Mobile-first: these values are calibrated for touch targets
/// and thumb-zone ergonomics, not desktop density.
abstract final class AppSpacing {
  static const double xs  =  4.0;
  static const double sm  =  8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;

  // ── Semantic shortcuts ──────────────────────────────────────────────────
  /// Standard horizontal screen padding — 24px matches thumb-safe zone.
  static const EdgeInsets screenH =
      EdgeInsets.symmetric(horizontal: lg);

  /// Card inner padding — 16px horizontal, 12px vertical.
  static const EdgeInsets card =
      EdgeInsets.symmetric(horizontal: md, vertical: sm + sm / 2);
  // 8 + 4 = 12 — avoiding the 14px non-grid value

  /// Section header padding: top 24, sides 24, bottom 8.
  static const EdgeInsets sectionHeader =
      EdgeInsets.fromLTRB(lg, lg, lg, sm);
}
