import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'animal_voices.dart';
import 'synth_core.dart';
import 'wav_utils.dart';

/// Generates an ~85s Bossa Nova loop as a WAV file, rendered off the UI isolate.
/// 32 bars × 4 beats at 90 BPM. A 16-bar jazz progression plays twice; the
/// reprise lifts lower melody notes an octave for an A/A' contrast.
/// Voices use Karplus-Strong (nylon guitar) over a bed of water + wind ambience
/// with sparse animal calls.
class JungleSequencer {
  static const _sr = SynthCore.sampleRate;
  static const _beatsPerBar = 4;
  static const _totalBars = 32;
  static const _spb = _sr * 60 ~/ 90; // samples per beat at 90 BPM = 21333

  static double _midi(int n) => 440.0 * pow(2, (n - 69) / 12);

  // 16-bar progression (key of C). 4-note jazz voicings (MIDI).
  static const _chords = <List<int>>[
    [60, 64, 67, 71], // Cmaj7
    [60, 64, 67, 71], // Cmaj7
    [62, 65, 69, 72], // Dm7
    [59, 62, 65, 67], // G7
    [64, 67, 71, 74], // Em7
    [61, 64, 67, 69], // A7
    [62, 65, 69, 72], // Dm7
    [59, 62, 65, 67], // G7
    [60, 64, 67, 71], // Cmaj7
    [57, 60, 64, 67], // Am7
    [62, 65, 69, 72], // Dm7
    [59, 62, 65, 67], // G7
    [64, 67, 71, 74], // Em7
    [61, 64, 67, 69], // A7
    [62, 65, 69, 72], // Dm7
    [55, 59, 62, 65], // G7 (turnaround)
  ];

  // Bass roots per bar (MIDI), matching the chords.
  static const _bassRoots = [
    36, 36, 38, 43, 40, 45, 38, 43, // bars 0–7
    36, 45, 38, 43, 40, 45, 38, 43, // bars 8–15
  ];

  // Bossa comping pattern over one bar (16 sixteenth steps).
  static const _batida = [1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0];

  // Main melody: (midiNote, beats). 0 = rest. 16 bars / 64 beats.
  static const _melody = <(int, double)>[
    (67, 1), (71, 0.5), (67, 0.5), (64, 2), // bar0
    (64, 1), (67, 1), (72, 2), // bar1
    (69, 1), (72, 0.5), (69, 0.5), (65, 2), // bar2
    (67, 1), (65, 1), (62, 2), // bar3
    (64, 1), (67, 0.5), (71, 0.5), (74, 2), // bar4
    (73, 1), (71, 1), (69, 2), // bar5
    (69, 1), (65, 1), (62, 2), // bar6
    (62, 2), (0, 2), // bar7
    (60, 1), (64, 0.5), (67, 0.5), (71, 2), // bar8
    (69, 1), (67, 1), (64, 2), // bar9
    (65, 1), (69, 0.5), (72, 0.5), (69, 2), // bar10
    (67, 1), (62, 1), (65, 2), // bar11
    (71, 1), (67, 1), (64, 2), // bar12
    (73, 1.5), (69, 0.5), (67, 2), // bar13
    (65, 1), (62, 0.5), (69, 0.5), (62, 2), // bar14
    (62, 4), // bar15
  ];

  static Future<Uint8List> generate() => Isolate.run(_renderLoop);

  static Uint8List _renderLoop() {
    final total = _totalBars * _beatsPerBar * _spb;
    final out = Int16List(total);

    _renderAmbience(out);
    for (int pass = 0; pass < 2; pass++) {
      final barOffset = pass * 16;
      _renderBass(out, barOffset);
      _renderComping(out, barOffset);
      _renderMelody(out, barOffset, reprise: pass == 1);
    }
    _renderAnimals(out);

    _normalize(out);
    return buildWav(out, sampleRate: _sr);
  }

  static void _renderAmbience(Int16List out) {
    // Babbling water (low, slow modulation).
    SynthCore.filteredNoise(out, 0, out.length,
        pink: true, cutoff: 600, lfoRate: 0.15, lfoDepth: 0.4, volume: 0.10,
        seed: 101);
    // Wind / leaves.
    SynthCore.filteredNoise(out, 0, out.length,
        pink: true, cutoff: 1200, lfoRate: 0.08, lfoDepth: 0.5, volume: 0.06,
        seed: 202);
  }

  static void _renderBass(Int16List out, int barOffset) {
    for (int b = 0; b < 16; b++) {
      final barStart = (barOffset + b) * _beatsPerBar * _spb;
      final root = _bassRoots[b];
      SynthCore.pluck(out, _midi(root), barStart, (1.5 * _spb).round(),
          brightness: 0.97, damping: 0.6, volume: 0.30);
      SynthCore.pluck(out, _midi(root + 7), barStart + 2 * _spb,
          (1.5 * _spb).round(),
          brightness: 0.97, damping: 0.6, volume: 0.26);
    }
  }

  static void _renderComping(Int16List out, int barOffset) {
    final sixteenth = _spb ~/ 4;
    for (int b = 0; b < 16; b++) {
      final barStart = (barOffset + b) * _beatsPerBar * _spb;
      final chord = _chords[b];
      for (int step = 0; step < 16; step++) {
        if (_batida[step] == 0) continue;
        final hit = barStart + step * sixteenth;
        for (int v = 0; v < chord.length; v++) {
          // Small strum spread between strings.
          final strum = (v * 0.006 * _sr).round();
          SynthCore.pluck(out, _midi(chord[v]), hit + strum, _spb,
              brightness: 0.95, damping: 0.45, volume: 0.16);
        }
      }
    }
  }

  static void _renderMelody(Int16List out, int barOffset,
      {required bool reprise}) {
    int offset = barOffset * _beatsPerBar * _spb;
    for (final (note, beats) in _melody) {
      final dur = (beats * _spb).round();
      if (note > 0) {
        final n = (reprise && note < 72) ? note + 12 : note;
        SynthCore.pluck(out, _midi(n), offset, dur - 200,
            brightness: 0.96, damping: 0.4, volume: 0.30);
      }
      offset += dur;
    }
  }

  static void _renderAnimals(Int16List out) {
    // Deterministic sparse calls under the music (level, time in seconds).
    const calls = <(int, double)>[
      (3, 5.0), (4, 12.0), (1, 20.0), (3, 33.0),
      (8, 48.0), (4, 60.0), (1, 70.0), (3, 78.0),
    ];
    for (final (level, sec) in calls) {
      final src = AnimalVoices.voiceSamples(level);
      _mixInto(out, src, (sec * _sr).round(), 0.22);
    }
  }

  static void _mixInto(Int16List dest, Int16List src, int offset, double vol) {
    for (int i = 0; i < src.length; i++) {
      final j = offset + i;
      if (j >= dest.length) break;
      dest[j] = (dest[j] + src[i] * vol).clamp(-32767, 32767).round();
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
