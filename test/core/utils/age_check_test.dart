import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/core/utils/age_check.dart';

void main() {
  group('isAtLeast12', () {
    final birth = DateTime(2014, 6, 15);

    test('day before 12th birthday → false', () {
      expect(isAtLeast12(birth, DateTime(2026, 6, 14)), isFalse);
    });
    test('on 12th birthday → true', () {
      expect(isAtLeast12(birth, DateTime(2026, 6, 15)), isTrue);
    });
    test('day after 12th birthday → true', () {
      expect(isAtLeast12(birth, DateTime(2026, 6, 16)), isTrue);
    });
    test('much younger → false', () {
      expect(isAtLeast12(DateTime(2020, 1, 1), DateTime(2026, 6, 14)), isFalse);
    });
    test('much older → true', () {
      expect(isAtLeast12(DateTime(1990, 1, 1), DateTime(2026, 6, 14)), isTrue);
    });
    test('Feb 29 birth → exact 12th birthday is valid Feb 29', () {
      final leapBirth = DateTime(2008, 2, 29); // 2008 e 2020 são bissextos
      expect(isAtLeast12(leapBirth, DateTime(2020, 2, 29)), isTrue);
      expect(isAtLeast12(leapBirth, DateTime(2020, 2, 28)), isFalse);
    });
  });

  group('daysInMonth', () {
    test('February common year', () => expect(daysInMonth(2025, 2), 28));
    test('February leap year', () => expect(daysInMonth(2024, 2), 29));
    test('30-day month (April)', () => expect(daysInMonth(2025, 4), 30));
    test('31-day month (January)', () => expect(daysInMonth(2025, 1), 31));
  });
}
