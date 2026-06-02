import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/audio/synth_core.dart';

void main() {
  group('SynthCore.sampleRate', () {
    test('é 32000', () => expect(SynthCore.sampleRate, 32000));
  });

  group('adsr', () {
    test('attack sobe de 0 a 1', () {
      expect(SynthCore.adsr(0, 1.0, 0.1, 0.1, 0.5, 0.2), 0.0);
      expect(SynthCore.adsr(0.1, 1.0, 0.1, 0.1, 0.5, 0.2), closeTo(1.0, 1e-9));
    });
    test('sustain mantém nível s', () {
      expect(SynthCore.adsr(0.5, 1.0, 0.1, 0.1, 0.5, 0.2), closeTo(0.5, 1e-9));
    });
    test('após a duração retorna 0', () {
      expect(SynthCore.adsr(1.0, 1.0, 0.1, 0.1, 0.5, 0.2), 0.0);
      expect(SynthCore.adsr(2.0, 1.0, 0.1, 0.1, 0.5, 0.2), 0.0);
    });
  });

  group('lfo', () {
    test('oscila em torno de 1.0', () {
      expect(SynthCore.lfo(0, 1, 0.5), closeTo(1.0, 1e-9));
      expect(SynthCore.lfo(0.25, 1, 0.5), closeTo(1.5, 1e-9));
    });
  });

  group('tone', () {
    test('preenche o buffer com áudio sem clipping', () {
      final buf = Int16List(SynthCore.sampleRate ~/ 10); // 0.1s
      SynthCore.tone(buf, 0, buf.length, startFreq: 440, volume: 0.5);
      final hasSignal = buf.any((s) => s.abs() > 100);
      expect(hasSignal, isTrue);
      expect(buf.every((s) => s.abs() <= 32767), isTrue);
    });
  });

  group('mix', () {
    test('soma com clamp e ignora índices fora do buffer', () {
      final buf = Int16List(4);
      SynthCore.mix(buf, 10000, 1);
      SynthCore.mix(buf, 10000, 1);
      expect(buf[1], 20000);
      SynthCore.mix(buf, 40000, 1);
      expect(buf[1], 32767); // clamp
      expect(() => SynthCore.mix(buf, 1000, 99), returnsNormally);
    });
  });
}
