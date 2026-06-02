import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/audio/sfxr_synth.dart';
import 'package:capivara_2048/domain/audio/sound_presets.dart';

void main() {
  late SfxrSynth synth;
  setUp(() => synth = SfxrSynth());

  group('bomb sounds', () {
    test('bomb2x gera WAV válido com magic bytes RIFF/WAVE', () {
      final wav = synth.generate(SoundPresets.bomb2x);
      expect(wav.length, greaterThan(44));
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    });

    test('bomb3x é mais longo que bomb2x', () {
      final b2 = synth.generate(SoundPresets.bomb2x);
      final b3 = synth.generate(SoundPresets.bomb3x);
      expect(b3.length, greaterThan(b2.length));
    });

    test('bomb2x dura entre 0.3s e 0.6s', () {
      final wav = synth.generate(SoundPresets.bomb2x);
      // 44-byte header, 2 bytes/sample, 22050Hz
      final samples = (wav.length - 44) ~/ 2;
      final durationMs = samples * 1000 ~/ 22050;
      expect(durationMs, greaterThanOrEqualTo(300));
      expect(durationMs, lessThanOrEqualTo(600));
    });

    test('bomb3x dura entre 0.5s e 0.9s', () {
      final wav = synth.generate(SoundPresets.bomb3x);
      final samples = (wav.length - 44) ~/ 2;
      final durationMs = samples * 1000 ~/ 22050;
      expect(durationMs, greaterThanOrEqualTo(500));
      expect(durationMs, lessThanOrEqualTo(900));
    });
  });

  group('merge sounds', () {
    test('generateMerge produz WAV válido para todos os níveis', () {
      for (int level = 1; level <= 11; level++) {
        final wav = synth.generateMerge(level);
        expect(wav.length, greaterThan(44), reason: 'level $level');
        expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF', reason: 'level $level');
      }
    });

    test('todos os níveis têm mesma duração', () {
      final lengths = List.generate(11, (i) => synth.generateMerge(i + 1).length);
      expect(lengths.every((l) => l == lengths[0]), isTrue);
    });
  });

  group('victory e game over', () {
    test('generateVictory retorna WAV com 4 notas de ~0.13s', () {
      final wav = synth.generateVictory();
      final samples = (wav.length - 44) ~/ 2;
      final expectedSamples = (4 * 0.13 * 22050).round();
      expect(samples, closeTo(expectedSamples, 50));
    });

    test('generateGameOver retorna WAV com 3 notas de ~0.28s', () {
      final wav = synth.generateGameOver();
      final samples = (wav.length - 44) ~/ 2;
      final expectedSamples = (3 * 0.28 * 22050).round();
      expect(samples, closeTo(expectedSamples, 50));
    });

    test('game over é mais longo que victory', () {
      expect(synth.generateGameOver().length, greaterThan(synth.generateVictory().length));
    });
  });
}
