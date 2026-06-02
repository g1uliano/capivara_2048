import 'dart:math';
import 'dart:typed_data';

/// Reusable pure-Dart DSP building blocks shared by music and SFX synthesis.
/// All audio modules reference [sampleRate] as the single source of truth.
class SynthCore {
  const SynthCore._();

  static const int sampleRate = 32000;

  /// ADSR envelope value at time [t] (seconds) for a note of [dur] seconds.
  static double adsr(
      double t, double dur, double a, double d, double s, double r) {
    if (t < a) return t / a;
    if (t < a + d) return 1.0 - (1.0 - s) * (t - a) / d;
    if (t < dur - r) return s;
    if (r > 0 && t < dur) return s * (dur - t) / r;
    return 0.0;
  }

  /// Low-frequency oscillator centered on 1.0, for vibrato/tremolo.
  static double lfo(double t, double rate, double depth) =>
      1.0 + depth * sin(2 * pi * rate * t);

  /// Adds [sample] into [target] at [index], clamping to Int16. No-op if OOB.
  static void mix(Int16List target, double sample, int index) {
    if (index < 0 || index >= target.length) return;
    target[index] =
        (target[index] + sample).clamp(-32767, 32767).round();
  }

  /// Renders an oscillator tone into [target] starting at [offset].
  /// Supports exponential pitch glide ([endFreq]) and vibrato.
  /// waveType: 0=sine, 1=square, 2=triangle.
  static void tone(
    Int16List target,
    int offset,
    int durationSamples, {
    required double startFreq,
    double endFreq = -1,
    double vibratoRate = 0,
    double vibratoDepth = 0,
    double a = 0.01,
    double d = 0.0,
    double s = 1.0,
    double r = 0.05,
    double volume = 0.5,
    int waveType = 0,
  }) {
    final freqEnd = endFreq < 0 ? startFreq : endFreq;
    final dur = durationSamples / sampleRate;
    double phase = 0;
    final end = (offset + durationSamples).clamp(0, target.length);
    for (int i = offset; i < end; i++) {
      final t = (i - offset) / sampleRate;
      final frac = durationSamples == 0 ? 0.0 : (i - offset) / durationSamples;
      final base = startFreq * pow(freqEnd / startFreq, frac).toDouble();
      final freq = base * lfo(t, vibratoRate, vibratoDepth);
      phase = (phase + freq / sampleRate) % 1.0;
      final w = switch (waveType) {
        1 => sin(2 * pi * phase) >= 0 ? 1.0 : -1.0,
        2 => (2 / pi) * asin(sin(2 * pi * phase).clamp(-1.0, 1.0)),
        _ => sin(2 * pi * phase),
      };
      final amp = adsr(t, dur, a, d, s, r) * volume;
      mix(target, w * amp * 16000, i);
    }
  }

  /// Karplus-Strong plucked string. Fills a delay line with noise and reads it
  /// in a loop through a 1-pole lowpass feedback — yields a nylon-guitar timbre.
  /// [brightness] = feedback gain (0.90–0.999). [damping] = lowpass blend (0–1).
  static void pluck(
    Int16List target,
    double freq,
    int offset,
    int durationSamples, {
    double brightness = 0.96,
    double damping = 0.5,
    double volume = 1.0,
    int seed = 0,
  }) {
    final n = (sampleRate / freq).round().clamp(2, sampleRate);
    final buf = Float64List(n);
    final rng = Random(seed);
    for (int i = 0; i < n; i++) {
      buf[i] = rng.nextDouble() * 2 - 1;
    }
    int idx = 0;
    double prev = 0;
    final end = (offset + durationSamples).clamp(0, target.length);
    for (int i = offset; i < end; i++) {
      final cur = buf[idx];
      final filtered = cur * (1 - damping) + prev * damping;
      buf[idx] = filtered * brightness;
      prev = filtered;
      final t = i - offset;
      final fadeOut =
          (t > durationSamples - 240) ? (durationSamples - t) / 240.0 : 1.0;
      mix(target, filtered * volume * fadeOut.clamp(0.0, 1.0) * 16000, i);
      idx = (idx + 1) % n;
    }
  }
}
