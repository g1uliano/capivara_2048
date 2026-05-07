import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/sync/sync_engine.dart';
import 'package:capivara_2048/data/models/game_record.dart';

void main() {
  late FakeSyncEngine sut;

  setUp(() => sut = FakeSyncEngine());

  group('FakeSyncEngine — novos métodos', () {
    test('deleteUserData completa sem lançar', () async {
      await expectLater(sut.deleteUserData(), completes);
    });

    test('updateDisplayName completa sem lançar', () async {
      await expectLater(sut.updateDisplayName('Nome'), completes);
    });

    test('syncGameRecord completa sem lançar', () async {
      final record = GameRecord(
        playedAt: DateTime(2025),
        elapsedMs: 60000,
        score: 1234,
        maxLevel: 5,
      );
      await expectLater(sut.syncGameRecord(record), completes);
    });

    test('remoteAvatarUrl retorna null por padrão', () {
      expect(sut.remoteAvatarUrl, isNull);
    });
  });
}
