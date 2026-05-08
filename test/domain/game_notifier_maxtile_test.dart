import 'package:flutter_test/flutter_test.dart';

// Unit test for the maxTile computation used in ranking submission.
// The formula: maxTile = 1 << maxLevel (bitshift, same as 2^maxLevel)
void main() {
  group('maxTile computation from maxLevel', () {
    test('level 11 → tile 2048', () {
      expect(1 << 11, 2048);
    });

    test('level 12 → tile 4096', () {
      expect(1 << 12, 4096);
    });

    test('level 13 → tile 8192', () {
      expect(1 << 13, 8192);
    });

    test('level 0 guard → null (not computed)', () {
      // game_notifier uses: maxLevel > 0 ? (1 << maxLevel) : null
      final maxLevel = 0;
      final result = maxLevel > 0 ? (1 << maxLevel) : null;
      expect(result, isNull);
    });
  });
}
