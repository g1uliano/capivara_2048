import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/audio/sfxr_synth.dart';
import 'package:capivara_2048/domain/audio/sound_presets.dart';
import 'package:capivara_2048/domain/audio/synth_core.dart';

void main() {
  late SfxrSynth synth;
  setUp(() => synth = SfxrSynth());

  int samplesOf(wav) => (wav.length - 44) ~/ 2;

  group('bomb sounds', () {
    test('bomb2x gera WAV válido com magic bytes RIFF/WAVE', () {
      final wav = synth.generate(SoundPresets.bomb2x);
      expect(wav.length, greaterThan(44));
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    });

    test('bomb3x é mais longo que bomb2x', () {
      expect(synth.generate(SoundPresets.bomb3x).length,
          greaterThan(synth.generate(SoundPresets.bomb2x).length));
    });

    test('bomb2x dura entre 0.3s e 0.6s', () {
      final ms = samplesOf(synth.generate(SoundPresets.bomb2x)) *
          1000 ~/
          SynthCore.sampleRate;
      expect(ms, greaterThanOrEqualTo(300));
      expect(ms, lessThanOrEqualTo(600));
    });
  });

  group('merge sounds', () {
    test('generateMerge produz WAV válido para todos os níveis', () {
      for (int level = 1; level <= 11; level++) {
        final wav = synth.generateMerge(level);
        expect(wav.length, greaterThan(44), reason: 'level $level');
        expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF',
            reason: 'level $level');
      }
    });
  });

  group('undo sounds', () {
    test('generateUndo1 e generateUndo3 geram WAV válido', () {
      for (final wav in [synth.generateUndo1(), synth.generateUndo3()]) {
        expect(wav.length, greaterThan(44));
        expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      }
    });

    test('undo3 é mais longo que undo1', () {
      expect(synth.generateUndo3().length,
          greaterThan(synth.generateUndo1().length));
    });
  });

  group('victory e game over', () {
    test('game over é mais longo que victory', () {
      expect(synth.generateGameOver().length,
          greaterThan(synth.generateVictory().length));
    });
  });
}
