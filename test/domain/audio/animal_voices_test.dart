import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/audio/animal_voices.dart';
import 'package:capivara_2048/domain/audio/synth_core.dart';

void main() {
  group('mergePluck', () {
    test('gera WAV válido com sampleRate correto p/ todos os níveis', () {
      for (int level = 1; level <= 11; level++) {
        final wav = AnimalVoices.mergePluck(level);
        expect(wav.length, greaterThan(44), reason: 'level $level');
        expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF',
            reason: 'level $level');
        // header sampleRate (bytes 24-27, little endian) == 32000
        final sr = wav[24] | (wav[25] << 8) | (wav[26] << 16) | (wav[27] << 24);
        expect(sr, SynthCore.sampleRate, reason: 'level $level');
      }
    });
  });

  group('voice', () {
    test('produz WAV válido p/ todos os níveis (inclui chime e especial)', () {
      for (int level = 1; level <= 11; level++) {
        final wav = AnimalVoices.voice(level);
        expect(wav.length, greaterThan(44), reason: 'level $level');
        expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF',
            reason: 'level $level');
      }
    });

    test('capivara (11) é a mais longa', () {
      final capivara = AnimalVoices.voice(11).length;
      for (int level = 1; level <= 10; level++) {
        expect(capivara, greaterThan(AnimalVoices.voice(level).length),
            reason: 'level $level');
      }
    });
  });

  group('voiceSamples', () {
    test('retorna buffer sem header WAV', () {
      final samples = AnimalVoices.voiceSamples(3);
      expect(samples.length, greaterThan(0));
    });
  });
}
