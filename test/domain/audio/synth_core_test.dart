import 'dart:math';
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
    test('decay desce de 1 a s', () {
      // t=0.15 is midpoint of decay [0.1, 0.2], should be 0.75
      expect(SynthCore.adsr(0.15, 1.0, 0.1, 0.1, 0.5, 0.2), closeTo(0.75, 1e-9));
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
    test('square e triangle não produzem NaN nem clipping', () {
      for (final wt in [1, 2]) {
        final buf = Int16List(SynthCore.sampleRate ~/ 10);
        SynthCore.tone(buf, 0, buf.length, startFreq: 440, volume: 0.5, waveType: wt);
        expect(buf.every((s) => s.abs() <= 32767), isTrue, reason: 'waveType $wt');
        expect(buf.any((s) => s.abs() > 100), isTrue, reason: 'waveType $wt has signal');
      }
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

  group('filteredNoise', () {
    int zeroCrossings(Int16List buf) {
      int c = 0;
      for (int i = 1; i < buf.length; i++) {
        if ((buf[i - 1] < 0) != (buf[i] < 0)) c++;
      }
      return c;
    }

    test('preenche buffer no range e respeita tamanho', () {
      final n = SynthCore.sampleRate ~/ 5;
      final buf = Int16List(n);
      SynthCore.filteredNoise(buf, 0, n, cutoff: 600, volume: 0.4);
      expect(buf.any((s) => s.abs() > 50), isTrue);
      expect(buf.every((s) => s.abs() <= 32767), isTrue);
    });

    test('lowpass tem menos zero-crossings que bandpass alto', () {
      final n = SynthCore.sampleRate ~/ 2;
      final low = Int16List(n);
      final band = Int16List(n);
      SynthCore.filteredNoise(low, 0, n,
          filter: 'lowpass', cutoff: 400, volume: 0.5, seed: 3);
      SynthCore.filteredNoise(band, 0, n,
          filter: 'bandpass', cutoff: 6000, volume: 0.5, seed: 3);
      expect(zeroCrossings(low), lessThan(zeroCrossings(band)));
    });
  });

  group('pluck (Karplus-Strong)', () {
    double rms(Int16List buf, int from, int to) {
      double sum = 0;
      for (int i = from; i < to; i++) {
        sum += buf[i] * buf[i].toDouble();
      }
      return sqrt(sum / (to - from));
    }

    test('produz som que decai ao longo do tempo', () {
      final n = SynthCore.sampleRate ~/ 2; // 0.5s
      final buf = Int16List(n);
      SynthCore.pluck(buf, 220, 0, n, volume: 0.8);
      final early = rms(buf, 0, n ~/ 4);
      final late = rms(buf, 3 * n ~/ 4, n);
      expect(early, greaterThan(0));
      expect(late, lessThan(early), reason: 'corda deve decair');
    });

    test('não estoura Int16 e respeita o tamanho', () {
      final n = SynthCore.sampleRate ~/ 4;
      final buf = Int16List(n);
      SynthCore.pluck(buf, 440, 0, n);
      expect(buf.every((s) => s.abs() <= 32767), isTrue);
    });
  });
}
