import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/audio/audio_service.dart';
import 'package:capivara_2048/domain/audio/audio_service_stub.dart';

void main() {
  group('AudioServiceStub', () {
    late AudioService stub;

    setUp(() => stub = AudioServiceStub());

    test('init completes without error', () async {
      await expectLater(stub.init(), completes);
    });

    test('playEffect does not throw for any event', () {
      expect(() => stub.playEffect(const Bomb2xUsed()), returnsNormally);
      expect(() => stub.playEffect(const Bomb3xUsed()), returnsNormally);
      expect(() => stub.playEffect(const TilesMerged(5)), returnsNormally);
      expect(() => stub.playEffect(const AnimalReached(8)), returnsNormally);
      expect(() => stub.playEffect(const Undo1Used()), returnsNormally);
      expect(() => stub.playEffect(const Undo3Used()), returnsNormally);
      expect(() => stub.playEffect(const VictoryReached()), returnsNormally);
      expect(() => stub.playEffect(const GameOver()), returnsNormally);
    });

    test('sfx volume and enabled do not throw', () {
      expect(() => stub.setSfxVolume(0.5), returnsNormally);
      expect(() => stub.setSfxEnabled(false), returnsNormally);
    });
  });
}
