/// Date utility functions used throughout StreakIt.
///
/// All dates in the app are stored as UTC midnight (date-only).
/// This eliminates timezone edge cases when computing streaks.

abstract final class StreakDateUtils {
  /// Returns a [DateTime] representing the start of today (midnight, local).
  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Returns a [DateTime] for yesterday at midnight local.
  static DateTime yesterday() {
    final t = today();
    return t.subtract(const Duration(days: 1));
  }

  /// Strips time from a [DateTime], returning midnight of that day.
  static DateTime dateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// Returns true if [a] and [b] are on the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Number of calendar days between [from] and [to] (inclusive = false).
  static int daysBetween(DateTime from, DateTime to) {
    final f = dateOnly(from);
    final t = dateOnly(to);
    return t.difference(f).inDays;
  }

  /// Returns a list of [DateTime] (midnight) from [start] to [end] inclusive.
  static List<DateTime> dateRange(DateTime start, DateTime end) {
    final result = <DateTime>[];
    var current = dateOnly(start);
    final last = dateOnly(end);
    while (!current.isAfter(last)) {
      result.add(current);
      current = current.add(const Duration(days: 1));
    }
    return result;
  }

  /// Returns the start of the week (Monday) containing [date].
  static DateTime startOfWeek(DateTime date) {
    final d = dateOnly(date);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  /// Returns the start of the month containing [date].
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Short weekday label for a [weekday] integer (1=Mon, 7=Sun).
  static String shortWeekday(int weekday) {
    const labels = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[weekday.clamp(1, 7)];
  }

  /// Short month label from month integer (1–12).
  static String shortMonth(int month) {
    const labels = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return labels[month.clamp(1, 12)];
  }

  /// Full month label from month integer (1–12).
  static String fullMonth(int month) {
    const labels = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return labels[month.clamp(1, 12)];
  }

  /// Converts DateTime to ISO date string (YYYY-MM-DD).
  static String toIsoDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  /// Parses an ISO date string (YYYY-MM-DD) back to DateTime (midnight local).
  static DateTime fromIsoDate(String s) {
    final parts = s.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  /// Human-readable relative label: "Today", "Yesterday", "3 days ago", date.
  static String relativeLabel(DateTime date) {
    final t = today();
    final d = dateOnly(date);
    final diff = t.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${shortMonth(d.month)} ${d.day}';
  }
}
