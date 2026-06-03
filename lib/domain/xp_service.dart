import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/streak_calculator.dart';

/// XP & Level persistence service.
///
/// XP is stored in SharedPreferences (it's a single integer — no need
/// for a DB table). The level is always derived from XP, never stored.
///
/// This service is intentionally synchronous-cache-backed:
/// we load once on first call and write-through on every mutation.
class XPService {
  int? _cachedXP; // null = not loaded yet

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Total XP earned all-time.
  Future<int> getTotalXP() async {
    if (_cachedXP != null) return _cachedXP!;
    final prefs = await SharedPreferences.getInstance();
    _cachedXP = prefs.getInt(AppConstants.prefTotalXP) ?? 0;
    return _cachedXP!;
  }

  int get cachedXP => _cachedXP ?? 0;

  int get level => StreakCalculator.levelForXP(cachedXP);

  double get levelProgress => StreakCalculator.xpProgressInLevel(cachedXP);

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Awards XP for a habit completion + milestone bonus if applicable.
  /// Returns the [XPAward] breakdown so callers can decide what to show.
  Future<XPAward> awardForCompletion(int newStreak) async {
    final base = AppConstants.xpPerCompletion;
    final bonus = _milestoneBonus(newStreak);
    final total = base + bonus;
    final milestone = _milestoneForStreak(newStreak);

    final before = await getTotalXP();
    final levelBefore = StreakCalculator.levelForXP(before);
    await _add(total);
    final after = _cachedXP ?? 0;
    final levelAfter = StreakCalculator.levelForXP(after);

    return XPAward(
      base: base,
      bonus: bonus,
      total: total,
      totalXP: after,
      leveledUp: levelAfter > levelBefore,
      newLevel: levelAfter,
      milestone: milestone,
    );
  }

  /// Directly adds [amount] XP (e.g. for achievements, manual rewards).
  Future<void> addXP(int amount) => _add(amount);

  Future<void> _add(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    _cachedXP = (_cachedXP ?? 0) + amount;
    await prefs.setInt(AppConstants.prefTotalXP, _cachedXP!);
  }

  /// Resets XP to 0 (for testing / dev builds only).
  Future<void> reset() async {
    _cachedXP = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefTotalXP, 0);
  }

  static int _milestoneBonus(int streak) {
    const bonusMap = {
      7: AppConstants.xpStreakBonus7,
      21: AppConstants.xpStreakBonus21,
      30: AppConstants.xpStreakBonus30,
      66: AppConstants.xpStreakBonus66,
      100: AppConstants.xpStreakBonus100,
    };
    return bonusMap[streak] ?? 0;
  }

  static int? _milestoneForStreak(int streak) {
    const milestones = {7, 21, 30, 66, 100};
    return milestones.contains(streak) ? streak : null;
  }
}

/// Result of an XP award operation.
class XPAward {
  final int base;
  final int bonus;
  final int total;
  final int totalXP;
  final bool leveledUp;
  final int newLevel;
  final int? milestone; // null if no milestone hit

  bool get hasMilestone => milestone != null;

  const XPAward({
    required this.base,
    required this.bonus,
    required this.total,
    required this.totalXP,
    required this.leveledUp,
    required this.newLevel,
    this.milestone,
  });
}
