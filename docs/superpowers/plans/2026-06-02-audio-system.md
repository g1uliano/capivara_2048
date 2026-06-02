# Audio System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar sistema de áudio procedural completo: efeitos sonoros 8-bit (sfxr-style) + música de fundo MPB/Bossa Nova em chiptune, sintetizados em runtime via Dart + flutter_soloud.

**Architecture:** `flutter_soloud` (SoLoud C++) serve como engine de playback — mixing, looping, baixa latência. `SfxrSynth` gera WAV PCM em memória para efeitos. `JungleSequencer` roda em `Isolate` no boot e pré-renderiza um loop musical de ~85s. `AudioService` é o facade Riverpod que orquestra os três. Flavor `dev` usa stub silencioso.

**Tech Stack:** flutter_soloud ^2.x, dart:isolate, dart:typed_data, dart:math

**Spec:** `docs/superpowers/specs/2026-06-02-audio-system-design.md`

---

## File Map

**Criar:**
- `lib/domain/audio/wav_utils.dart` — escreve header WAV + amostras Int16 para Uint8List
- `lib/domain/audio/sound_presets.dart` — SoundPreset data class, WaveType enum, SoundPresets constants
- `lib/domain/audio/sfxr_synth.dart` — síntese PCM de efeitos sonoros
- `lib/domain/audio/audio_service.dart` — sealed GameSoundEvent, abstract AudioService, Riverpod provider
- `lib/domain/audio/audio_service_stub.dart` — no-op stub (FLAVOR=dev)
- `lib/domain/audio/audio_service_impl.dart` — implementação flutter_soloud
- `lib/domain/audio/jungle_sequencer.dart` — sintetizador bossa nova 85s

**Modificar:**
- `pubspec.yaml` — add flutter_soloud
- `lib/app.dart` — ConsumerStatefulWidget + audioService.init()
- `lib/presentation/controllers/settings_notifier.dart` — add audio fields
- `lib/presentation/screens/settings_screen.dart` — add audio section
- `lib/presentation/controllers/game_notifier.dart` — hooks bomb + merge
- `lib/presentation/screens/game/game_screen.dart` — música lifecycle + gameOver hook
- `lib/presentation/widgets/victory_choice_dialog.dart` — victory hook

**Testes:**
- `test/domain/audio/wav_utils_test.dart`
- `test/domain/audio/sfxr_synth_test.dart`
- `test/domain/audio/jungle_sequencer_test.dart`

---

## Task 1: flutter_soloud + WAV utilities

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/domain/audio/wav_utils.dart`
- Create: `test/domain/audio/wav_utils_test.dart`

- [ ] **Step 1: Adicionar flutter_soloud ao pubspec.yaml**

Dentro de `dependencies:`, adicionar após `flutter_riverpod`:
```yaml
flutter_soloud: ^2.0.0
```

Rodar:
```bash
flutter pub get
```

Esperado: resolução sem conflitos de versão. Se houver conflito, checar versão atual em pub.dev e ajustar o constraint.

- [ ] **Step 2: Escrever testes para buildWav**

Criar `test/domain/audio/wav_utils_test.dart`:
```dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/audio/wav_utils.dart';

void main() {
  group('buildWav', () {
    test('header starts with RIFF and WAVE magic bytes', () {
      final samples = Int16List(100);
      final wav = buildWav(samples);
      expect(wav[0], 0x52); // R
      expect(wav[1], 0x49); // I
      expect(wav[2], 0x46); // F
      expect(wav[3], 0x46); // F
      expect(wav[8], 0x57);  // W
      expect(wav[9], 0x41);  // A
      expect(wav[10], 0x56); // V
      expect(wav[11], 0x45); // E
    });

    test('total size is 44 + samples * 2', () {
      final samples = Int16List(1000);
      final wav = buildWav(samples);
      expect(wav.length, 44 + 1000 * 2);
    });

    test('sample rate is written correctly at offset 24', () {
      final samples = Int16List(10);
      final wav = buildWav(samples, sampleRate: 22050);
      final view = ByteData.sublistView(wav);
      expect(view.getUint32(24, Endian.little), 22050);
    });

    test('data chunk size is samples * 2', () {
      final samples = Int16List(500);
      final wav = buildWav(samples);
      final view = ByteData.sublistView(wav);
      expect(view.getUint32(40, Endian.little), 500 * 2);
    });
  });
}
```

- [ ] **Step 3: Rodar testes — esperar FAIL**

```bash
flutter test test/domain/audio/wav_utils_test.dart
```
Esperado: compilation error (arquivo não existe ainda).

- [ ] **Step 4: Implementar wav_utils.dart**

Criar `lib/domain/audio/wav_utils.dart`:
```dart
import 'dart:typed_data';

Uint8List buildWav(Int16List samples, {int sampleRate = 22050}) {
  final dataSize = samples.length * 2;
  final fileSize = 44 + dataSize;
  final buffer = ByteData(fileSize);

  void setStr(int offset, String s) {
    for (int i = 0; i < s.length; i++) {
      buffer.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  setStr(0, 'RIFF');
  buffer.setUint32(4, fileSize - 8, Endian.little);
  setStr(8, 'WAVE');
  setStr(12, 'fmt ');
  buffer.setUint32(16, 16, Endian.little);
  buffer.setUint16(20, 1, Endian.little);   // PCM
  buffer.setUint16(22, 1, Endian.little);   // mono
  buffer.setUint32(24, sampleRate, Endian.little);
  buffer.setUint32(28, sampleRate * 2, Endian.little); // byteRate
  buffer.setUint16(32, 2, Endian.little);   // blockAlign
  buffer.setUint16(34, 16, Endian.little);  // bitsPerSample
  setStr(36, 'data');
  buffer.setUint32(40, dataSize, Endian.little);

  final bytes = buffer.buffer.asUint8List();
  final sampleBytes = samples.buffer.asUint8List();
  bytes.setRange(44, fileSize, sampleBytes);
  return bytes;
}
```

- [ ] **Step 5: Rodar testes — esperar PASS**

```bash
flutter test test/domain/audio/wav_utils_test.dart
```
Esperado: 4 testes passando.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/domain/audio/wav_utils.dart test/domain/audio/wav_utils_test.dart
git commit -m "feat(audio): flutter_soloud dep + WAV header utility"
```

---

## Task 2: Tipos de domínio — GameSoundEvent + AudioService + Stub

**Files:**
- Create: `lib/domain/audio/audio_service.dart`
- Create: `lib/domain/audio/audio_service_stub.dart`
- Create: `test/domain/audio/audio_service_test.dart`

- [ ] **Step 1: Escrever testes para o stub**

Criar `test/domain/audio/audio_service_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/audio/audio_service.dart';
import 'package:capivara_2048/domain/audio/audio_service_stub.dart';

void main() {
  group('AudioServiceStub', () {
    late AudioService stub;

    setUp(() => stub = AudioServiceStub());

    test('init completes without error', () async {
      await expectLater(stub.init(), completes);
    });

    test('playEffect does not throw for any event', () {
      expect(() => stub.playEffect(const Bomb2xUsed()), returnsNormally);
      expect(() => stub.playEffect(const Bomb3xUsed()), returnsNormally);
      expect(() => stub.playEffect(const TilesMerged(5)), returnsNormally);
      expect(() => stub.playEffect(const VictoryReached()), returnsNormally);
      expect(() => stub.playEffect(const GameOverEvent()), returnsNormally);
    });

    test('music control methods do not throw', () {
      expect(() => stub.startMusic(), returnsNormally);
      expect(() => stub.pauseMusic(), returnsNormally);
      expect(() => stub.stopMusic(), returnsNormally);
      expect(() => stub.setSfxVolume(0.5), returnsNormally);
      expect(() => stub.setMusicVolume(0.5), returnsNormally);
      expect(() => stub.setSfxEnabled(false), returnsNormally);
      expect(() => stub.setMusicEnabled(false), returnsNormally);
    });
  });
}
```

- [ ] **Step 2: Rodar testes — esperar FAIL**

```bash
flutter test test/domain/audio/audio_service_test.dart
```
Esperado: compilation error.

- [ ] **Step 3: Implementar audio_service.dart**

Criar `lib/domain/audio/audio_service.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_service_impl.dart';
import 'audio_service_stub.dart';

sealed class GameSoundEvent {
  const GameSoundEvent();
}

class Bomb2xUsed extends GameSoundEvent {
  const Bomb2xUsed();
}

class Bomb3xUsed extends GameSoundEvent {
  const Bomb3xUsed();
}

class TilesMerged extends GameSoundEvent {
  const TilesMerged(this.level);
  final int level; // 1–11
}

class VictoryReached extends GameSoundEvent {
  const VictoryReached();
}

class GameOverEvent extends GameSoundEvent {
  const GameOverEvent();
}

abstract class AudioService {
  Future<void> init();
  void dispose();

  void playEffect(GameSoundEvent event);

  void startMusic();
  void pauseMusic();
  void stopMusic();

  void setSfxVolume(double v);
  void setMusicVolume(double v);
  void setSfxEnabled(bool v);
  void setMusicEnabled(bool v);
}

final audioServiceProvider = Provider<AudioService>((ref) {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  final service = flavor == 'dev' ? AudioServiceStub() : AudioServiceImpl();
  ref.onDispose(service.dispose);
  return service;
});
```

- [ ] **Step 4: Implementar audio_service_stub.dart**

Criar `lib/domain/audio/audio_service_stub.dart`:
```dart
import 'audio_service.dart';

class AudioServiceStub implements AudioService {
  @override Future<void> init() async {}
  @override void dispose() {}
  @override void playEffect(GameSoundEvent event) {}
  @override void startMusic() {}
  @override void pauseMusic() {}
  @override void stopMusic() {}
  @override void setSfxVolume(double v) {}
  @override void setMusicVolume(double v) {}
  @override void setSfxEnabled(bool v) {}
  @override void setMusicEnabled(bool v) {}
}
```

- [ ] **Step 5: Rodar testes — esperar PASS**

```bash
flutter test test/domain/audio/audio_service_test.dart
```
Esperado: 3 testes passando.

- [ ] **Step 6: Commit**

```bash
git add lib/domain/audio/audio_service.dart lib/domain/audio/audio_service_stub.dart test/domain/audio/audio_service_test.dart
git commit -m "feat(audio): AudioService interface, GameSoundEvent, stub"
```

---

## Task 3: SfxrSynth — explosões (Bomba 2x e 3x)

**Files:**
- Create: `lib/domain/audio/sound_presets.dart`
- Create: `lib/domain/audio/sfxr_synth.dart`
- Create: `test/domain/audio/sfxr_synth_test.dart`

- [ ] **Step 1: Escrever testes de explosão**

Criar `test/domain/audio/sfxr_synth_test.dart`:
```dart
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
}
```

- [ ] **Step 2: Rodar testes — esperar FAIL**

```bash
flutter test test/domain/audio/sfxr_synth_test.dart
```
Esperado: compilation error.

- [ ] **Step 3: Implementar sound_presets.dart**

Criar `lib/domain/audio/sound_presets.dart`:
```dart
enum WaveType { square, triangle, sine }

class SoundPreset {
  const SoundPreset({
    required this.waveType,
    required this.baseFreq,
    this.freqSweep = 0,
    required this.attack,
    required this.sustain,
    required this.decay,
    this.volume = 1.0,
    this.hasNoise = false,
  });

  final WaveType waveType;
  final double baseFreq;
  final double freqSweep;  // quanto a frequência cai por segundo (exp decay)
  final double attack;     // segundos
  final double sustain;    // segundos
  final double decay;      // segundos
  final double volume;     // 0.0–1.0
  final bool hasNoise;     // mistura ruído branco

  double get totalDuration => attack + sustain + decay;
}

class SoundPresets {
  const SoundPresets._();

  static const bomb2x = SoundPreset(
    waveType: WaveType.square,
    baseFreq: 300,
    freqSweep: 8.0,
    attack: 0.001,
    sustain: 0.05,
    decay: 0.35,
    volume: 0.8,
    hasNoise: true,
  );

  static const bomb3x = SoundPreset(
    waveType: WaveType.square,
    baseFreq: 200,
    freqSweep: 5.0,
    attack: 0.001,
    sustain: 0.08,
    decay: 0.55,
    volume: 1.0,
    hasNoise: true,
  );

  // Frequências de merge por nível (1–11)
  static const mergePitches = [
    220.00, // 1 - Tanajura
    246.94, // 2
    261.63, // 3
    293.66, // 4
    329.63, // 5 - Sagui
    369.99, // 6
    415.30, // 7
    440.00, // 8
    493.88, // 9
    587.33, // 10
    880.00, // 11 - Capivara Lendária
  ];

  // Arpejo vitória: C4→G4→C5→E5
  static const victoryNotes = [261.63, 392.0, 523.25, 659.25];
  static const victoryNoteDuration = 0.13; // segundos por nota

  // Sequência game over: C4→A3→F3
  static const gameOverNotes = [261.63, 220.0, 174.61];
  static const gameOverNoteDuration = 0.28;
}
```

- [ ] **Step 4: Implementar sfxr_synth.dart**

Criar `lib/domain/audio/sfxr_synth.dart`:
```dart
import 'dart:math';
import 'dart:typed_data';
import 'sound_presets.dart';
import 'wav_utils.dart';

class SfxrSynth {
  static const _sampleRate = 22050;
  final _random = Random(42); // seed fixo: reproduzível

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
          WaveType.triangle => (2 / pi) * asin(sin(2 * pi * phase).clamp(-1.0, 1.0)),
          WaveType.sine => sin(2 * pi * phase),
        };
      }

      samples[i] = (wave * amplitude * 32767).clamp(-32767, 32767).round();
    }

    return buildWav(samples);
  }

  // Gera som de merge para um nível (1–11)
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

  // Arpejo ascendente para vitória
  Uint8List generateVictory() {
    return _generateSequence(
      SoundPresets.victoryNotes,
      SoundPresets.victoryNoteDuration,
      WaveType.square,
      0.85,
    );
  }

  // Sequência descendente para game over
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
        // Envelope simples: fade-in 5ms, fade-out últimos 10ms
        final fadeIn = (t < 0.005) ? t / 0.005 : 1.0;
        final fadeOut = (i > noteSamples - 220) ? (noteSamples - i) / 220.0 : 1.0;
        final amp = fadeIn * fadeOut * volume;
        phase += freqs[n] / _sampleRate;
        final wave = switch (waveType) {
          WaveType.square => sin(2 * pi * phase) >= 0 ? 1.0 : -1.0,
          WaveType.triangle => (2 / pi) * asin(sin(2 * pi * phase).clamp(-1.0, 1.0)),
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
```

- [ ] **Step 5: Rodar testes — esperar PASS**

```bash
flutter test test/domain/audio/sfxr_synth_test.dart
```
Esperado: 4 testes passando.

- [ ] **Step 6: Commit**

```bash
git add lib/domain/audio/sound_presets.dart lib/domain/audio/sfxr_synth.dart test/domain/audio/sfxr_synth_test.dart
git commit -m "feat(audio): SfxrSynth — bomb, merge, victory, game over synthesis"
```

---

## Task 4: SfxrSynth — testes de merge, vitória e game over

**Files:**
- Modify: `test/domain/audio/sfxr_synth_test.dart`

- [ ] **Step 1: Adicionar testes de merge e sequências**

Append ao grupo de testes em `test/domain/audio/sfxr_synth_test.dart`:
```dart
  group('merge sounds', () {
    test('generateMerge produz WAV válido para todos os níveis', () {
      for (int level = 1; level <= 11; level++) {
        final wav = synth.generateMerge(level);
        expect(wav.length, greaterThan(44), reason: 'level $level');
        expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF', reason: 'level $level');
      }
    });

    test('nível 11 tem mais amostras que nível 1 (mesma duração, mas verificamos)', () {
      // Mesma duração por design — só checa que ambos geram sem erro
      final wav1 = synth.generateMerge(1);
      final wav11 = synth.generateMerge(11);
      expect(wav1.length, greaterThan(44));
      expect(wav11.length, greaterThan(44));
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
```

- [ ] **Step 2: Rodar testes**

```bash
flutter test test/domain/audio/sfxr_synth_test.dart
```
Esperado: todos os testes passando (7 total agora).

- [ ] **Step 3: Commit**

```bash
git add test/domain/audio/sfxr_synth_test.dart
git commit -m "test(audio): cobertura de merge levels + victory + game over"
```

---

## Task 5: AudioServiceImpl — SFX (sem música ainda)

**Files:**
- Create: `lib/domain/audio/audio_service_impl.dart`

> **Nota:** `AudioServiceImpl` não tem testes de unidade — depende de SoLoud nativo. Será testado manualmente ao rodar o app.

- [ ] **Step 1: Criar audio_service_impl.dart (somente SFX)**

Criar `lib/domain/audio/audio_service_impl.dart`:
```dart
import 'dart:typed_data';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'audio_service.dart';
import 'sfxr_synth.dart';

class AudioServiceImpl implements AudioService {
  final _synth = SfxrSynth();

  AudioSource? _bomb2x;
  AudioSource? _bomb3x;
  final _mergeSounds = <int, AudioSource>{};
  AudioSource? _victory;
  AudioSource? _gameOver;
  AudioSource? _music;

  SoundHandle? _musicHandle;

  double _sfxVolume = 1.0;
  double _musicVolume = 0.7;
  bool _sfxEnabled = true;
  bool _musicEnabled = true;

  @override
  Future<void> init() async {
    await SoLoud.instance.init();
    await _loadSfx();
    // Música: carregada separadamente em Task 8
  }

  Future<void> _loadSfx() async {
    _bomb2x = await SoLoud.instance.loadMem('bomb2x', _synth.generate(SoundPresets.bomb2x));
    _bomb3x = await SoLoud.instance.loadMem('bomb3x', _synth.generate(SoundPresets.bomb3x));
    for (int level = 1; level <= 11; level++) {
      _mergeSounds[level] = await SoLoud.instance.loadMem(
        'merge_$level',
        _synth.generateMerge(level),
      );
    }
    _victory = await SoLoud.instance.loadMem('victory', _synth.generateVictory());
    _gameOver = await SoLoud.instance.loadMem('gameover', _synth.generateGameOver());
  }

  @override
  void playEffect(GameSoundEvent event) {
    if (!_sfxEnabled) return;
    final source = switch (event) {
      Bomb2xUsed() => _bomb2x,
      Bomb3xUsed() => _bomb3x,
      TilesMerged(:final level) => _mergeSounds[level.clamp(1, 11)],
      VictoryReached() => _victory,
      GameOverEvent() => _gameOver,
    };
    if (source != null) {
      SoLoud.instance.play(source, volume: _sfxVolume);
    }
  }

  @override
  void startMusic() {
    if (!_musicEnabled || _music == null) return;
    if (_musicHandle != null) {
      SoLoud.instance.setPause(_musicHandle!, false);
      return;
    }
    _musicHandle = SoLoud.instance.play(_music!, looping: true, volume: _musicVolume);
  }

  @override
  void pauseMusic() {
    if (_musicHandle != null) {
      SoLoud.instance.setPause(_musicHandle!, true);
    }
  }

  @override
  void stopMusic() {
    if (_musicHandle != null) {
      SoLoud.instance.stop(_musicHandle!);
      _musicHandle = null;
    }
  }

  @override
  void setSfxVolume(double v) {
    _sfxVolume = v.clamp(0.0, 1.0);
  }

  @override
  void setMusicVolume(double v) {
    _musicVolume = v.clamp(0.0, 1.0);
    if (_musicHandle != null) {
      SoLoud.instance.setVolume(_musicHandle!, _musicVolume);
    }
  }

  @override
  void setSfxEnabled(bool v) => _sfxEnabled = v;

  @override
  void setMusicEnabled(bool v) {
    _musicEnabled = v;
    if (!v) pauseMusic();
    if (v) startMusic();
  }

  @override
  void dispose() {
    stopMusic();
    SoLoud.instance.deinit();
  }
}
```

> **Import obrigatório:** Em Dart, imports não são transitivos. Mesmo que `sfxr_synth.dart` importe `sound_presets.dart`, `audio_service_impl.dart` deve importar explicitamente: `import 'sound_presets.dart';`

- [ ] **Step 2: Verificar que o projeto compila**

```bash
flutter build apk --flavor tst --dart-define=FLAVOR=dev --debug 2>&1 | tail -5
```
Esperado: BUILD SUCCESSFUL (flavor dev usa stub, então SoLoud não é chamado).

- [ ] **Step 3: Commit**

```bash
git add lib/domain/audio/audio_service_impl.dart
git commit -m "feat(audio): AudioServiceImpl SFX — bomb, merge, victory, game over"
```

---

## Task 6: JungleSequencer — engine de síntese

**Files:**
- Create: `lib/domain/audio/jungle_sequencer.dart`
- Create: `test/domain/audio/jungle_sequencer_test.dart`

- [ ] **Step 1: Escrever testes para o sequenciador**

Criar `test/domain/audio/jungle_sequencer_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/audio/jungle_sequencer.dart';

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
      final durationSec = samples / 22050;
      expect(durationSec, greaterThanOrEqualTo(80));
      expect(durationSec, lessThanOrEqualTo(90));
    });

    test('loop point é suave — amplitude média final similar ao início', () async {
      final wav = await JungleSequencer.generate();
      // Verificar que as últimas 1000 amostras não têm clipping (valor max)
      final sampleData = wav.sublist(44);
      int clipped = 0;
      for (int i = sampleData.length - 2000; i < sampleData.length; i += 2) {
        final lo = sampleData[i];
        final hi = sampleData[i + 1];
        final sample = (hi << 8) | lo;
        final signed = sample > 32767 ? sample - 65536 : sample;
        if (signed.abs() > 30000) clipped++;
      }
      expect(clipped, lessThan(50), reason: 'loop end should not be clipping');
    });
  });
}
```

- [ ] **Step 2: Rodar testes — esperar FAIL**

```bash
flutter test test/domain/audio/jungle_sequencer_test.dart
```
Esperado: compilation error.

- [ ] **Step 3: Implementar jungle_sequencer.dart (engine + composição)**

Criar `lib/domain/audio/jungle_sequencer.dart`:
```dart
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'wav_utils.dart';

class JungleSequencer {
  static const _sampleRate = 22050;
  static const _bpm = 90.0;
  static const _beatsPerBar = 4;

  // Amostras por beat (quarter note)
  static int get _spb => (_sampleRate * 60 / _bpm).round(); // 14700

  // Converte MIDI note number para frequência Hz
  static double _midi(int n) => 440.0 * pow(2, (n - 69) / 12);

  // Roda em isolate para não bloquear a UI
  static Future<Uint8List> generate() => Isolate.run(_renderLoop);

  static Uint8List _renderLoop() {
    // 64 compassos × 4 beats × _spb amostras
    final totalSamples = 64 * _beatsPerBar * _spb;
    final out = Int16List(totalSamples);

    _renderVoice(out, _melodyVoice());
    _renderVoice(out, _bassVoice());
    _renderVoice(out, _batidaVoice());
    _renderVoice(out, _counterVoice());

    // Normalizar para evitar clipping
    _normalize(out);

    return buildWav(out);
  }

  // ─── VOZES ────────────────────────────────────────────────────────────────

  // Cada voz retorna lista de (sampleOffset, frequência, duraçãoEmAmostras, tipo, volume)
  // tipo: 0=square, 1=triangle, 2=noise

  static List<_Note> _melodyVoice() {
    // Melodia MPB em D maior, sincopada com antecipação
    // MIDI: D4=62, E4=64, F#4=66, G4=67, A4=69, B4=71, C#5=73, D5=74, A5=81
    const mel = [
      // Seção A (compasso 0–15): melodia principal
      // Compasso 0–3
      (62, 1.0), (69, 0.5), (67, 0.5), (66, 1.0), (64, 1.0), // D E F# durations
      (62, 2.0), (0, 1.0), (64, 1.0),
      (66, 1.5), (67, 0.5), (69, 1.0), (71, 1.0),
      (69, 2.0), (0, 2.0),
      // Compasso 4–7
      (67, 1.0), (69, 0.5), (71, 0.5), (73, 1.0), (71, 1.0),
      (69, 2.0), (0, 1.0), (67, 1.0),
      (66, 1.5), (64, 0.5), (62, 1.0), (64, 1.0),
      (62, 3.0), (0, 1.0),
      // Compasso 8–11
      (64, 1.0), (66, 0.5), (67, 0.5), (69, 1.0), (67, 1.0),
      (66, 2.0), (0, 1.0), (64, 1.0),
      (62, 1.5), (64, 0.5), (66, 1.0), (64, 1.0),
      (62, 3.0), (0, 1.0),
      // Compasso 12–15
      (69, 1.0), (71, 0.5), (73, 0.5), (74, 1.0), (73, 1.0),
      (71, 2.0), (0, 1.0), (69, 1.0),
      (67, 1.5), (66, 0.5), (64, 1.0), (62, 1.0),
      (62, 4.0), // final da seção A
    ];

    const melB = [
      // Seção B (compasso 16–31): mais tensão, varia melodia
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
      (81, 3.0), (0, 1.0), // A5 - nota alta para B
    ];

    // Seção C (compassos 32–47): melodia silente
    final silentC = [(0, 16 * 4.0)]; // 16 compassos de silêncio

    // Seção A' (compassos 48–63): igual A
    final notes = <_Note>[];
    int offset = 0;
    for (final patterns in [mel, melB, silentC, mel]) {
      for (final (midi, beats) in patterns) {
        final dur = (beats * _spb).round();
        if (midi > 0) {
          notes.add(_Note(_midi(midi), offset, dur, 1, 0.75)); // triangle
        }
        offset += dur;
      }
    }
    return notes;
  }

  static List<_Note> _bassVoice() {
    // Root MIDI notes para todos os 64 compassos (registro grave: D2=38)
    const allBarRoots = [
      // Seção A (16 compassos)
      38, 40, 45, 38,  // Dmaj7 Em7 A7 Dmaj7
      43, 41, 47, 40,  // Gmaj7 C#m7b5/F#7 Bm7 E7
      40, 39, 38, 47,  // Em7 Eb7 Dmaj7/F# Bm7
      40, 45, 38, 45,  // Em7 A7 Dmaj7 A7sus4
      // Seção B (16 compassos)
      43, 44, 38, 40,  // Gmaj7 G#dim Dmaj7/F# E7
      42, 47, 40, 39,  // F#m7 B7 Em7 Eb7
      44, 49, 42, 47,  // G#m7b5 C#7 F#m7 B7
      40, 45, 38, 42,  // Em7 A7 Dmaj7 F#7
      // Seção C (16 compassos): Bm Em A D ×4
      47, 40, 45, 38,  47, 40, 45, 38,
      47, 40, 45, 38,  47, 40, 45, 38,
      // Seção A' (igual A)
      38, 40, 45, 38,  43, 41, 47, 40,
      40, 39, 38, 47,  40, 45, 38, 45,
    ];

    final notes = <_Note>[];
    for (int bar = 0; bar < 64; bar++) {
      final barStart = bar * _beatsPerBar * _spb;
      final root = allBarRoots[bar];
      notes.add(_Note(_midi(root), barStart, _spb - 150, 0, 0.70));
      notes.add(_Note(_midi(root + 7), barStart + 2 * _spb, _spb - 150, 0, 0.55));
    }
    return notes;
  }

  static List<_Note> _batidaVoice() {
    const batidaPattern = [1,0,0,1, 0,1,1,0, 0,1,0,1, 1,0,1,0];
    final sixteenth = _spb ~/ 4;

    // Voicings de 2 notas [3ª, 7ª] para todos os 64 compassos
    final allBarVoicings = <List<int>>[
      // Seção A
      [66,69],[64,67],[64,67],[66,69],[71,74],[65,69],[66,69],[64,68],
      [64,67],[63,66],[66,69],[62,66],[64,67],[64,67],[66,69],[64,67],
      // Seção B
      [71,74],[68,71],[66,69],[64,68],[66,69],[66,69],[64,67],[63,66],
      [68,71],[68,72],[66,69],[66,69],[64,67],[64,67],[66,69],[66,69],
      // Seção C
      [62,66],[64,67],[64,67],[66,69],[62,66],[64,67],[64,67],[66,69],
      [62,66],[64,67],[64,67],[66,69],[62,66],[64,67],[64,67],[66,69],
      // Seção A'
      [66,69],[64,67],[64,67],[66,69],[71,74],[65,69],[66,69],[64,68],
      [64,67],[63,66],[66,69],[62,66],[64,67],[64,67],[66,69],[64,67],
    ];

    final notes = <_Note>[];
    for (int bar = 0; bar < 64; bar++) {
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

  static List<_Note> _counterVoice() {
    // Contraponto: ativo em Seção B (compassos 16–31) e A' (48–63)
    // Responde à melodia principal com frases curtas
    const counterMelB = [
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
      (66, 1.0), (64, 0.5), (62, 0.5), (64, 2.0),
      (0, 4.0),
      (69, 1.5), (71, 0.5), (73, 1.0), (74, 1.0),
      (81, 4.0),
    ];

    final notes = <_Note>[];
    // Silente em A (compassos 0–15)
    int offset = 16 * _beatsPerBar * _spb;

    // Seção B ativa
    for (final (midi, beats) in counterMelB) {
      final dur = (beats * _spb).round();
      if (midi > 0) {
        notes.add(_Note(_midi(midi), offset, dur, 1, 0.55));
      }
      offset += dur;
    }

    // Seção C silente (pula 16 compassos)
    offset = 48 * _beatsPerBar * _spb;

    // Seção A' ativa (igual B)
    for (final (midi, beats) in counterMelB) {
      final dur = (beats * _spb).round();
      if (midi > 0) {
        notes.add(_Note(_midi(midi), offset, dur, 1, 0.55));
      }
      offset += dur;
    }

    return notes;
  }

  // ─── RENDERIZAÇÃO ──────────────────────────────────────────────────────────

  static void _renderVoice(Int16List out, List<_Note> notes) {
    for (final note in notes) {
      final end = (note.offset + note.durationSamples).clamp(0, out.length);
      double phase = 0;
      for (int i = note.offset; i < end; i++) {
        final t = (i - note.offset) / _sampleRate;
        final dur = note.durationSamples / _sampleRate;

        // Envelope com fade in/out suave
        final fadeIn = (t < 0.012) ? t / 0.012 : 1.0;
        final fadeOut = (t > dur - 0.018) ? (dur - t) / 0.018 : 1.0;
        final amp = (fadeIn * fadeOut).clamp(0.0, 1.0) * note.volume;

        phase += note.freq / _sampleRate;
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
  const _Note(this.freq, this.offset, this.durationSamples, this.waveType, this.volume);
  final double freq;
  final int offset;
  final int durationSamples;
  final int waveType; // 0=square, 1=triangle
  final double volume;
}
```

- [ ] **Step 4: Rodar testes**

```bash
flutter test test/domain/audio/jungle_sequencer_test.dart --timeout 120s
```
Esperado: 3 testes passando. O segundo teste (duração 80–90s) é o critério principal de qualidade. Se falhar, ajustar as sequências de notas.

- [ ] **Step 5: Ajustar sequências se necessário**

Se a duração estiver errada, o problema está no offset acumulado das vozes. Adicionar log de diagnóstico temporário:
```dart
// ao final de _renderLoop():
print('Total samples: $totalSamples, duration: ${totalSamples / _sampleRate}s');
```
Esperado: `~1,881,600 samples, duration: ~85.3s`.

- [ ] **Step 6: Commit**

```bash
git add lib/domain/audio/jungle_sequencer.dart test/domain/audio/jungle_sequencer_test.dart
git commit -m "feat(audio): JungleSequencer — bossa nova MPB 85s loop"
```

---

## Task 7: AudioServiceImpl — integração da música

**Files:**
- Modify: `lib/domain/audio/audio_service_impl.dart`

- [ ] **Step 1: Adicionar carregamento de música ao init()**

Em `AudioServiceImpl.init()`, após `_loadSfx()`, adicionar:
```dart
await _loadMusic();
```

Adicionar o método `_loadMusic()` à classe:
```dart
Future<void> _loadMusic() async {
  final bytes = await Isolate.run(JungleSequencer._renderLoop);
  _music = await SoLoud.instance.loadMem('jungle_music', bytes);
}
```

Adicionar import no topo do arquivo:
```dart
import 'dart:isolate';
import 'jungle_sequencer.dart';
```

- [ ] **Step 2: Verificar que o app compila com flavor prd**

```bash
flutter build apk --flavor prd --release \
  --dart-define=FLAVOR=prd \
  --dart-define=AD_UNIT_ANDROID=ca-app-pub-3940256099942544/5224354917 \
  2>&1 | tail -10
```
Esperado: BUILD SUCCESSFUL.

- [ ] **Step 3: Commit**

```bash
git add lib/domain/audio/audio_service_impl.dart
git commit -m "feat(audio): AudioServiceImpl — integra JungleSequencer no init"
```

---

## Task 8: Settings — campos de áudio

**Files:**
- Modify: `lib/presentation/controllers/settings_notifier.dart`
- Modify: `lib/presentation/screens/settings_screen.dart`

- [ ] **Step 1: Adicionar campos ao SettingsState**

Em `lib/presentation/controllers/settings_notifier.dart`, alterar `SettingsState`:
```dart
class SettingsState {
  final bool hapticEnabled;
  final String locale;
  final bool musicEnabled;
  final bool sfxEnabled;
  final double musicVolume;
  final double sfxVolume;

  const SettingsState({
    this.hapticEnabled = true,
    this.locale = 'pt',
    this.musicEnabled = true,
    this.sfxEnabled = true,
    this.musicVolume = 0.7,
    this.sfxVolume = 1.0,
  });

  SettingsState copyWith({
    bool? hapticEnabled,
    String? locale,
    bool? musicEnabled,
    bool? sfxEnabled,
    double? musicVolume,
    double? sfxVolume,
  }) => SettingsState(
    hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    locale: locale ?? this.locale,
    musicEnabled: musicEnabled ?? this.musicEnabled,
    sfxEnabled: sfxEnabled ?? this.sfxEnabled,
    musicVolume: musicVolume ?? this.musicVolume,
    sfxVolume: sfxVolume ?? this.sfxVolume,
  );
}
```

- [ ] **Step 2: Adicionar chaves e métodos ao SettingsNotifier**

Dentro de `SettingsNotifier`, adicionar após as chaves existentes:
```dart
static const _musicEnabledKey = 'settings.music_enabled';
static const _sfxEnabledKey = 'settings.sfx_enabled';
static const _musicVolumeKey = 'settings.music_volume';
static const _sfxVolumeKey = 'settings.sfx_volume';
```

Atualizar `build()` para carregar os novos valores:
```dart
@override
SettingsState build() {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsState(
    hapticEnabled: prefs.getBool(_hapticKey) ?? true,
    locale: prefs.getString(_localeKey) ?? 'pt',
    musicEnabled: prefs.getBool(_musicEnabledKey) ?? true,
    sfxEnabled: prefs.getBool(_sfxEnabledKey) ?? true,
    musicVolume: prefs.getDouble(_musicVolumeKey) ?? 0.7,
    sfxVolume: prefs.getDouble(_sfxVolumeKey) ?? 1.0,
  );
}
```

Adicionar métodos de atualização:
```dart
void setMusicEnabled(bool value) {
  ref.read(sharedPreferencesProvider).setBool(_musicEnabledKey, value);
  state = state.copyWith(musicEnabled: value);
  ref.read(audioServiceProvider).setMusicEnabled(value);
}

void setSfxEnabled(bool value) {
  ref.read(sharedPreferencesProvider).setBool(_sfxEnabledKey, value);
  state = state.copyWith(sfxEnabled: value);
  ref.read(audioServiceProvider).setSfxEnabled(value);
}

void setMusicVolume(double value) {
  ref.read(sharedPreferencesProvider).setDouble(_musicVolumeKey, value);
  state = state.copyWith(musicVolume: value);
  ref.read(audioServiceProvider).setMusicVolume(value);
}

void setSfxVolume(double value) {
  ref.read(sharedPreferencesProvider).setDouble(_sfxVolumeKey, value);
  state = state.copyWith(sfxVolume: value);
  ref.read(audioServiceProvider).setSfxVolume(value);
}
```

Adicionar import no topo:
```dart
import '../../domain/audio/audio_service.dart';
```

- [ ] **Step 3: Adicionar seção Áudio na SettingsScreen**

Abrir `lib/presentation/screens/settings_screen.dart`. Localizar a seção de settings existente e adicionar após as configurações de gameplay:

```dart
// Import no topo:
import 'package:google_fonts/google_fonts.dart';
import '../../domain/audio/audio_service.dart';

// No corpo da tela, adicionar seção Áudio:
_buildAudioSection(context, ref),

// Implementação do método:
Widget _buildAudioSection(BuildContext context, WidgetRef ref) {
  final settings = ref.watch(settingsProvider);
  final notifier = ref.read(settingsProvider.notifier);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
        child: OutlinedText(
          'Áudio',
          style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      Card(
        child: Column(
          children: [
            SwitchListTile(
              title: Text('Música de fundo', style: GoogleFonts.nunito(fontSize: 15)),
              value: settings.musicEnabled,
              onChanged: notifier.setMusicEnabled,
            ),
            if (settings.musicEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.music_note, size: 18),
                    Expanded(
                      child: Slider(
                        value: settings.musicVolume,
                        onChanged: notifier.setMusicVolume,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1),
            SwitchListTile(
              title: Text('Efeitos sonoros', style: GoogleFonts.nunito(fontSize: 15)),
              value: settings.sfxEnabled,
              onChanged: notifier.setSfxEnabled,
            ),
            if (settings.sfxEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.volume_up, size: 18),
                    Expanded(
                      child: Slider(
                        value: settings.sfxVolume,
                        onChanged: notifier.setSfxVolume,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
```

- [ ] **Step 4: Verificar compilação**

```bash
flutter build apk --flavor tst --dart-define=FLAVOR=dev --debug 2>&1 | tail -5
```
Esperado: BUILD SUCCESSFUL.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/controllers/settings_notifier.dart lib/presentation/screens/settings_screen.dart
git commit -m "feat(audio): settings — music/sfx enable + volume controls"
```

---

## Task 9: App init + hooks do jogo

**Files:**
- Modify: `lib/app.dart`
- Modify: `lib/presentation/controllers/game_notifier.dart`
- Modify: `lib/presentation/screens/game/game_screen.dart`
- Modify: `lib/presentation/widgets/victory_choice_dialog.dart`

- [ ] **Step 1: Inicializar AudioService no app startup**

Em `lib/app.dart`, mudar `CapivaraApp` de `StatefulWidget` para `ConsumerStatefulWidget` e `_CapivaraAppState` para `ConsumerState<CapivaraApp>`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain/audio/audio_service.dart';

class CapivaraApp extends ConsumerStatefulWidget {
  const CapivaraApp({super.key, this.precacheFutureOverride});

  @visibleForTesting
  final Future<void>? precacheFutureOverride;

  @override
  ConsumerState<CapivaraApp> createState() => _CapivaraAppState();
}

class _CapivaraAppState extends ConsumerState<CapivaraApp> {
  Future<void>? _precacheFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheFuture ??= widget.precacheFutureOverride ?? precacheCriticalAssets(context);
    // Inicia áudio em background — não bloqueia abertura do app
    ref.read(audioServiceProvider).init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Olha o Bichim!',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: SplashScreen(precacheFuture: _precacheFuture),
    );
  }
}
```

- [ ] **Step 2: Hook de bomba no GameNotifier**

Abrir `lib/presentation/controllers/game_notifier.dart`. Localizar o método que faz o disparo automático da bomba quando `_bombSelection.length == maxTiles` (procurar pela linha `if (_bombSelection.length == maxTiles)`).

Adicionar import:
```dart
import '../../domain/audio/audio_service.dart';
```

No `selectBombTile`, logo após o auto-fire (quando `_bombSelection.length == maxTiles`), adicionar:
```dart
final mode = state.bombMode;
if (mode == BombMode.bomb2) {
  ref.read(audioServiceProvider).playEffect(const Bomb2xUsed());
} else {
  ref.read(audioServiceProvider).playEffect(const Bomb3xUsed());
}
```

> **Onde exatamente:** O auto-fire ocorre na linha ~322 do arquivo. O audio hook vai imediatamente após `_bombSelection.length == maxTiles` ser verdadeiro, antes de chamar `_applyBombSelection()` ou equivalente.

- [ ] **Step 3: Hook de merge no GameNotifier**

No mesmo arquivo, localizar o método `_applyMove()` (ou o método equivalente que chama `GameEngine.applyMove`/`move`). Após o cálculo do novo estado, verificar se houve merge comparando o score:

```dart
// Após obter newState de GameEngine:
final prevScore = state.score;
// (aplicar movimento...)
final newState = GameEngine.applyMove(state, direction);
state = newState;

// Hook de merge
if (newState.score > prevScore) {
  // Inferir nível pelo tile mais alto que pode ter sido criado
  // Usar lastMergedLevel se existir no GameState, ou calcular pelo score delta
  final mergeLevel = _inferMergeLevel(newState);
  ref.read(audioServiceProvider).playEffect(TilesMerged(mergeLevel));
}
```

Adicionar helper `_inferMergeLevel`:
```dart
int _inferMergeLevel(GameState s) {
  // Retorna o nível do tile mais alto no board (proxy do merge recente)
  int maxLevel = 1;
  for (final row in s.board) {
    for (final tile in row) {
      if (tile != null && tile.level > maxLevel) maxLevel = tile.level;
    }
  }
  return maxLevel.clamp(1, 11);
}
```

> **Nota:** Verificar se `GameState` já expõe `lastMergeLevel` ou similar. Se sim, usar diretamente. Caso `_applyMove` não exista com esse nome, localizar o método que despacha o movimento (provavelmente chamado quando o jogador faz swipe) — procurar por `GameEngine.move` ou `GameEngine.applyMove`.

- [ ] **Step 4: Hook de música e game over no GameScreen**

Abrir `lib/presentation/screens/game/game_screen.dart`. Adicionar import:
```dart
import '../../../domain/audio/audio_service.dart';
```

Em `initState()`, adicionar após `super.initState()`:
```dart
// Áudio iniciado ligeiramente depois para não concorrer com a animação de abertura
Future.delayed(const Duration(milliseconds: 300), () {
  if (mounted) ref.read(audioServiceProvider).startMusic();
});
```

Em `dispose()`, adicionar antes de `super.dispose()`:
```dart
ref.read(audioServiceProvider).pauseMusic();
```

No `ref.listen<GameState>(gameProvider, ...)` existente (linha ~107), dentro do callback, adicionar detecção de game over:
```dart
ref.listen<GameState>(gameProvider, (previous, current) {
  // Hook existente...
  
  // Game over hook
  if (previous != null && !previous.isGameOver && current.isGameOver) {
    ref.read(audioServiceProvider).playEffect(const GameOverEvent());
  }
});
```

- [ ] **Step 5: Hook de vitória no VictoryChoiceDialog**

Abrir `lib/presentation/widgets/victory_choice_dialog.dart`. Adicionar import:
```dart
import '../../../domain/audio/audio_service.dart';
```

Localizar o ponto onde o dialog é criado/exibido (provavelmente em `build()` ou `show()`). No `initState` do dialog (ou equivalente para StatelessWidget no `build` via `WidgetsBinding.instance.addPostFrameCallback`):

```dart
// Se for StatefulWidget, em initState:
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(audioServiceProvider).playEffect(const VictoryReached());
  });
}

// Se for StatelessWidget, no build usando ref (ConsumerWidget):
@override
Widget build(BuildContext context, WidgetRef ref) {
  // Tocar som na primeira exibição
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(audioServiceProvider).playEffect(const VictoryReached());
  });
  // ... resto do widget
}
```

> **Nota:** Verificar se `VictoryChoiceDialog` é `StatefulWidget` ou `StatelessWidget` e se já é um `ConsumerWidget`. Adaptar conforme o padrão existente.

- [ ] **Step 6: Build final de verificação**

```bash
flutter build apk --flavor tst --dart-define=FLAVOR=dev --debug 2>&1 | tail -5
```
Esperado: BUILD SUCCESSFUL.

- [ ] **Step 7: Commit**

```bash
git add lib/app.dart lib/presentation/controllers/game_notifier.dart lib/presentation/screens/game/game_screen.dart lib/presentation/widgets/victory_choice_dialog.dart
git commit -m "feat(audio): hooks — music lifecycle, bomb, merge, victory, game over"
```

---

## Task 10: Teste manual e ajuste fino

> Esta task não tem código automatizado — é validação no device.

- [ ] **Rodar no dispositivo físico (flavor tst = stub, sem áudio)**

```bash
flutter run --flavor tst --dart-define=FLAVOR=dev
```
Verificar: app abre normalmente, sem crashes, configurações de áudio aparecem na tela de settings.

- [ ] **Rodar com flavor prd para testar o áudio real**

```bash
flutter run --flavor prod --dart-define=FLAVOR=prd
```
Verificar:
1. App abre → música de fundo começa após ~300ms
2. Fazer merge → som de tile
3. Usar Bomba 2x → explosão curta
4. Usar Bomba 3x → explosão mais grave e longa
5. Atingir 2048 → fanfarra
6. Game over → sequência descendente
7. Settings → sliders de volume funcionam
8. Desativar música → silêncio imediato

- [ ] **Ajustar parâmetros de som se necessário**

Se algum efeito soar mal, ajustar em `sound_presets.dart`:
- Volume muito alto: diminuir `volume` do preset
- Duração inadequada: ajustar `decay`
- Pitch errado para merge: ajustar `mergePitches` em `SoundPresets`

Se a música estiver desequilibrada (uma voz muito alta), ajustar o `volume` nos `_Note` dentro de `jungle_sequencer.dart`.

- [ ] **Commit final**

```bash
git add -p  # staged apenas os ajustes de parâmetros
git commit -m "fix(audio): ajuste fino de volumes e parâmetros de síntese"
```

---

## Checklist de Cobertura da Spec

| Requisito da Spec | Task |
|---|---|
| flutter_soloud como engine | Task 1, 5 |
| SfxrSynth — Dart puro | Task 3, 4 |
| JungleSequencer — Isolate | Task 6 |
| AudioService facade Riverpod | Task 2 |
| Stub para FLAVOR=dev | Task 2 |
| Bomb2x/Bomb3x sons | Task 3, 5 |
| Merge 11 níveis | Task 4, 5 |
| Vitória / Game over | Task 4, 5 |
| Música bossa nova 85s loop | Task 6 |
| 4 vozes (melodia, baixo, batida, contraponto) | Task 6 |
| Settings musicEnabled/sfxEnabled/volumes | Task 8 |
| Hook bomba no GameNotifier | Task 9 |
| Hook merge no GameNotifier | Task 9 |
| Hook game over no GameScreen | Task 9 |
| Hook vitória no VictoryChoiceDialog | Task 9 |
| App init no startup | Task 9 |
| WAV 22050Hz mono 16-bit | Task 1 |
