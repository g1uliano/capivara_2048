// test/domain/shop/share_codes_notifier_test.dart

import 'package:capivara_2048/data/models/share_code.dart';
import 'package:capivara_2048/data/models/shop_package.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShareCode JSON', () {
    test('toJson / fromJson são inversos', () {
      final original = ShareCode(
        code: 'abc-123',
        packageId: 'p1',
        giftContents: const RewardBundle(
          lives: 0, bomb2: 0, bomb3: 2, undo1: 0, undo3: 0,
        ),
        status: ShareCodeStatus.pending,
        createdAt: DateTime(2026, 5, 2, 12, 0),
      );

      final roundTripped = ShareCode.fromJson(original.toJson());

      expect(roundTripped.code, original.code);
      expect(roundTripped.packageId, original.packageId);
      expect(roundTripped.giftContents.bomb3, original.giftContents.bomb3);
      expect(roundTripped.status, original.status);
      expect(roundTripped.createdAt, original.createdAt);
    });
  });
}
