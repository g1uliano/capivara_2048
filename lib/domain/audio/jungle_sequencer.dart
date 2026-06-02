import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'wav_utils.dart';

/// Generates an 85-second MPB/Bossa Nova chiptune loop as a WAV file.
/// Structure: 32 bars × 4 beats at 90 BPM = 85.3s
/// Sections: A (bars 0–7) | B (bars 8–15) | C respite (bars 16–23) | A' with counter (bars 24–31)
class JungleSequencer {
  static const _sampleRate = 22050;
  static const _bpm = 90.0;
  static const _beatsPerBar = 4;
  static const _totalBars = 32;

  // 22050 * 60 / 90 = 14700 samples per beat
  static int get _spb => (_sampleRate * 60 / _bpm).round();

  static double _midi(int n) => 440.0 * pow(2, (n - 69) / 12);

  static Future<Uint8List> generate() => Isolate.run(_renderLoop);

  static Uint8List _renderLoop() {
    final totalSamples = _totalBars * _beatsPerBar * _spb;
    final out = Int16List(totalSamples);

    _renderVoice(out, _melodyVoice());
    _renderVoice(out, _bassVoice());
    _renderVoice(out, _batidaVoice());
    _renderVoice(out, _counterVoice());

    _normalize(out);

    return buildWav(out);
  }

  // ---------------------------------------------------------------------------
  // Melody voice — section A (bars 0–7) and A' (bars 24–31)
  // Section B (bars 8–15) silent, Section C (bars 16–23) also has melody
  // ---------------------------------------------------------------------------
  static List<_Note> _melodyVoice() {
    // Section A: 8 bars = 32 beats
    const melA = [
      (62, 1.0), (69, 0.5), (67, 0.5), (66, 1.0), (64, 1.0),
      (62, 2.0), (0, 1.0), (64, 1.0),
      (66, 1.5), (67, 0.5), (69, 1.0), (71, 1.0),
      (69, 2.0), (0, 2.0),
      (67, 1.0), (69, 0.5), (71, 0.5), (73, 1.0), (71, 1.0),
      (69, 2.0), (0, 1.0), (67, 1.0),
      (66, 1.5), (64, 0.5), (62, 1.0), (64, 1.0),
      (62, 3.0), (0, 1.0),
      (64, 1.0), (66, 0.5), (67, 0.5), (69, 1.0), (67, 1.0),
      (66, 2.0), (0, 1.0), (64, 1.0),
      (62, 1.5), (64, 0.5), (66, 1.0), (64, 1.0),
      (62, 3.0), (0, 1.0),
      (69, 1.0), (71, 0.5), (73, 0.5), (74, 1.0), (73, 1.0),
      (71, 2.0), (0, 1.0), (69, 1.0),
      (67, 1.5), (66, 0.5), (64, 1.0), (62, 1.0),
      (62, 4.0),
    ];

    // Section B (bars 8–15): melody rests, counter voice plays instead
    const silentB = [(0, 32.0)]; // 8 bars × 4 beats

    // Section C (bars 16–23): variant melody
    const melC = [
      (74, 1.0), (73, 0.5), (71, 0.5), (69, 1.0), (67, 1.0),
      (66, 2.0), (0, 1.0), (64, 1.0),
      (66, 1.5), (67, 0.5), (69, 1.0), (71, 1.0),
      (73, 2.0), (0, 2.0),
      (71, 1.0), (69, 0.5), (67, 0.5), (66, 1.0), (64, 1.0),
      (62, 2.0), (0, 1.0), (64, 1.0),
      (66, 1.5), (69, 0.5), (71, 1.0), (73, 1.0),
      (74, 3.0), (0, 1.0),
      (73, 1.0), (71, 0.5), (69, 0.5), (67, 1.0), (66, 1.0),
      (64, 2.0), (0, 1.0), (62, 1.0),
      (64, 1.5), (66, 0.5), (67, 1.0), (66, 1.0),
      (64, 2.0), (0, 2.0),
      (62, 1.0), (64, 0.5), (66, 0.5), (67, 1.0), (69, 1.0),
      (71, 2.0), (73, 1.0), (74, 1.0),
      (76, 4.0),
    ];

    final notes = <_Note>[];
    int offset = 0;
    for (final patterns in [melA, silentB, melC, melA]) {
      for (final (midi, beats) in patterns) {
        final dur = (beats * _spb).round();
        if (midi > 0) {
          notes.add(_Note(_midi(midi), offset, dur, 1, 0.75));
        }
        offset += dur;
      }
    }
    return notes;
  }

  // ---------------------------------------------------------------------------
  // Bass voice — root + fifth pattern, one per bar (32 bars)
  // ---------------------------------------------------------------------------
  static List<_Note> _bassVoice() {
    const allBarRoots = [
      // Section A (bars 0–7)
      38, 40, 45, 38, 43, 41, 47, 40,
      // Section B (bars 8–15)
      40, 39, 38, 47, 40, 45, 38, 45,
      // Section C (bars 16–23)
      43, 44, 38, 40, 42, 47, 40, 39,
      // Section A' (bars 24–31)
      38, 40, 45, 38, 43, 41, 47, 40,
    ];

    final notes = <_Note>[];
    for (int bar = 0; bar < _totalBars; bar++) {
      final barStart = bar * _beatsPerBar * _spb;
      final root = allBarRoots[bar];
      notes.add(_Note(_midi(root), barStart, _spb - 150, 0, 0.70));
      notes.add(_Note(_midi(root + 7), barStart + 2 * _spb, _spb - 150, 0, 0.55));
    }
    return notes;
  }

  // ---------------------------------------------------------------------------
  // Batida (chord strumming) — bossa nova rhythmic pattern
  // ---------------------------------------------------------------------------
  static List<_Note> _batidaVoice() {
    const batidaPattern = [1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0];
    final sixteenth = _spb ~/ 4;

    const allBarVoicings = [
      // Section A (bars 0–7)
      [66, 69], [64, 67], [64, 67], [66, 69],
      [71, 74], [65, 69], [66, 69], [64, 68],
      // Section B (bars 8–15)
      [64, 67], [63, 66], [66, 69], [62, 66],
      [64, 67], [64, 67], [66, 69], [64, 67],
      // Section C (bars 16–23)
      [71, 74], [68, 71], [66, 69], [64, 68],
      [66, 69], [66, 69], [64, 67], [63, 66],
      // Section A' (bars 24–31)
      [66, 69], [64, 67], [64, 67], [66, 69],
      [71, 74], [65, 69], [66, 69], [64, 68],
    ];

    final notes = <_Note>[];
    for (int bar = 0; bar < _totalBars; bar++) {
      final barStart = bar * _beatsPerBar * _spb;
      for (int step = 0; step < 16; step++) {
        if (batidaPattern[step] == 1) {
          final offset = barStart + step * sixteenth;
          for (final midiNote in allBarVoicings[bar]) {
            notes.add(_Note(_midi(midiNote), offset, sixteenth - 20, 0, 0.38));
          }
        }
      }
    }
    return notes;
  }

  // ---------------------------------------------------------------------------
  // Counter melody — active in sections B (bars 8–15) and A' (bars 24–31)
  // ---------------------------------------------------------------------------
  static List<_Note> _counterVoice() {
    const counterMel = [
      (0, 4.0),
      (71, 1.0), (69, 0.5), (67, 0.5), (66, 2.0),
      (0, 2.0), (67, 1.0), (69, 0.5), (71, 0.5),
      (73, 2.0), (0, 2.0),
      (71, 1.0), (69, 0.5), (67, 0.5), (66, 2.0),
      (0, 4.0),
      (64, 1.0), (66, 0.5), (67, 0.5), (69, 2.0),
      (0, 2.0), (69, 1.0), (71, 0.5), (73, 0.5),
      (74, 3.0), (0, 1.0),
      (73, 1.0), (71, 0.5), (69, 0.5), (67, 2.0),
      (0, 4.0),
    ];

    final notes = <_Note>[];

    // Section B: bars 8–15
    int offset = 8 * _beatsPerBar * _spb;
    for (final (midi, beats) in counterMel) {
      final dur = (beats * _spb).round();
      if (midi > 0) {
        notes.add(_Note(_midi(midi), offset, dur, 1, 0.55));
      }
      offset += dur;
    }

    // Section A': bars 24–31
    offset = 24 * _beatsPerBar * _spb;
    for (final (midi, beats) in counterMel) {
      final dur = (beats * _spb).round();
      if (midi > 0) {
        notes.add(_Note(_midi(midi), offset, dur, 1, 0.55));
      }
      offset += dur;
    }

    return notes;
  }

  // ---------------------------------------------------------------------------
  // Render helpers
  // ---------------------------------------------------------------------------
  static void _renderVoice(Int16List out, List<_Note> notes) {
    for (final note in notes) {
      final end = (note.offset + note.durationSamples).clamp(0, out.length);
      double phase = 0;
      for (int i = note.offset; i < end; i++) {
        final t = (i - note.offset) / _sampleRate;
        final dur = note.durationSamples / _sampleRate;

        final fadeIn = (t < 0.012) ? t / 0.012 : 1.0;
        final fadeOut = (t > dur - 0.018) ? (dur - t) / 0.018 : 1.0;
        final amp = (fadeIn * fadeOut).clamp(0.0, 1.0) * note.volume;

        // Phase wrapped to avoid floating-point precision loss on long notes
        phase = (phase + note.freq / _sampleRate) % 1.0;
        final wave = note.waveType == 0
            ? (sin(2 * pi * phase) >= 0 ? 1.0 : -1.0)
            : (2 / pi) * asin(sin(2 * pi * phase).clamp(-1.0, 1.0));

        final existing = out[i];
        out[i] = (existing + wave * amp * 8191).clamp(-32767, 32767).round();
      }
    }
  }

  static void _normalize(Int16List samples) {
    int peak = 0;
    for (final s in samples) {
      if (s.abs() > peak) peak = s.abs();
    }
    if (peak == 0) return;
    final scale = 28000 / peak;
    for (int i = 0; i < samples.length; i++) {
      samples[i] = (samples[i] * scale).clamp(-32767, 32767).round();
    }
  }
}

class _Note {
  const _Note(
      this.freq, this.offset, this.durationSamples, this.waveType, this.volume);
  final double freq;
  final int offset;
  final int durationSamples;
  final int waveType; // 0=square, 1=triangle
  final double volume;
}
