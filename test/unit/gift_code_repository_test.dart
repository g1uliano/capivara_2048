// test/unit/gift_code_repository_test.dart

import 'package:test/test.dart';
import 'package:capivara_2048/data/repositories/gift_code_repository.dart';

void main() {
  group('validateGiftCode', () {
    final now = DateTime(2026, 5, 15);
    final recentDate = DateTime(2026, 5, 10);
    const userId = 'user_abc';
    const otherUserId = 'user_xyz';

    test('returns null for valid pending code', () {
      expect(
        validateGiftCode(
          status: 'pending',
          createdBy: otherUserId,
          createdAt: recentDate,
          userId: userId,
          now: now,
        ),
        isNull,
      );
    });

    test('returns alreadyRedeemed when status is redeemed', () {
      expect(
        validateGiftCode(
          status: 'redeemed',
          createdBy: otherUserId,
          createdAt: recentDate,
          userId: userId,
          now: now,
        ),
        RedeemError.alreadyRedeemed,
      );
    });

    test('returns ownCode when createdBy matches userId', () {
      expect(
        validateGiftCode(
          status: 'pending',
          createdBy: userId,
          createdAt: recentDate,
          userId: userId,
          now: now,
        ),
        RedeemError.ownCode,
      );
    });

    test('returns expired when code is older than 30 days', () {
      final oldDate = DateTime(2026, 4, 14); // 31 days before now
      expect(
        validateGiftCode(
          status: 'pending',
          createdBy: otherUserId,
          createdAt: oldDate,
          userId: userId,
          now: now,
        ),
        RedeemError.expired,
      );
    });

    test('returns null for code exactly 30 days old', () {
      final thirtyDaysAgo = DateTime(2026, 4, 15); // exactly 30 days
      expect(
        validateGiftCode(
          status: 'pending',
          createdBy: otherUserId,
          createdAt: thirtyDaysAgo,
          userId: userId,
          now: now,
        ),
        isNull,
      );
    });

    test('returns null for code 29 days old', () {
      final twentyNineDaysAgo = DateTime(2026, 4, 16); // 29 days before now
      expect(
        validateGiftCode(
          status: 'pending',
          createdBy: otherUserId,
          createdAt: twentyNineDaysAgo,
          userId: userId,
          now: now,
        ),
        isNull,
      );
    });

    test('alreadyRedeemed takes priority over ownCode', () {
      expect(
        validateGiftCode(
          status: 'redeemed',
          createdBy: userId,
          createdAt: recentDate,
          userId: userId,
          now: now,
        ),
        RedeemError.alreadyRedeemed,
      );
    });
  });
}
