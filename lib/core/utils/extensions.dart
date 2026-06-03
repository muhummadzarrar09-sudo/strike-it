import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// ── Color Extensions ──────────────────────────────────────────────────────

extension ColorX on Color {
  /// Returns a version of this color with modified opacity.
  Color get subtle => withValues(alpha: 0.12);
  Color get muted => withValues(alpha: 0.5);
  Color get faded => withValues(alpha: 0.08);
}

// ── BuildContext Extensions ───────────────────────────────────────────────

extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get tt => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get viewPadding => MediaQuery.of(this).viewPadding;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  Color get surfaceColor => isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get surface2Color => isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
  Color get borderColor => isDark ? AppColors.darkBorder : AppColors.lightBorder;
  Color get textPrimary => isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  Color get textSecondary => isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  Color get textMuted => isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

  void showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.destructive : null,
      ),
    );
  }
}

// ── DateTime Extensions ───────────────────────────────────────────────────

extension DateTimeX on DateTime {
  /// Returns true if this and [other] are on the same calendar day.
  bool isSameDayAs(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Returns a new DateTime at midnight of this day.
  DateTime get dateOnly => DateTime(year, month, day);

  /// Returns true if this date is today.
  bool get isToday => isSameDayAs(DateTime.now());

  /// Returns true if this date is yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDayAs(yesterday);
  }
}

// ── String Extensions ─────────────────────────────────────────────────────

extension StringX on String {
  /// Capitalises the first character, leaves the rest alone.
  String get capitalised =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Trims and returns null if blank.
  String? get blankToNull {
    final t = trim();
    return t.isEmpty ? null : t;
  }

  /// Parses a hex color string like '#4F5FD3' into a Flutter Color.
  /// Falls back to AppColors.brand on any parse error.
  Color toColor() {
    try {
      return Color(int.parse('FF${replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.brand;
    }
  }
}

// ── int Extensions ────────────────────────────────────────────────────────

extension IntX on int {
  /// Formats an XP number with commas. E.g. 1234 → "1,234".
  String get xpFormatted {
    final s = toString();
    final buffer = StringBuffer();
    final start = s.length % 3;
    if (start > 0) buffer.write(s.substring(0, start));
    for (int i = start; i < s.length; i += 3) {
      if (i > 0) buffer.write(',');
      buffer.write(s.substring(i, i + 3));
    }
    return buffer.toString();
  }

  /// Ordinal suffix: 1 → "1st", 2 → "2nd", 3 → "3rd", 4 → "4th".
  String get ordinal {
    if (this >= 11 && this <= 13) return '${this}th';
    switch (this % 10) {
      case 1: return '${this}st';
      case 2: return '${this}nd';
      case 3: return '${this}rd';
      default: return '${this}th';
    }
  }
}

// ── double Extensions ─────────────────────────────────────────────────────

extension DoubleX on double {
  /// Formats as a percentage string. E.g. 0.876 → "88%".
  String get asPercent => '${(this * 100).round()}%';

  /// Formats as "87.6" with one decimal. Useful for scores.
  String get oneDecimal => toStringAsFixed(1);
}
