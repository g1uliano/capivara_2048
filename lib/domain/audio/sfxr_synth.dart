import 'dart:math';
import 'dart:typed_data';
import 'sound_presets.dart';
import 'wav_utils.dart';

class SfxrSynth {
  static const _sampleRate = 22050;
  final _random = Random(42);

  Uint8List generate(SoundPreset preset) {
    final totalSamples = (preset.totalDuration * _sampleRate).round();
    final samples = Int16List(totalSamples);
    double phase = 0;

    for (int i = 0; i < totalSamples; i++) {
      final t = i / _sampleRate;
      final amplitude = _envelope(t, preset) * preset.volume;
      final freq = preset.baseFreq * exp(-preset.freqSweep * t);
      phase += freq / _sampleRate;

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

    return buildWav(samples);
  }

  Uint8List generateMerge(int level) {
    assert(level >= 1 && level <= 11);
    final freq = SoundPresets.mergePitches[level - 1];
    final preset = SoundPreset(
      waveType: WaveType.triangle,
      baseFreq: freq,
      attack: 0.01,
      sustain: 0.04,
      decay: 0.07,
      volume: 0.65,
    );
    return generate(preset);
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
        phase += freqs[n] / _sampleRate;
        final wave = switch (waveType) {
          WaveType.square => sin(2 * pi * phase) >= 0 ? 1.0 : -1.0,
          WaveType.triangle =>
            (2 / pi) * asin(sin(2 * pi * phase).clamp(-1.0, 1.0)),
          WaveType.sine => sin(2 * pi * phase),
        };
        total[offset + i] = (wave * amp * 32767).clamp(-32767, 32767).round();
      }
    }

    return buildWav(total);
  }

  double _envelope(double t, SoundPreset p) {
    if (t < p.attack) return t / p.attack;
    if (t < p.attack + p.sustain) return 1.0;
    final dt = t - p.attack - p.sustain;
    return exp(-dt * 5 / p.decay).clamp(0.0, 1.0);
  }
}
