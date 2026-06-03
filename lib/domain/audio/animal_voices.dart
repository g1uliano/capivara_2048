import 'dart:math';
import 'dart:typed_data';
import 'sound_presets.dart';
import 'synth_core.dart';
import 'wav_utils.dart';

/// Synthesizes per-animal voices and the warm merge pluck.
/// Level→animal mapping is fixed (see plan/spec table).
class AnimalVoices {
  const AnimalVoices._();

  static const _sr = SynthCore.sampleRate;

  /// Warm nylon pluck tuned by level — played on EVERY merge (subtle).
  static Uint8List mergePluck(int level) {
    final freq = SoundPresets.mergePitches[level - 1];
    final dur = (0.18 * _sr).round();
    final buf = Int16List(dur);
    SynthCore.pluck(buf, freq, 0, dur,
        brightness: 0.95, damping: 0.4, volume: 0.6);
    _edgeFade(buf);
    return buildWav(buf, sampleRate: _sr);
  }

  /// Animal voice WAV — played only when the player reaches that animal anew.
  static Uint8List voice(int level) => buildWav(
        switch (level) {
          1 => _cigarra(),
          3 => _sapo(),
          4 => _tucano(),
          5 => _sagui(),
          8 => _boto(),
          10 => _sucuri(),
          11 => _capivara(),
          _ => _chime(level), // 2, 6, 7, 9 (difíceis)
        },
        sampleRate: _sr,
      );

  static Int16List _cigarra() {
    final n = (0.5 * _sr).round();
    final buf = Int16List(n);
    SynthCore.filteredNoise(buf, 0, n,
        filter: 'bandpass', cutoff: 4000, resonance: 0.8, volume: 0.5, seed: 1);
    _tremolo(buf, 18);
    _edgeFade(buf);
    return buf;
  }

  static Int16List _sapo() {
    final n = (0.6 * _sr).round();
    final buf = Int16List(n);
    final burst = (0.18 * _sr).round();
    for (final start in [0, (0.30 * _sr).round()]) {
      SynthCore.tone(buf, start, burst,
          startFreq: 130, endFreq: 110, waveType: 1, a: 0.02, r: 0.05,
          volume: 0.5);
    }
    _tremolo(buf, 28);
    _edgeFade(buf);
    return buf;
  }

  static Int16List _tucano() {
    final n = (0.4 * _sr).round();
    final buf = Int16List(n);
    final chirp = (0.10 * _sr).round();
    for (final start in [0, (0.18 * _sr).round()]) {
      SynthCore.tone(buf, start, chirp,
          startFreq: 900, endFreq: 1600, a: 0.005, r: 0.03, volume: 0.45);
    }
    _edgeFade(buf);
    return buf;
  }

  static Int16List _sagui() {
    final n = (0.45 * _sr).round();
    final buf = Int16List(n);
    SynthCore.tone(buf, 0, n,
        startFreq: 5000, endFreq: 6000, vibratoRate: 35, vibratoDepth: 0.06,
        a: 0.01, r: 0.05, volume: 0.35);
    _tremolo(buf, 30);
    _edgeFade(buf);
    return buf;
  }

  static Int16List _boto() {
    final n = (0.55 * _sr).round();
    final buf = Int16List(n);
    SynthCore.tone(buf, 0, (0.4 * _sr).round(),
        startFreq: 800, endFreq: 2600, a: 0.02, r: 0.08, volume: 0.4);
    final rng = Random(8);
    for (int k = 0; k < 6; k++) {
      final at = (0.42 * _sr).round() + (k * 0.018 * _sr).round();
      SynthCore.tone(buf, at, (0.006 * _sr).round(),
          startFreq: 2000 + rng.nextDouble() * 800, a: 0.001, r: 0.002,
          volume: 0.3);
    }
    _edgeFade(buf);
    return buf;
  }

  static Int16List _sucuri() {
    final n = (0.6 * _sr).round();
    final buf = Int16List(n);
    SynthCore.filteredNoise(buf, 0, n,
        filter: 'bandpass', cutoff: 6000, resonance: 0.3, volume: 0.5,
        seed: 10);
    _swell(buf);
    _edgeFade(buf);
    return buf;
  }

  static Int16List _capivara() {
    final n = (1.0 * _sr).round();
    final buf = Int16List(n);
    SynthCore.tone(buf, 0, (0.5 * _sr).round(),
        startFreq: 180, endFreq: 220, waveType: 2, a: 0.03, r: 0.1,
        volume: 0.4);
    const arp = [261.63, 329.63, 392.0, 523.25]; // C E G C
    for (int k = 0; k < arp.length; k++) {
      final at = (0.45 * _sr).round() + (k * 0.12 * _sr).round();
      SynthCore.pluck(buf, arp[k], at, (0.4 * _sr).round(),
          brightness: 0.96, damping: 0.35, volume: 0.5);
    }
    _edgeFade(buf);
    return buf;
  }

  static Int16List _chime(int level) {
    final n = (0.5 * _sr).round();
    final buf = Int16List(n);
    final base = SoundPresets.mergePitches[level - 1];
    SynthCore.tone(buf, 0, n,
        startFreq: base, a: 0.005, d: 0.1, s: 0.4, r: 0.2, volume: 0.35);
    SynthCore.tone(buf, 0, n,
        startFreq: base * 1.5, a: 0.005, d: 0.1, s: 0.3, r: 0.2, volume: 0.2);
    SynthCore.tone(buf, 0, n,
        startFreq: base * 2, a: 0.005, d: 0.1, s: 0.25, r: 0.2, volume: 0.15);
    _edgeFade(buf);
    return buf;
  }

  static void _edgeFade(Int16List buf, {int len = 240}) {
    final n = buf.length;
    for (int i = 0; i < len && i < n; i++) {
      final g = i / len;
      buf[i] = (buf[i] * g).round();
      buf[n - 1 - i] = (buf[n - 1 - i] * g).round();
    }
  }

  static void _tremolo(Int16List buf, double rate, {double depth = 0.5}) {
    for (int i = 0; i < buf.length; i++) {
      final t = i / _sr;
      final g = 1 - depth + depth * (0.5 + 0.5 * sin(2 * pi * rate * t));
      buf[i] = (buf[i] * g).round();
    }
  }

  static void _swell(Int16List buf) {
    final n = buf.length;
    for (int i = 0; i < n; i++) {
      buf[i] = (buf[i] * sin(pi * i / n)).round();
    }
  }
}
