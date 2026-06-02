# Trilha Bossa Nova Amazônica — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reformular a trilha tema e os SFX do jogo para uma Bossa Nova amazônica com timbres de violão de nylon, ambiência de natureza, vozes de bicho e SFX de desfazer — tudo 100% procedural.

**Architecture:** Um núcleo de síntese DSP novo (`SynthCore`: Karplus-Strong, ruído filtrado, ADSR, tom/glide) é compartilhado pela música (`JungleSequencer` reescrito) e pelos SFX. As vozes de bicho ficam num módulo próprio (`AnimalVoices`). Eventos novos no `AudioService` conectam o gameplay (merge que sobe nível → voz do bicho; desfazer 1/3 → "rebobinar"). Tudo gerado como WAV em memória no startup; nenhum arquivo de áudio.

**Tech Stack:** Dart puro (`dart:math`, `dart:typed_data`, `dart:isolate`), `flutter_soloud` (playback), `flutter_riverpod`, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-06-02-trilha-bossa-amazonica-design.md`

---

## File Structure

| Arquivo | Responsabilidade |
| ------- | ---------------- |
| `lib/domain/audio/synth_core.dart` **[NOVO]** | DSP reutilizável: Karplus-Strong, ruído filtrado, ADSR, tom/glide, mix. Fonte única de `sampleRate`. |
| `lib/domain/audio/animal_voices.dart` **[NOVO]** | Voz sintetizada de cada bicho + pluck de merge. Expõe `voiceSamples` (buffer) para a ambiência do sequencer. |
| `lib/domain/audio/jungle_sequencer.dart` **[REESCRITO]** | Loop de música: harmonia bossa, comping/baixo/melodia via KS, ambiência + bichos esparsos. |
| `lib/domain/audio/sfxr_synth.dart` **[EDITADO]** | `generateMerge` delega a `AnimalVoices`; `generateUndo1/3`; migra p/ `SynthCore.sampleRate`. |
| `lib/domain/audio/sound_presets.dart` **[EDITADO]** | Presets `undo1`/`undo3`. |
| `lib/domain/audio/audio_service.dart` **[EDITADO]** | Eventos `AnimalReached`, `Undo1Used`, `Undo3Used`. |
| `lib/domain/audio/audio_service_impl.dart` **[EDITADO]** | Carrega vozes de bicho + undo; roteia eventos novos. |
| `lib/presentation/controllers/game_notifier.dart` **[EDITADO]** | Dispara `AnimalReached` (nível máximo novo) e `Undo1/3Used` (no `undo`). |

**Mapeamento nível → animal → síntese** (referência fixa, usada em `AnimalVoices`):

| Nível | Animal | Técnica |
| --- | --- | --- |
| 1 | Tanajura (cigarra) | ruído bandpass alto + tremolo (zumbido) |
| 2 | Lobo-guará | **chime** (difícil) |
| 3 | Sapo-cururu | dois bursts square graves + tremolo (coaxar) |
| 4 | Tucano | dois chirps (sweep de pitch p/ cima) |
| 5 | Sagui | tom agudo 5–6 kHz + vibrato rápido + tremolo |
| 6 | Preguiça | **chime** (difícil) |
| 7 | Mico-leão | **chime** (difícil) |
| 8 | Boto | assobio ascendente + cliques |
| 9 | Onça | **chime** (difícil) |
| 10 | Sucuri | ruído bandpass + swell (sibilo) |
| 11 | Capivara | **especial**: call grave + arpejo nylon triunfante |

---

## Task 1: SynthCore — base (constants, mix, lfo, adsr, tone)

**Files:**
- Create: `lib/domain/audio/synth_core.dart`
- Test: `test/domain/audio/synth_core_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/domain/audio/synth_core_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/audio/synth_core_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'synth_core.dart'`.

- [ ] **Step 3: Write minimal implementation**

Create `lib/domain/audio/synth_core.dart`:

```dart
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
    if (t < dur) return s * (dur - t) / r;
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
      final freq = base * (1 + vibratoDepth * sin(2 * pi * vibratoRate * t));
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
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/audio/synth_core_test.dart`
Expected: PASS (all 7 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/domain/audio/synth_core.dart test/domain/audio/synth_core_test.dart
git commit -m "feat(audio): SynthCore base — sampleRate, adsr, lfo, tone, mix"
```

---

## Task 2: SynthCore.pluck (Karplus-Strong)

**Files:**
- Modify: `lib/domain/audio/synth_core.dart`
- Test: `test/domain/audio/synth_core_test.dart`

- [ ] **Step 1: Write the failing test**

Add this group to `test/domain/audio/synth_core_test.dart` (inside `main()`):

```dart
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
```

Add `import 'dart:math';` at the top of the test file (for `sqrt`/`pow`) if not present.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/audio/synth_core_test.dart`
Expected: FAIL — `The method 'pluck' isn't defined for the type 'SynthCore'`.

- [ ] **Step 3: Write minimal implementation**

Add to `class SynthCore` in `lib/domain/audio/synth_core.dart`:

```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/audio/synth_core_test.dart`
Expected: PASS (all groups).

- [ ] **Step 5: Commit**

```bash
git add lib/domain/audio/synth_core.dart test/domain/audio/synth_core_test.dart
git commit -m "feat(audio): SynthCore.pluck — Karplus-Strong nylon string"
```

---

## Task 3: SynthCore.filteredNoise

**Files:**
- Modify: `lib/domain/audio/synth_core.dart`
- Test: `test/domain/audio/synth_core_test.dart`

- [ ] **Step 1: Write the failing test**

Add this group to `test/domain/audio/synth_core_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/audio/synth_core_test.dart`
Expected: FAIL — `The method 'filteredNoise' isn't defined`.

- [ ] **Step 3: Write minimal implementation**

Add to `class SynthCore`:

```dart
  /// Renders filtered noise (state-variable filter) into [target].
  /// [filter]: 'lowpass' | 'bandpass'. [pink] mellows the white noise.
  /// Cutoff is modulated by a slow LFO ([lfoRate]/[lfoDepth]).
  static void filteredNoise(
    Int16List target,
    int offset,
    int durationSamples, {
    bool pink = false,
    String filter = 'lowpass',
    double cutoff = 800,
    double resonance = 0.5,
    double lfoRate = 0.2,
    double lfoDepth = 0.0,
    double volume = 0.3,
    int seed = 0,
  }) {
    final rng = Random(seed);
    final end = (offset + durationSamples).clamp(0, target.length);
    double low = 0, band = 0, pinkState = 0;
    final q = 1.0 - resonance.clamp(0.0, 0.99);
    for (int i = offset; i < end; i++) {
      double white = rng.nextDouble() * 2 - 1;
      if (pink) {
        pinkState = 0.98 * pinkState + 0.02 * white;
        white = pinkState * 3.5;
      }
      final t = (i - offset) / sampleRate;
      final modCutoff =
          (cutoff * (1 + lfoDepth * sin(2 * pi * lfoRate * t)))
              .clamp(20, sampleRate / 2.2);
      final f = 2 * sin(pi * modCutoff / sampleRate);
      low += f * band;
      final high = white - low - q * band;
      band += f * high;
      final out = filter == 'bandpass' ? band : low;
      mix(target, out * volume * 16000, i);
    }
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/audio/synth_core_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/audio/synth_core.dart test/domain/audio/synth_core_test.dart
git commit -m "feat(audio): SynthCore.filteredNoise — state-variable filtered noise"
```

---

## Task 4: AnimalVoices (vozes de bicho + pluck de merge)

**Files:**
- Create: `lib/domain/audio/animal_voices.dart`
- Test: `test/domain/audio/animal_voices_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/domain/audio/animal_voices_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/audio/animal_voices.dart';
import 'package:capivara_2048/domain/audio/synth_core.dart';

void main() {
  group('mergePluck', () {
    test('gera WAV válido com sampleRate correto p/ todos os níveis', () {
      for (int level = 1; level <= 11; level++) {
        final wav = AnimalVoices.mergePluck(level);
        expect(wav.length, greaterThan(44), reason: 'level $level');
        expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF',
            reason: 'level $level');
        // header sampleRate (bytes 24-27, little endian) == 32000
        final sr = wav[24] | (wav[25] << 8) | (wav[26] << 16) | (wav[27] << 24);
        expect(sr, SynthCore.sampleRate, reason: 'level $level');
      }
    });
  });

  group('voice', () {
    test('produz WAV válido p/ todos os níveis (inclui chime e especial)', () {
      for (int level = 1; level <= 11; level++) {
        final wav = AnimalVoices.voice(level);
        expect(wav.length, greaterThan(44), reason: 'level $level');
        expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF',
            reason: 'level $level');
      }
    });

    test('capivara (11) é a mais longa', () {
      final capivara = AnimalVoices.voice(11).length;
      for (int level = 1; level <= 10; level++) {
        expect(capivara, greaterThan(AnimalVoices.voice(level).length),
            reason: 'level $level');
      }
    });
  });

  group('voiceSamples', () {
    test('retorna buffer sem header WAV', () {
      final samples = AnimalVoices.voiceSamples(3);
      expect(samples.length, greaterThan(0));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/audio/animal_voices_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'animal_voices.dart'`.

- [ ] **Step 3: Write minimal implementation**

Create `lib/domain/audio/animal_voices.dart`:

```dart
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
  static Uint8List voice(int level) =>
      buildWav(voiceSamples(level), sampleRate: _sr);

  /// Same as [voice] but raw samples (no WAV header), for embedding in the
  /// music loop ambience.
  static Int16List voiceSamples(int level) => switch (level) {
        1 => _cigarra(),
        3 => _sapo(),
        4 => _tucano(),
        5 => _sagui(),
        8 => _boto(),
        10 => _sucuri(),
        11 => _capivara(),
        _ => _chime(level), // 2, 6, 7, 9 (difíceis)
      };

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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/audio/animal_voices_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/audio/animal_voices.dart test/domain/audio/animal_voices_test.dart
git commit -m "feat(audio): AnimalVoices — vozes sintetizadas dos bichos + merge pluck"
```

---

## Task 5: sound_presets — presets de desfazer

**Files:**
- Modify: `lib/domain/audio/sound_presets.dart`
- Test: `test/domain/audio/sfxr_synth_test.dart` (verificação na Task 6)

- [ ] **Step 1: Write minimal implementation**

Em `lib/domain/audio/sound_presets.dart`, adicionar dentro de `class SoundPresets`, logo após `bomb3x`:

```dart
  // Desfazer: varredura de pitch REVERSA (freq sobe no tempo) → "rebobinar".
  // freqSweep negativo faz freq = baseFreq * exp(+|sweep|*t), subindo.
  static const undo1 = SoundPreset(
    waveType: WaveType.triangle,
    baseFreq: 220,
    freqSweep: -4.0,
    attack: 0.005,
    sustain: 0.04,
    decay: 0.18,
    volume: 0.6,
  );

  static const undo3 = SoundPreset(
    waveType: WaveType.triangle,
    baseFreq: 130,
    freqSweep: -3.0,
    attack: 0.005,
    sustain: 0.08,
    decay: 0.40,
    volume: 0.7,
  );
```

(`SfxrSynth.generate` já computa `freq = baseFreq * exp(-freqSweep * t)`; com `freqSweep` negativo a frequência sobe, gerando a sensação de rebobinar.)

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/domain/audio/sound_presets.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/domain/audio/sound_presets.dart
git commit -m "feat(audio): presets undo1/undo3 — varredura de pitch reversa"
```

---

## Task 6: sfxr_synth — merge delegado, SFX de desfazer, sampleRate 32k

**Files:**
- Modify: `lib/domain/audio/sfxr_synth.dart`
- Test: `test/domain/audio/sfxr_synth_test.dart`

- [ ] **Step 1: Write/adjust the failing tests**

Substituir o conteúdo de `test/domain/audio/sfxr_synth_test.dart` por (atualiza sampleRate p/ 32000, adiciona undo, ajusta merge):

```dart
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/domain/audio/sfxr_synth_test.dart`
Expected: FAIL — `generateUndo1`/`generateUndo3` não definidos.

- [ ] **Step 3: Write minimal implementation**

Em `lib/domain/audio/sfxr_synth.dart`:

1. Trocar o import e a constante de sampleRate. No topo, adicionar:

```dart
import 'animal_voices.dart';
import 'synth_core.dart';
```

2. Trocar a linha `static const _sampleRate = 22050;` por:

```dart
  static const _sampleRate = SynthCore.sampleRate;
```

3. Em `generate(...)`, a chamada final `return buildWav(samples);` passa a:

```dart
    return buildWav(samples, sampleRate: _sampleRate);
```

4. Substituir o corpo de `generateMerge` para delegar:

```dart
  Uint8List generateMerge(int level) {
    assert(level >= 1 && level <= 11);
    return AnimalVoices.mergePluck(level);
  }
```

5. Adicionar os dois métodos de desfazer (após `generateMerge`):

```dart
  Uint8List generateUndo1() => generate(SoundPresets.undo1);
  Uint8List generateUndo3() => generate(SoundPresets.undo3);
```

6. Em `_generateSequence`, a chamada `return buildWav(total);` passa a:

```dart
    return buildWav(total, sampleRate: _sampleRate);
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/domain/audio/sfxr_synth_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/audio/sfxr_synth.dart test/domain/audio/sfxr_synth_test.dart
git commit -m "feat(audio): sfxr — merge delegado a AnimalVoices, undo1/3, sampleRate 32k"
```

---

## Task 7: jungle_sequencer — reescrita (bossa + KS + ambiência + bichos)

**Files:**
- Modify (rewrite): `lib/domain/audio/jungle_sequencer.dart`
- Test: `test/domain/audio/jungle_sequencer_test.dart`

- [ ] **Step 1: Adjust the failing test (sampleRate 32k)**

Substituir o conteúdo de `test/domain/audio/jungle_sequencer_test.dart` por:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/audio/jungle_sequencer.dart';
import 'package:capivara_2048/domain/audio/synth_core.dart';

void main() {
  group('JungleSequencer', () {
    test('generate retorna WAV válido', () async {
      final wav = await JungleSequencer.generate();
      expect(wav.length, greaterThan(44));
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    });

    test('duração está entre 80s e 90s', () async {
      final wav = await JungleSequencer.generate();
      final samples = (wav.length - 44) ~/ 2;
      final durationSec = samples / SynthCore.sampleRate;
      expect(durationSec, greaterThanOrEqualTo(80));
      expect(durationSec, lessThanOrEqualTo(90));
    });

    test('header declara sampleRate 32000', () async {
      final wav = await JungleSequencer.generate();
      final sr = wav[24] | (wav[25] << 8) | (wav[26] << 16) | (wav[27] << 24);
      expect(sr, SynthCore.sampleRate);
    });

    test('fim do loop não está clippando', () async {
      final wav = await JungleSequencer.generate();
      final data = wav.sublist(44);
      int clipped = 0;
      for (int i = data.length - 2000; i < data.length; i += 2) {
        final raw = (data[i + 1] << 8) | data[i];
        final signed = raw > 32767 ? raw - 65536 : raw;
        if (signed.abs() > 30000) clipped++;
      }
      expect(clipped, lessThan(50));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/audio/jungle_sequencer_test.dart`
Expected: FAIL — header sampleRate ainda é 22050 (test novo de sampleRate falha) ou import de `synth_core` ausente no sequencer.

- [ ] **Step 3: Rewrite the implementation**

Substituir TODO o conteúdo de `lib/domain/audio/jungle_sequencer.dart` por:

```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/audio/jungle_sequencer_test.dart`
Expected: PASS (duração ~85.3s dentro de 80–90s; sampleRate 32000; sem clipping).

- [ ] **Step 5: Commit**

```bash
git add lib/domain/audio/jungle_sequencer.dart test/domain/audio/jungle_sequencer_test.dart
git commit -m "feat(audio): JungleSequencer reescrito — bossa nylon KS + ambiência + bichos"
```

---

## Task 8: audio_service — eventos novos

**Files:**
- Modify: `lib/domain/audio/audio_service.dart`
- Test: `test/domain/audio/audio_service_test.dart`

- [ ] **Step 1: Write the failing test**

Substituir o `test('playEffect does not throw for any event', ...)` em `test/domain/audio/audio_service_test.dart` por:

```dart
    test('playEffect does not throw for any event', () {
      expect(() => stub.playEffect(const Bomb2xUsed()), returnsNormally);
      expect(() => stub.playEffect(const Bomb3xUsed()), returnsNormally);
      expect(() => stub.playEffect(const TilesMerged(5)), returnsNormally);
      expect(() => stub.playEffect(const AnimalReached(8)), returnsNormally);
      expect(() => stub.playEffect(const Undo1Used()), returnsNormally);
      expect(() => stub.playEffect(const Undo3Used()), returnsNormally);
      expect(() => stub.playEffect(const VictoryReached()), returnsNormally);
      expect(() => stub.playEffect(const GameOver()), returnsNormally);
    });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/audio/audio_service_test.dart`
Expected: FAIL — `AnimalReached` / `Undo1Used` / `Undo3Used` não definidos.

- [ ] **Step 3: Write minimal implementation**

Em `lib/domain/audio/audio_service.dart`, adicionar os eventos ao `sealed class GameSoundEvent` (após `TilesMerged`):

```dart
class AnimalReached extends GameSoundEvent {
  const AnimalReached(this.level); // 1–11
  final int level;
}

class Undo1Used extends GameSoundEvent {
  const Undo1Used();
}

class Undo3Used extends GameSoundEvent {
  const Undo3Used();
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/audio/audio_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/audio/audio_service.dart test/domain/audio/audio_service_test.dart
git commit -m "feat(audio): eventos AnimalReached, Undo1Used, Undo3Used"
```

---

## Task 9: audio_service_impl — carregar e rotear novos sons

**Files:**
- Modify: `lib/domain/audio/audio_service_impl.dart`

> Sem teste unitário próprio: `AudioServiceImpl` depende de `SoLoud` (plugin nativo) e não roda em `flutter test`. A verificação é o `flutter analyze` (switch exaustivo sobre o sealed exige os casos novos) + smoke manual no app.

- [ ] **Step 1: Add fields for the new sounds**

Em `lib/domain/audio/audio_service_impl.dart`, dentro da classe, junto aos outros campos `AudioSource?`, adicionar:

```dart
  final _animalVoices = <int, AudioSource>{};
  AudioSource? _undo1;
  AudioSource? _undo3;
```

- [ ] **Step 2: Load them in `_loadSfx`**

Dentro de `_loadSfx()`, logo após o loop que carrega `_mergeSounds`, adicionar:

```dart
    for (int level = 1; level <= 11; level++) {
      _animalVoices[level] = await SoLoud.instance.loadMem(
        'animal_$level',
        AnimalVoices.voice(level),
      );
    }
    _undo1 = await SoLoud.instance.loadMem('undo1', synth.generateUndo1());
    _undo3 = await SoLoud.instance.loadMem('undo3', synth.generateUndo3());
```

E adicionar o import no topo do arquivo:

```dart
import 'animal_voices.dart';
```

- [ ] **Step 3: Route the new events in `playEffect`**

No `switch (event)` de `playEffect`, adicionar os casos (antes do fechamento do switch):

```dart
      AnimalReached(:final level) => _animalVoices[level.clamp(1, 11)],
      Undo1Used() => _undo1,
      Undo3Used() => _undo3,
```

- [ ] **Step 4: Verify it compiles (exhaustive switch satisfied)**

Run: `flutter analyze lib/domain/audio/audio_service_impl.dart`
Expected: No issues (sem aviso de switch não-exaustivo).

- [ ] **Step 5: Commit**

```bash
git add lib/domain/audio/audio_service_impl.dart
git commit -m "feat(audio): impl carrega vozes de bicho + undo e roteia eventos"
```

---

## Task 10: game_notifier — disparar eventos no gameplay

**Files:**
- Modify: `lib/presentation/controllers/game_notifier.dart`

> Sem teste unitário: o disparo de áudio via `ref.read(audioServiceProvider)` usa o `AudioServiceStub` em testes (no-op) e os hooks já existentes (bombas) não têm teste. Verificação: `flutter analyze` + smoke manual.

- [ ] **Step 1: Disparar AnimalReached ao subir o nível máximo**

Em `lib/presentation/controllers/game_notifier.dart`, no bloco `if (state.maxLevel > before.maxLevel) {` (≈ linha 126), adicionar a chamada de áudio logo após o `maybeHaptic(...)` de intensidade heavy e antes do `unawaited(... updateHighestLevel ...)`:

```dart
      ref.read(audioServiceProvider).playEffect(
        AnimalReached(state.maxLevel),
      );
```

- [ ] **Step 2: Disparar Undo1/Undo3Used no método `undo`**

Substituir o método `undo` (≈ linhas 191–198) por:

```dart
  bool undo(int steps) {
    final stack = state.undoStack;
    if (stack.length < steps) return false;
    final idx = steps - 1;
    final remainingStack = stack.skip(idx + 1).toList();
    state = stack[idx].copyWith(undoStack: remainingStack);
    ref.read(audioServiceProvider).playEffect(
      steps == 1 ? const Undo1Used() : const Undo3Used(),
    );
    return true;
  }
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/presentation/controllers/game_notifier.dart`
Expected: No issues. (O import `'../../domain/audio/audio_service.dart'` já existe — linha 23 — então `AnimalReached`/`Undo1Used`/`Undo3Used` estão visíveis.)

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/controllers/game_notifier.dart
git commit -m "feat(audio): game_notifier dispara AnimalReached e Undo1/3Used"
```

---

## Task 11: Verificação final

**Files:** nenhum (apenas verificação).

- [ ] **Step 1: Rodar toda a suíte de áudio**

Run: `flutter test test/domain/audio/`
Expected: PASS — todos os testes (synth_core, animal_voices, sfxr_synth, jungle_sequencer, audio_service, wav_utils).

- [ ] **Step 2: Analyze do módulo inteiro**

Run: `flutter analyze lib/domain/audio lib/presentation/controllers/game_notifier.dart`
Expected: No issues found.

- [ ] **Step 3: Smoke manual no app (dispositivo/emulador)**

Run: `flutter run --flavor tst --dart-define=FLAVOR=dev`
Verificar manualmente:
- Música tema soa como bossa com violão de nylon (sem "bip-bip"); ambiência de água/vento audível ao fundo; bichos esparsos.
- Merge comum = pluck sutil; ao alcançar um animal novo, toca a voz dele (ou chime nos difíceis 2/6/7/9).
- Desfazer 1 e Desfazer 3 tocam "rebobinar" distintos (undo3 mais grave/longo).

- [ ] **Step 4: Atualizar CHANGELOG / docs (release checklist)**

Conforme `CLAUDE.md`: atualizar `CHANGELOG.md`, `README.md`, `CLAUDE.md`, `AGENTS.md` com a nova trilha (fase 5.x). Commit:

```bash
git add CHANGELOG.md README.md CLAUDE.md AGENTS.md
git commit -m "docs: trilha Bossa Nova amazônica procedural (áudio v2)"
```

---

## Notas de implementação

- **Ordem de render no sequencer importa:** ambiência primeiro (volume baixo), depois instrumentos, depois bichos; `_normalize` no fim garante headroom sem clipping. Os volumes por voz já deixam margem.
- **Determinismo:** todas as fontes de `Random` usam seed fixo → o WAV gerado é idêntico a cada startup (loop consistente, sem "pops" diferentes a cada execução).
- **Performance:** o render roda 1× no `Isolate.run` no startup; ~85s a 32 kHz com plucks KS é O(amostras × vozes ativas) — aceitável fora da UI thread.
- **`buildWav` default 22050:** toda chamada DEVE passar `sampleRate: SynthCore.sampleRate`. As tasks 4, 6 e 7 já fazem isso; não introduzir chamadas sem o parâmetro.
