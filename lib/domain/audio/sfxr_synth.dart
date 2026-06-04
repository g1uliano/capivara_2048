import 'dart:math';
import 'dart:typed_data';
import 'animal_voices.dart';
import 'sound_presets.dart';
import 'synth_core.dart';
import 'wav_utils.dart';

class SfxrSynth {
  static const _sampleRate = SynthCore.sampleRate;
  final _random = Random(42);

  Uint8List generate(SoundPreset preset) {
    final totalSamples = (preset.totalDuration * _sampleRate).round();
    final samples = Int16List(totalSamples);
    double phase = 0;

    for (int i = 0; i < totalSamples; i++) {
      final t = i / _sampleRate;
      final amplitude = _envelope(t, preset) * preset.volume;
      final freq = preset.baseFreq * exp(-preset.freqSweep * t);
      phase = (phase + freq / _sampleRate) % 1.0;

      double wave;
      if (preset.hasNoise) {
        final noise = _random.nextDouble() * 2 - 1;
        final sq = sin(2 * pi * phase) >= 0 ? 1.0 : -1.0;
        wave = noise * 0.45 + sq * 0.55;
      } else {
        wave = switch (preset.waveType) {
          WaveType.square => sin(2 * pi * phase) >= 0 ? 1.0 : -1.0,
          WaveType.triangle =>
            (2 / pi) * asin(sin(2 * pi * phase).clamp(-1.0, 1.0)),
          WaveType.sine => sin(2 * pi * phase),
        };
      }

      samples[i] = (wave * amplitude * 32767).clamp(-32767, 32767).round();
    }

    return buildWav(samples, sampleRate: _sampleRate);
  }

  Uint8List generateMerge(int level) {
    assert(level >= 1 && level <= 11);
    return AnimalVoices.mergePluck(level);
  }

  Uint8List generateUndo1() => _generateVhsRewind(
        duration: 0.55,
        startFreq: 600,
        peakFreq: 1500,
        endFreq: 400,
        volume: 0.55,
        seed: 11,
      );

  Uint8List generateUndo3() => _generateVhsRewind(
        duration: 1.0,
        startFreq: 650,
        peakFreq: 1950,
        endFreq: 380,
        volume: 0.7,
        seed: 23,
      );

  /// Rebobinar fita VHS: três camadas mixadas —
  /// (1) zunido do motor com contorno de pitch (acelera → platô com flutter →
  ///     desacelera) e warble ~23 Hz da rotação do carretel;
  /// (2) atrito da fita: ruído com filtro passa-banda acompanhando o zunido;
  /// (3) "clunk" mecânico curto no fim (mecanismo desengatando).
  Uint8List _generateVhsRewind({
    required double duration,
    required double startFreq,
    required double peakFreq,
    required double endFreq,
    required double volume,
    required int seed,
  }) {
    final total = (duration * _sampleRate).round();
    final samples = Int16List(total);

    const flutterRate = 23.0; // warble da rotação do carretel (Hz)
    double phase = 0, phase2 = 0;
    for (int i = 0; i < total; i++) {
      final t = i / _sampleRate;
      final p = i / total; // progresso normalizado 0..1

      // Contorno de pitch: acelera (0–0.15) → platô (0.15–0.8) → freia (0.8–1).
      double f;
      if (p < 0.15) {
        f = startFreq * pow(peakFreq / startFreq, p / 0.15).toDouble();
      } else if (p < 0.8) {
        f = peakFreq;
      } else {
        f = peakFreq * pow(endFreq / peakFreq, (p - 0.8) / 0.2).toDouble();
      }
      final freq = f * SynthCore.lfo(t, flutterRate, 0.05);
      phase = (phase + freq / _sampleRate) % 1.0;
      phase2 = (phase2 + (freq * 2.01) / _sampleRate) % 1.0;

      // Timbre: triângulo fundamental + leve quadrada (granulado do motor).
      final tri = (2 / pi) * asin(sin(2 * pi * phase).clamp(-1.0, 1.0));
      final sq = sin(2 * pi * phase2) >= 0 ? 1.0 : -1.0;
      final wave = tri * 0.8 + sq * 0.2;

      final attack = (t < 0.02) ? t / 0.02 : 1.0;
      final tail = (p > 0.85) ? ((1 - p) / 0.15).clamp(0.0, 1.0) : 1.0;
      final tremolo = SynthCore.lfo(t, flutterRate, 0.22);
      final amp = attack * tail * tremolo * volume;

      SynthCore.mix(samples, wave * amp * 13000, i);
    }

    // Camada 2 — atrito da fita: ruído passa-banda na faixa do zunido.
    SynthCore.filteredNoise(
      samples,
      0,
      total,
      filter: 'bandpass',
      cutoff: peakFreq * 1.6,
      resonance: 0.4,
      lfoRate: flutterRate,
      lfoDepth: 0.3,
      volume: 0.12 * volume,
      seed: seed,
    );

    // Camada 3 — clunk mecânico no fim (mecanismo parando).
    final clunkSamples = (0.05 * _sampleRate).round();
    SynthCore.tone(
      samples,
      total - clunkSamples,
      clunkSamples,
      startFreq: 90,
      endFreq: 55,
      a: 0.002,
      r: 0.04,
      volume: 0.35 * volume,
      waveType: 1,
    );

    return buildWav(samples, sampleRate: _sampleRate);
  }

  Uint8List generateVictory() {
    return _generateSequence(
      SoundPresets.victoryNotes,
      SoundPresets.victoryNoteDuration,
      WaveType.square,
      0.85,
    );
  }

  Uint8List generateGameOver() {
    return _generateSequence(
      SoundPresets.gameOverNotes,
      SoundPresets.gameOverNoteDuration,
      WaveType.triangle,
      0.65,
    );
  }

  Uint8List _generateSequence(
    List<double> freqs,
    double noteDuration,
    WaveType waveType,
    double volume,
  ) {
    final noteSamples = (noteDuration * _sampleRate).round();
    final total = Int16List(noteSamples * freqs.length);

    for (int n = 0; n < freqs.length; n++) {
      double phase = 0;
      final offset = n * noteSamples;
      for (int i = 0; i < noteSamples; i++) {
        final t = i / _sampleRate;
        final fadeIn = (t < 0.005) ? t / 0.005 : 1.0;
        final fadeOut =
            (i > noteSamples - 220) ? (noteSamples - i) / 220.0 : 1.0;
        final amp = fadeIn * fadeOut * volume;
        phase = (phase + freqs[n] / _sampleRate) % 1.0;
        final wave = switch (waveType) {
          WaveType.square => sin(2 * pi * phase) >= 0 ? 1.0 : -1.0,
          WaveType.triangle =>
            (2 / pi) * asin(sin(2 * pi * phase).clamp(-1.0, 1.0)),
          WaveType.sine => sin(2 * pi * phase),
        };
        total[offset + i] = (wave * amp * 32767).clamp(-32767, 32767).round();
      }
    }

    return buildWav(total, sampleRate: _sampleRate);
  }

  double _envelope(double t, SoundPreset p) {
    if (t < p.attack) return t / p.attack;
    if (t < p.attack + p.sustain) return 1.0;
    final dt = t - p.attack - p.sustain;
    return exp(-dt * 5 / p.decay).clamp(0.0, 1.0);
  }
}
