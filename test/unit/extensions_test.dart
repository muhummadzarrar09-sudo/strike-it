import 'package:flutter_test/flutter_test.dart';
import 'package:streak_it/core/utils/extensions.dart';

void main() {
  group('StringX extensions', () {
    test('capitalised capitalises first char', () {
      expect('hello world'.capitalised, 'Hello world');
    });

    test('capitalised on empty string returns empty', () {
      expect(''.capitalised, '');
    });

    test('capitalised on already-capitalised string is stable', () {
      expect('Hello'.capitalised, 'Hello');
    });

    test('blankToNull on blank string returns null', () {
      expect('   '.blankToNull, null);
    });

    test('blankToNull on empty string returns null', () {
      expect(''.blankToNull, null);
    });

    test('blankToNull on non-blank string returns trimmed string', () {
      expect('  hello  '.blankToNull, 'hello');
    });
  });

  group('IntX extensions', () {
    test('xpFormatted formats small numbers without commas', () {
      expect(0.xpFormatted, '0');
      expect(999.xpFormatted, '999');
    });

    test('xpFormatted formats 1000 with comma', () {
      expect(1000.xpFormatted, '1,000');
    });

    test('xpFormatted formats large numbers', () {
      expect(1234567.xpFormatted, '1,234,567');
    });

    test('ordinal: 1st, 2nd, 3rd, 4th', () {
      expect(1.ordinal, '1st');
      expect(2.ordinal, '2nd');
      expect(3.ordinal, '3rd');
      expect(4.ordinal, '4th');
      expect(11.ordinal, '11th');
      expect(12.ordinal, '12th');
      expect(13.ordinal, '13th');
      expect(21.ordinal, '21st');
      expect(22.ordinal, '22nd');
      expect(23.ordinal, '23rd');
    });
  });

  group('DoubleX extensions', () {
    test('asPercent converts 0.876 → "88%"', () {
      expect(0.876.asPercent, '88%');
    });

    test('asPercent 0.0 → "0%"', () {
      expect(0.0.asPercent, '0%');
    });

    test('asPercent 1.0 → "100%"', () {
      expect(1.0.asPercent, '100%');
    });

    test('oneDecimal formats correctly', () {
      expect(3.14159.oneDecimal, '3.1');
      expect(0.0.oneDecimal, '0.0');
      expect(100.0.oneDecimal, '100.0');
    });
  });

  group('DateTimeX extensions', () {
    test('isToday returns true for now', () {
      expect(DateTime.now().isToday, true);
    });

    test('isToday returns false for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(yesterday.isToday, false);
    });

    test('isYesterday returns true for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(yesterday.isYesterday, true);
    });

    test('isYesterday returns false for today', () {
      expect(DateTime.now().isYesterday, false);
    });

    test('dateOnly strips time', () {
      final dt = DateTime(2025, 6, 15, 12, 30, 45);
      expect(dt.dateOnly, DateTime(2025, 6, 15));
    });

    test('isSameDayAs: true for same day', () {
      final a = DateTime(2025, 3, 10, 8, 0);
      final b = DateTime(2025, 3, 10, 22, 0);
      expect(a.isSameDayAs(b), true);
    });

    test('isSameDayAs: false for different days', () {
      expect(
        DateTime(2025, 3, 10).isSameDayAs(DateTime(2025, 3, 11)),
        false,
      );
    });
  });
}
