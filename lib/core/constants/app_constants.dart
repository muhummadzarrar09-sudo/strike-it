/// Global constants for StreakIt.
/// Centralised here so magic numbers never appear inline in business logic.
abstract final class AppConstants {
  // ── App Identity ──────────────────────────────────────────────────────
  static const String appName = 'Streak It';
  static const String appVersion = '1.0.0';
  static const String dbName = 'streak_it.db';
  static const int dbVersion = 1;

  // ── SharedPreferences Keys ────────────────────────────────────────────
  static const String prefThemeMode = 'theme_mode';        // 'dark' | 'light' | 'system'
  static const String prefAccentIndex = 'accent_index';    // 0–5
  static const String prefOnboardingDone = 'onboarding_done';
  static const String prefBiometricEnabled = 'biometric_enabled';
  static const String prefFirstLaunchDate = 'first_launch_date';
  static const String prefTotalXP = 'total_xp';

  // ── Streak / Score Engine ─────────────────────────────────────────────

  /// Score decay per missed day (percentage points deducted from score).
  /// Inspired by Loop Habit Tracker's exponential smoothing model.
  /// Score = previous_score × (1 − decay) + completion × 100 × decay
  static const double scoreDecayFactor = 0.1;

  /// Minimum score before a habit is considered "at risk" (0–100).
  static const double scoreAtRiskThreshold = 40.0;

  /// Maximum allowed grace days a user can configure per habit.
  static const int maxGraceDays = 3;

  // ── XP / Gamification ─────────────────────────────────────────────────

  static const int xpPerCompletion = 10;
  static const int xpStreakBonus7 = 50;    // Bonus at 7-day streak
  static const int xpStreakBonus21 = 150;
  static const int xpStreakBonus30 = 250;
  static const int xpStreakBonus66 = 500;
  static const int xpStreakBonus100 = 1000;

  /// XP thresholds for level-up. Index = level (0-indexed).
  static const List<int> xpLevelThresholds = [
    0,     // Level 1
    500,   // Level 2
    1200,  // Level 3
    2500,  // Level 4
    5000,  // Level 5
    9000,  // Level 6
    15000, // Level 7
    25000, // Level 8
    40000, // Level 9
    60000, // Level 10 (Diamond)
  ];

  // ── Milestone Day Counts ──────────────────────────────────────────────
  static const List<int> streakMilestones = [7, 14, 21, 30, 50, 66, 100, 200, 365];

  // ── Analytics Periods (days) ──────────────────────────────────────────
  static const int analyticsShort = 7;
  static const int analyticsMedium = 30;
  static const int analyticsLong = 90;
  static const int analyticsYear = 365;

  // ── Habit Count Limits (free tier) ───────────────────────────────────
  // Set to very large number — app is fully free, offline.
  static const int maxHabits = 9999;

  // ── Notification IDs ──────────────────────────────────────────────────
  // Each habit gets IDs in ranges. Habit index 0 → IDs 1000–1009, etc.
  static const int notificationBaseId = 1000;
  static const int notificationSlotSize = 10;

  // ── Onboarding ────────────────────────────────────────────────────────
  static const int onboardingTotalPages = 3;

  // ── Habit Frequency Options ───────────────────────────────────────────
  static const List<String> frequencyLabels = [
    'Every day',
    'Weekdays',
    'Weekends',
    'Custom days',
  ];

  // ── Quantified Habit Max ──────────────────────────────────────────────
  static const int quantifiedMax = 9999;

  // ── Animation Durations ───────────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 180);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animCelebration = Duration(milliseconds: 1800);
}
