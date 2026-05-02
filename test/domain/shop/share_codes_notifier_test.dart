// test/domain/shop/share_codes_notifier_test.dart

import 'package:capivara_2048/data/models/share_code.dart';
import 'package:capivara_2048/data/models/shop_package.dart';
import 'package:capivara_2048/data/repositories/share_codes_repository.dart';
import 'package:capivara_2048/domain/shop/share_codes_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

      expect(roundTripped, original);
    });

    test('copyWith changes only specified fields', () {
      final original = ShareCode(
        code: 'aaa',
        packageId: 'p1',
        giftContents: RewardBundle(lives: 1, bomb2: 0, bomb3: 0, undo1: 0, undo3: 0),
        status: ShareCodeStatus.pending,
        createdAt: DateTime.utc(2026, 5, 2),
      );
      final copy = original.copyWith(code: 'bbb');
      expect(copy.code, 'bbb');
      expect(copy.packageId, original.packageId);
      expect(copy.status, original.status);
      expect(copy.giftContents, original.giftContents);
    });
  });

  group('ShareCodesNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('add() appenda código e persiste na lista', () async {
      final container = ProviderContainer(overrides: [
        shareCodesRepositoryProvider
            .overrideWithValue(ShareCodesRepository()),
      ]);
      addTearDown(container.dispose);

      final code = ShareCode(
        code: 'test-code-0001',
        packageId: 'p1',
        giftContents: const RewardBundle(
          lives: 0, bomb2: 0, bomb3: 2, undo1: 0, undo3: 0,
        ),
        status: ShareCodeStatus.pending,
        createdAt: DateTime(2026, 5, 2),
      );

      await container.read(shareCodesProvider.notifier).add(code);
      expect(container.read(shareCodesProvider).length, 1);
      expect(container.read(shareCodesProvider).first.code, 'test-code-0001');
    });

    test('load() restaura lista após reinício simulado', () async {
      final repo = ShareCodesRepository();
      final code = ShareCode(
        code: 'persist-test',
        packageId: 'p2',
        giftContents: const RewardBundle(
          lives: 0, bomb2: 0, bomb3: 0, undo1: 0, undo3: 2,
        ),
        status: ShareCodeStatus.pending,
        createdAt: DateTime(2026, 5, 2),
      );
      await repo.save([code]);

      final container = ProviderContainer(overrides: [
        shareCodesRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await container.read(shareCodesProvider.notifier).load();
      expect(container.read(shareCodesProvider).length, 1);
      expect(container.read(shareCodesProvider).first.code, 'persist-test');
    });
  });
}
