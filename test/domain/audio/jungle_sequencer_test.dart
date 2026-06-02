import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/audio/jungle_sequencer.dart';
import 'package:capivara_2048/domain/audio/synth_core.dart';

void main() {
  group('JungleSequencer', () {
    test('generate retorna WAV válido', () async {
      final wav = await JungleSequencer.generate();
      expect(wav.length, greaterThan(44));
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    });

    test('duração está entre 80s e 90s', () async {
      final wav = await JungleSequencer.generate();
      final samples = (wav.length - 44) ~/ 2;
      final durationSec = samples / SynthCore.sampleRate;
      expect(durationSec, greaterThanOrEqualTo(80));
      expect(durationSec, lessThanOrEqualTo(90));
    });

    test('header declara sampleRate 32000', () async {
      final wav = await JungleSequencer.generate();
      final sr = wav[24] | (wav[25] << 8) | (wav[26] << 16) | (wav[27] << 24);
      expect(sr, SynthCore.sampleRate);
    });

    test('fim do loop não está clippando', () async {
      final wav = await JungleSequencer.generate();
      final data = wav.sublist(44);
      int clipped = 0;
      for (int i = data.length - 2000; i < data.length; i += 2) {
        final raw = (data[i + 1] << 8) | data[i];
        final signed = raw > 32767 ? raw - 65536 : raw;
        if (signed.abs() > 30000) clipped++;
      }
      expect(clipped, lessThan(50));
    });
  });
}
