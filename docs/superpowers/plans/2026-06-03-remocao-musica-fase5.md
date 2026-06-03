# Remoção da Música de Fundo + Encerramento Fase 5 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remover completamente a música de fundo do produto, manter SFX, atualizar CAPIVARA_2048_DESIGN.md com o sistema de áudio real, e encerrar a fase 5.

**Architecture:** Remoção cirúrgica em camadas — interface pública primeiro, implementação depois, UI depois, dead code por último. Cada task compila e passa nos testes antes do commit. Sem novos arquivos; apenas edições e deleções.

**Tech Stack:** Flutter/Dart, `flutter_soloud`, `flutter_riverpod`, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-06-03-remocao-musica-encerramento-fase5-design.md`

---

## File Map

| Arquivo | Operação |
| --- | --- |
| `lib/domain/audio/audio_service.dart` | Editar — remover 5 métodos da interface |
| `lib/domain/audio/audio_service_stub.dart` | Editar — remover 5 métodos |
| `lib/domain/audio/audio_service_impl.dart` | Editar — remover campos/métodos de música |
| `lib/presentation/controllers/settings_notifier.dart` | Editar — remover música do state/notifier |
| `lib/presentation/screens/settings_screen.dart` | Editar — remover bloco "Música de fundo" |
| `lib/presentation/screens/game/game_screen.dart` | Editar — remover startMusic/pauseMusic |
| `lib/domain/audio/animal_voices.dart` | Editar — remover `voiceSamples()` (dead code) |
| `lib/domain/audio/jungle_sequencer.dart` | **Deletar** |
| `test/domain/audio/jungle_sequencer_test.dart` | **Deletar** |
| `test/domain/audio/audio_service_test.dart` | Editar — remover teste de music controls |
| `test/domain/audio/animal_voices_test.dart` | Editar — remover teste de voiceSamples |
| `CAPIVARA_2048_DESIGN.md` | Editar — atualizar seção de áudio |
| `CLAUDE.md` | Editar — fase 5→✅, fase atual→6 |
| `AGENTS.md` | Editar — idem |
| `CHANGELOG.md` | Editar — entrada v1.9.29 |
| `pubspec.yaml` | Editar — bump 1.9.28+34 → 1.9.29+35 |

---

## Task 1: Interface AudioService + Stub — remover métodos de música

**Files:**
- Modify: `lib/domain/audio/audio_service.dart`
- Modify: `lib/domain/audio/audio_service_stub.dart`
- Test: `test/domain/audio/audio_service_test.dart`

- [ ] **Step 1: Atualizar o teste — remover grupo de music controls**

Em `test/domain/audio/audio_service_test.dart`, remover o grupo inteiro (linhas 26-34):

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
      expect(() => stub.playEffect(const AnimalReached(8)), returnsNormally);
      expect(() => stub.playEffect(const Undo1Used()), returnsNormally);
      expect(() => stub.playEffect(const Undo3Used()), returnsNormally);
      expect(() => stub.playEffect(const VictoryReached()), returnsNormally);
      expect(() => stub.playEffect(const GameOver()), returnsNormally);
    });

    test('sfx volume and enabled do not throw', () {
      expect(() => stub.setSfxVolume(0.5), returnsNormally);
      expect(() => stub.setSfxEnabled(false), returnsNormally);
    });
  });
}
```

(O grupo `music control methods do not throw` foi removido; substituído por `sfx volume and enabled do not throw` que testa só o que ainda existe.)

- [ ] **Step 2: Run test to see current state**

Run: `flutter test test/domain/audio/audio_service_test.dart`
Expected: PASS (o teste novo ainda passa pois setSfxVolume/setSfxEnabled existem; o teste antigo de music foi removido antes de mudar a interface, o que é correto pois não há mais necessidade de testar o que vai sumir).

- [ ] **Step 3: Atualizar a interface AudioService**

Substituir `lib/domain/audio/audio_service.dart` por:

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

class VictoryReached extends GameSoundEvent {
  const VictoryReached();
}

class GameOver extends GameSoundEvent {
  const GameOver();
}

abstract class AudioService {
  Future<void> init();
  void dispose();

  void playEffect(GameSoundEvent event);

  void setSfxVolume(double v);
  void setSfxEnabled(bool v);
}

final audioServiceProvider = Provider<AudioService>((ref) {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: '');
  final service = flavor.isNotEmpty ? AudioServiceImpl() : AudioServiceStub();
  ref.onDispose(service.dispose);
  return service;
});
```

- [ ] **Step 4: Atualizar o stub**

Substituir `lib/domain/audio/audio_service_stub.dart` por:

```dart
import 'audio_service.dart';

class AudioServiceStub implements AudioService {
  @override Future<void> init() async {}
  @override void dispose() {}
  @override void playEffect(GameSoundEvent event) {}
  @override void setSfxVolume(double v) {}
  @override void setSfxEnabled(bool v) {}
}
```

- [ ] **Step 5: Verificar que o analyze detecta os erros esperados (impl e notifier ainda têm os métodos)**

Run: `flutter analyze lib/domain/audio/audio_service_impl.dart lib/presentation/controllers/settings_notifier.dart`
Expected: erros de método não pertence à interface (serão corrigidos nas tasks seguintes). Isso confirma que as classes concretas ainda precisam ser atualizadas.

- [ ] **Step 6: Commit**

```bash
git add lib/domain/audio/audio_service.dart lib/domain/audio/audio_service_stub.dart test/domain/audio/audio_service_test.dart
git commit -m "feat(audio): remover interface e stub de música de fundo"
```

---

## Task 2: AudioServiceImpl — remover implementação de música

**Files:**
- Modify: `lib/domain/audio/audio_service_impl.dart`

- [ ] **Step 1: Substituir o arquivo**

Substituir `lib/domain/audio/audio_service_impl.dart` por:

```dart
import 'dart:async';

import 'package:flutter_soloud/flutter_soloud.dart';

import 'animal_voices.dart';
import 'audio_service.dart';
import 'sfxr_synth.dart';
import 'sound_presets.dart';

class AudioServiceImpl implements AudioService {
  AudioSource? _bomb2x;
  AudioSource? _bomb3x;
  final _mergeSounds = <int, AudioSource>{};
  final _animalVoices = <int, AudioSource>{};
  AudioSource? _undo1;
  AudioSource? _undo3;
  AudioSource? _victory;
  AudioSource? _gameOver;

  double _sfxVolume = 1.0;
  bool _sfxEnabled = true;

  @override
  Future<void> init() async {
    await SoLoud.instance.init();
    await _loadSfx();
  }

  Future<void> _loadSfx() async {
    final synth = SfxrSynth();
    _bomb2x = await SoLoud.instance.loadMem('bomb2x', synth.generate(SoundPresets.bomb2x));
    _bomb3x = await SoLoud.instance.loadMem('bomb3x', synth.generate(SoundPresets.bomb3x));
    for (int level = 1; level <= 11; level++) {
      _mergeSounds[level] = await SoLoud.instance.loadMem(
        'merge_$level',
        synth.generateMerge(level),
      );
    }
    for (int level = 1; level <= 11; level++) {
      _animalVoices[level] = await SoLoud.instance.loadMem(
        'animal_$level',
        AnimalVoices.voice(level),
      );
    }
    _undo1 = await SoLoud.instance.loadMem('undo1', synth.generateUndo1());
    _undo3 = await SoLoud.instance.loadMem('undo3', synth.generateUndo3());
    _victory = await SoLoud.instance.loadMem('victory', synth.generateVictory());
    _gameOver = await SoLoud.instance.loadMem('gameover', synth.generateGameOver());
  }

  @override
  void playEffect(GameSoundEvent event) {
    if (!_sfxEnabled) return;
    final source = switch (event) {
      Bomb2xUsed() => _bomb2x,
      Bomb3xUsed() => _bomb3x,
      TilesMerged(:final level) => _mergeSounds[level.clamp(1, 11)],
      AnimalReached(:final level) => _animalVoices[level.clamp(1, 11)],
      Undo1Used() => _undo1,
      Undo3Used() => _undo3,
      VictoryReached() => _victory,
      GameOver() => _gameOver,
    };
    if (source != null) {
      unawaited(SoLoud.instance.play(source, volume: _sfxVolume));
    }
  }

  @override
  void setSfxVolume(double v) {
    _sfxVolume = v.clamp(0.0, 1.0);
  }

  @override
  void setSfxEnabled(bool v) => _sfxEnabled = v;

  @override
  void dispose() {
    SoLoud.instance.deinit();
  }
}
```

- [ ] **Step 2: Verificar analyze**

Run: `flutter analyze lib/domain/audio/audio_service_impl.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/domain/audio/audio_service_impl.dart
git commit -m "feat(audio): AudioServiceImpl — remover música, manter SFX"
```

---

## Task 3: SettingsNotifier — remover estado e métodos de música

**Files:**
- Modify: `lib/presentation/controllers/settings_notifier.dart`

- [ ] **Step 1: Substituir o arquivo**

Substituir `lib/presentation/controllers/settings_notifier.dart` por:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/audio/audio_service.dart';

class SettingsState {
  final bool hapticEnabled;
  final String locale;
  final bool sfxEnabled;
  final double sfxVolume;

  const SettingsState({
    this.hapticEnabled = true,
    this.locale = 'pt',
    this.sfxEnabled = true,
    this.sfxVolume = 1.0,
  });

  SettingsState copyWith({
    bool? hapticEnabled,
    String? locale,
    bool? sfxEnabled,
    double? sfxVolume,
  }) => SettingsState(
    hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    locale: locale ?? this.locale,
    sfxEnabled: sfxEnabled ?? this.sfxEnabled,
    sfxVolume: sfxVolume ?? this.sfxVolume,
  );
}

/// Must be overridden in ProviderScope/ProviderContainer with the real instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

class SettingsNotifier extends Notifier<SettingsState> {
  static const _hapticKey = 'settings.haptic_enabled';
  static const _localeKey = 'settings.locale';
  static const _sfxEnabledKey = 'settings.sfx_enabled';
  static const _sfxVolumeKey = 'settings.sfx_volume';

  @override
  SettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return SettingsState(
      hapticEnabled: prefs.getBool(_hapticKey) ?? true,
      locale: prefs.getString(_localeKey) ?? 'pt',
      sfxEnabled: prefs.getBool(_sfxEnabledKey) ?? true,
      sfxVolume: prefs.getDouble(_sfxVolumeKey) ?? 1.0,
    );
  }

  void setHaptic(bool value) {
    ref.read(sharedPreferencesProvider).setBool(_hapticKey, value);
    state = state.copyWith(hapticEnabled: value);
  }

  void setLocale(String locale) {
    ref.read(sharedPreferencesProvider).setString(_localeKey, locale);
    state = state.copyWith(locale: locale);
  }

  void setSfxEnabled(bool value) {
    ref.read(sharedPreferencesProvider).setBool(_sfxEnabledKey, value);
    state = state.copyWith(sfxEnabled: value);
    ref.read(audioServiceProvider).setSfxEnabled(value);
  }

  void setSfxVolume(double value) {
    ref.read(sharedPreferencesProvider).setDouble(_sfxVolumeKey, value);
    state = state.copyWith(sfxVolume: value);
    ref.read(audioServiceProvider).setSfxVolume(value);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
```

- [ ] **Step 2: Verificar analyze**

Run: `flutter analyze lib/presentation/controllers/settings_notifier.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/controllers/settings_notifier.dart
git commit -m "feat(audio): SettingsNotifier — remover musicEnabled/musicVolume"
```

---

## Task 4: SettingsScreen — remover bloco "Música de fundo"

**Files:**
- Modify: `lib/presentation/screens/settings_screen.dart`

- [ ] **Step 1: Remover o bloco da música**

Em `lib/presentation/screens/settings_screen.dart`, localizar e remover as linhas do `SwitchListTile` de "Música de fundo" mais o `if (settings.musicEnabled)` com o `Padding`/`Slider` abaixo. O bloco vai da linha ~169 até a linha ~191 (inclusive o `const Divider` que separa música de SFX fica).

O trecho a remover (substituir pelo trecho seguinte ao divider):

```dart
                  SwitchListTile(
                    tileColor: Colors.transparent,
                    title: Text('Música de fundo', style: GoogleFonts.nunito(fontSize: 16)),
                    value: settings.musicEnabled,
                    onChanged: notifier.setMusicEnabled,
                    activeThumbColor: AppColors.primary,
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
                              activeColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
```

Deve ser substituído apenas por:

```dart
                  const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
```

(O Divider permanece para separar visualmente o campo de Efeitos sonoros dos controles acima, se houver outros. Se for o primeiro item no card, remova o Divider também — verificar o contexto ao redor.)

- [ ] **Step 2: Verificar analyze**

Run: `flutter analyze lib/presentation/screens/settings_screen.dart`
Expected: `No issues found!` (referências a `settings.musicEnabled`, `notifier.setMusicEnabled`, `settings.musicVolume`, `notifier.setMusicVolume` devem sumir).

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/screens/settings_screen.dart
git commit -m "feat(ui): SettingsScreen — remover controles de música"
```

---

## Task 5: GameScreen — remover chamadas de música

**Files:**
- Modify: `lib/presentation/screens/game/game_screen.dart`

- [ ] **Step 1: Remover startMusic e pauseMusic**

Em `lib/presentation/screens/game/game_screen.dart`:

**Remover** o bloco `Future.delayed` inteiro de `initState` (linhas 66-68):

```dart
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) ref.read(audioServiceProvider).startMusic();
    });
```

**Remover** a chamada de `pauseMusic` no `dispose` (linha 81):

```dart
    ref.read(audioServiceProvider).pauseMusic();
```

O `dispose` resultante fica:

```dart
  @override
  void dispose() {
    _fpsMonitorNotifier.stop();
    super.dispose();
  }
```

- [ ] **Step 2: Verificar analyze**

Run: `flutter analyze lib/presentation/screens/game/game_screen.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/screens/game/game_screen.dart
git commit -m "feat(audio): GameScreen — remover startMusic/pauseMusic"
```

---

## Task 6: AnimalVoices — remover voiceSamples (dead code)

**Files:**
- Modify: `lib/domain/audio/animal_voices.dart`
- Modify: `test/domain/audio/animal_voices_test.dart`

- [ ] **Step 1: Remover o grupo voiceSamples do teste**

Em `test/domain/audio/animal_voices_test.dart`, remover o grupo inteiro:

```dart
  group('voiceSamples', () {
    test('retorna buffer sem header WAV', () {
      final samples = AnimalVoices.voiceSamples(3);
      expect(samples.length, greaterThan(0));
    });
  });
```

O arquivo de teste fica com apenas os grupos `mergePluck` e `voice`.

- [ ] **Step 2: Run test to verify it still passes**

Run: `flutter test test/domain/audio/animal_voices_test.dart`
Expected: PASS (3 testes agora em vez de 4).

- [ ] **Step 3: Remover voiceSamples de animal_voices.dart**

Em `lib/domain/audio/animal_voices.dart`, remover o método `voiceSamples` (as linhas com o doc comment e a implementação):

```dart
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
```

- [ ] **Step 4: Verificar analyze + testes**

Run: `flutter analyze lib/domain/audio/animal_voices.dart && flutter test test/domain/audio/animal_voices_test.dart`
Expected: `No issues found!` + PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/audio/animal_voices.dart test/domain/audio/animal_voices_test.dart
git commit -m "feat(audio): AnimalVoices — remover voiceSamples (dead code)"
```

---

## Task 7: Deletar jungle_sequencer.dart + jungle_sequencer_test.dart

**Files:**
- Delete: `lib/domain/audio/jungle_sequencer.dart`
- Delete: `test/domain/audio/jungle_sequencer_test.dart`

- [ ] **Step 1: Deletar os arquivos**

```bash
rm lib/domain/audio/jungle_sequencer.dart
rm test/domain/audio/jungle_sequencer_test.dart
```

- [ ] **Step 2: Rodar suite completa de áudio**

Run: `flutter test test/domain/audio/`
Expected: PASS — todos os testes passam; os arquivos deletados não aparecem mais.

- [ ] **Step 3: Analyze do módulo de áudio**

Run: `flutter analyze lib/domain/audio/`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add -A lib/domain/audio/jungle_sequencer.dart test/domain/audio/jungle_sequencer_test.dart
git commit -m "feat(audio): deletar JungleSequencer — música de fundo removida"
```

(O `-A` inclui os arquivos deletados no staging.)

---

## Task 8: CAPIVARA_2048_DESIGN.md — atualizar seção de áudio

**Files:**
- Modify: `CAPIVARA_2048_DESIGN.md`

- [ ] **Step 1: Atualizar nota de áudio no cabeçalho (linha ~11)**

Substituir:
```
> **Áudio:** segue em **Fase 6**, junto da arte adicional e antes do lançamento; o jogo é desenvolvido sem áudio até lá.
```

Por:
```
> **Áudio:** sistema de SFX procedural implementado na Fase 5 — `flutter_soloud` + `SfxrSynth` + `AnimalVoices`. Sem música de fundo. Ver seção 11 para detalhes.
```

- [ ] **Step 2: Atualizar tabela de bibliotecas (linha ~52)**

Substituir a linha:
```
| Áudio | `audioplayers` ou `just_audio` | Sons e música (Fase 6) |
```
Por:
```
| Áudio | `flutter_soloud` | SFX procedural (implementado) |
```

- [ ] **Step 3: Atualizar estrutura de pastas — remover diretórios de áudio inexistentes (linhas ~155-157)**

Remover as três linhas:
```
├── sounds/animals/                   ← Fase 6
├── sounds/ui/                        ← Fase 6
├── music/                            ← Fase 6
```

O áudio é 100% em memória; esses diretórios nunca foram criados.

- [ ] **Step 4: Atualizar chaves de persistência — remover music_volume (linha ~1130)**

Localizar a linha:
```
| `settings.music_volume` | double 0–1 |
```
E removê-la. Manter `settings.sound_volume` / `settings.sfx_volume` se presentes.

- [ ] **Step 5: Atualizar seção de áudio/fase 6 (linha ~1673)**

Localizar o bloco que começa com:
```
**Sons dos 13 animais e UI + música ambiente.** Esta fase entra **depois** de toda a arte e polimento visual e **antes** do lançamento.
```

Substituir a descrição da fase de áudio pelo sistema implementado:

```markdown
## 11. Sistema de Áudio

**Status:** Implementado na Fase 5 (v1.9.28+). 100% procedural — zero arquivos de áudio no bundle.

### Stack

- `flutter_soloud` — playback low-latency
- `SynthCore` — primitivas DSP (Karplus-Strong, filteredNoise SVF, ADSR, LFO, 32kHz)
- `SfxrSynth` — sintetizador de SFX (bomba 2x/3x, merge, vitória, game over, desfazer 1/3)
- `AnimalVoices` — voz sintetizada por animal + pluck de merge

### SFX implementados

| Evento | Som |
| --- | --- |
| Merge de tiles | Pluck quente de violão (Karplus-Strong), pitch sobe com o nível |
| Novo animal alcançado | Voz sintetizada do bicho (cigarra, sapo, tucano, sagui, boto, sucuri, capivara); chime harmônico para os demais |
| Bomba 2x | Explosão curta |
| Bomba 3x | Explosão grave e mais longa |
| Vitória | Arpejo C4→G4→C5→E5 |
| Game Over | Sequência descendente C4→A3→F3 |
| Desfazer 1 | Pitch sweep reverso curto ("rebobinar") |
| Desfazer 3 | Pitch sweep reverso grave e mais longo |

### Configurações (SettingsScreen)

- Switch "Efeitos sonoros" + slider de volume — persistidos em `settings.sfx_enabled` / `settings.sfx_volume`
- Música de fundo: **não implementada** (removida da scope)
```

- [ ] **Step 6: Verificar o arquivo compila sem erros de Dart**

Este é um arquivo Markdown, não Dart. Apenas revisar visualmente que as edições estão corretas e não quebraram a formatação de tabelas.

- [ ] **Step 7: Commit**

```bash
git add CAPIVARA_2048_DESIGN.md
git commit -m "docs: CAPIVARA_2048_DESIGN — documentar sistema de SFX implementado"
```

---

## Task 9: Encerramento fase 5 — versão, CHANGELOG, CLAUDE.md, AGENTS.md

**Files:**
- Modify: `pubspec.yaml`
- Modify: `CHANGELOG.md`
- Modify: `CLAUDE.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: Bump de versão**

Em `pubspec.yaml`, linha 7:
```yaml
version: 1.9.29+35
```

- [ ] **Step 2: Atualizar CHANGELOG.md**

Mover o conteúdo de `[Unreleased]` para uma entrada versionada e adicionar a entrada de encerramento de fase. O topo do CHANGELOG deve ficar:

```markdown
## [Unreleased]

## [1.9.29] — 2026-06-03

### Removed

- **Música de fundo removida**: `JungleSequencer`, campos `musicEnabled`/`musicVolume` do `SettingsState`, controle "Música de fundo" na tela de Configurações, chamadas `startMusic`/`pauseMusic` no `GameScreen`
- **`AnimalVoices.voiceSamples`**: método dead code após remoção do `JungleSequencer`

### Changed

- Fase 5 encerrada — sistema de áudio completo (SFX procedural) como estado final da fase
```

- [ ] **Step 3: Atualizar CLAUDE.md — fase 5 e fase atual**

Localizar a linha da fase 5 no roadmap:
```
| 5 🔄      | Arte adicional e polimento visual ...
```
Alterar para:
```
| 5 ✅      | Arte adicional e polimento visual — sistema de SFX procedural (fases 5.1 e 5.2); demais itens visuais descartados |
```

Localizar a linha da fase atual:
```
Fase atual: **Fase 5 em progresso (v1.9.28) — Arte adicional e polimento visual**.
```
Alterar para:
```
Fase atual: **Fase 6 (v1.9.29) — Polimento, l10n, acessibilidade, lançamento**.
```

- [ ] **Step 4: Atualizar AGENTS.md — mesmas mudanças**

Localizar e alterar a linha da fase 5 em `AGENTS.md` (mesma operação do Step 3):

```
| 5 🔄      | Arte adicional e polimento visual ...
```
→
```
| 5 ✅      | Arte adicional e polimento visual — sistema de SFX procedural (fases 5.1 e 5.2); demais itens visuais descartados |
```

- [ ] **Step 5: Rodar suite de áudio final**

Run: `flutter test test/domain/audio/`
Expected: PASS — todos os testes (sem jungle_sequencer_test).

- [ ] **Step 6: Analyze geral dos arquivos modificados**

Run: `flutter analyze lib/domain/audio lib/presentation/controllers/settings_notifier.dart lib/presentation/screens/settings_screen.dart lib/presentation/screens/game/game_screen.dart`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml CHANGELOG.md CLAUDE.md AGENTS.md
git commit -m "chore(release): v1.9.29+35 — música removida, fase 5 encerrada"
```

---

## Notas de implementação

- **Ordem importa:** Tasks 1→2 devem ser feitas nessa sequência — a interface muda antes da impl. Tasks 3-7 são independentes entre si mas dependem das Tasks 1-2.
- **`settings_screen.dart` e o Divider:** após remover o bloco de música, o Divider entre música e SFX pode ficar no início do card sem nada acima. Se o "Áudio" for o primeiro e único grupo, o Divider pode ser removido também — checar visualmente o contexto ao redor ao editar.
- **`git add -A` na Task 7:** necessário para stagear arquivos deletados.
- **Não alterar:** `SynthCore`, `AnimalVoices.voice/mergePluck`, `SfxrSynth`, eventos `GameSoundEvent` existentes, `game_notifier.dart` (dispara AnimalReached/Undo1/3 — permanece).
