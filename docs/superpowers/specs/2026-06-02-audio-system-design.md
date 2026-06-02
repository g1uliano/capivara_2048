# Sistema de Áudio — Design Spec
**Data:** 2026-06-02  
**Fase:** 5 (antecipado de Fase 6)  
**Status:** Aprovado, aguardando implementação

---

## Visão Geral

Sistema de áudio procedural completo para "Olha o Bichim!": efeitos sonoros estilo 8-bit gerados algoritmicamente e música de fundo MPB/Bossa Nova em chiptune, tudo sintetizado em runtime via Dart + `flutter_soloud`.

**Decisões de design:**
- `flutter_soloud` como engine de playback (C++ SoLoud — baixa latência, mixing nativo, loop seamless)
- Síntese em Dart puro (sfxr-inspired para efeitos, sequenciador custom para música)
- Música pré-renderizada em `Isolate` no boot — jogo não espera
- Stub silencioso para flavor `tst` — testes não quebram

---

## Arquitetura

```
┌─────────────────────────────────────────────────────┐
│                    AudioService                      │  ← Riverpod provider singleton
│  playEffect(GameSoundEvent)                          │
│  startMusic() / pauseMusic() / stopMusic()           │
│  setSfxVolume() / setMusicVolume()                   │
│  setSfxEnabled() / setMusicEnabled()                 │
└───────────────┬─────────────────────┬────────────────┘
                │                     │
    ┌───────────▼──────────┐  ┌───────▼──────────────┐
    │    SfxrSynth         │  │   JungleSequencer     │
    │  gera PCM p/ efeitos │  │  gera loop PCM ~85s   │
    │  (Dart puro)         │  │  (roda em Isolate)    │
    └───────────┬──────────┘  └───────┬───────────────┘
                │                     │
    ┌───────────▼─────────────────────▼───────────────┐
    │              flutter_soloud (SoLoud)             │
    │  loadMem() / play() / stop() / setVolume()       │
    └─────────────────────────────────────────────────┘
```

### Estrutura de arquivos

```
lib/domain/audio/
├── audio_service.dart          — interface abstrata + Riverpod provider
├── audio_service_impl.dart     — implementação real (flutter_soloud)
├── audio_service_stub.dart     — stub silencioso (flavor tst / testes)
├── sfxr_synth.dart             — síntese de efeitos sonoros
├── jungle_sequencer.dart       — síntese da música de fundo
└── sound_presets.dart          — parâmetros de cada SoundEvent
```

### Lifecycle

1. `app.dart` chama `audioService.init()` em `initState`
2. `init()`: inicializa SoLoud → gera 15 SFX WAVs em memória → dispara `Isolate` para `JungleSequencer`
3. Quando `Isolate` retorna, carrega música no SoLoud com `looping: true` — jogo já está aberto
4. `GameScreen.initState` → `startMusic()`
5. `GameScreen.dispose` → `pauseMusic()`

### Flavor guard

```dart
final audioServiceProvider = Provider<AudioService>((ref) {
  if (const String.fromEnvironment('FLAVOR') == 'dev') {
    return AudioServiceStub();
  }
  return AudioServiceImpl();
});
```

---

## API Pública

```dart
abstract class AudioService {
  Future<void> init();
  void dispose();

  void playEffect(GameSoundEvent event);

  void startMusic();
  void pauseMusic();
  void stopMusic();

  void setSfxVolume(double v);    // 0.0–1.0
  void setMusicVolume(double v);  // 0.0–1.0
  void setSfxEnabled(bool v);
  void setMusicEnabled(bool v);
}

enum GameSoundEvent {
  bomb2xUsed,
  bomb3xUsed,
  tilesMerged,      // carrega level via construtor: GameSoundEvent.tilesMerged(level)
  victoryReached,
  gameOver,
}
```

---

## Efeitos Sonoros (`SfxrSynth`)

### Mapeamento de eventos

| `GameSoundEvent` | Trigger | Caráter |
|---|---|---|
| `bomb2xUsed` | Bomba 2x ativada | Explosão curta, impacto médio |
| `bomb3xUsed` | Bomba 3x ativada | Explosão grave, longa, mais peso |
| `tilesMerged(level)` | Merge de tiles (nível 1–11) | Bip ascendente; pitch sobe com nível |
| `victoryReached` | Atingiu 2048/4096/8192 | Fanfarra 8-bit ascendente |
| `gameOver` | Fim de jogo | Sequência descendente, tom triste |

### Síntese por evento

**Bombas:**
- Waveform: ruído branco + onda quadrada grave
- Frequency sweep descendente: 300Hz → 40Hz em 0.4s (Bomba 2x) / 200Hz → 30Hz em 0.6s (Bomba 3x)
- Envelope: ataque instantâneo, decay exponencial
- Bomba 3x: frequência base mais baixa, duração 40% maior, amplitude maior

**Merge de tiles:**
- Waveform: onda triangular (suave, não agride a cada merge)
- Frequência por nível:
  - Nível 1–3: 220–440 Hz
  - Nível 4–7: 440–880 Hz
  - Nível 8–11: 880–1760 Hz (Capivara Lendária = nota mais alta)
- 11 variantes pré-geradas no boot

**Vitória:**
- Arpejo ascendente pentatônico: C4 → G4 → C5 → E5
- Onda quadrada, 4 notas em 0.6s

**Game Over:**
- 3 notas descendentes: C4 → A3 → F3
- Onda triangular, 0.8s, sustain longo

### Formato de saída

WAV em memória: header 44 bytes + amostras `Int16` a 22050Hz mono.  
Todos os presets gerados no `init()` e armazenados como `AudioSource` no SoLoud — nenhuma geração on-demand em runtime.

---

## Música de Fundo (`JungleSequencer`)

### Conceito

Bossa Nova / MPB codificada como dados e renderizada em chiptune 8-bit. A qualidade vem das sequências de notas compostas, não da aleatoriedade. O algoritmo é um renderizador; a composição é o conteúdo.

### Parâmetros

| Parâmetro | Valor |
|---|---|
| Estilo | MPB / Bossa Nova |
| Tom | Ré maior (D) |
| Tempo | 90 BPM |
| Duração do loop | 64 compassos ≈ 85s |
| Sample rate | 22050 Hz mono |
| Tamanho em memória | ~1.9 MB |

### Vozes (4 canais SoLoud)

| Voz | Onda | Papel |
|---|---|---|
| Melodia | Triângulo suave | Frases com antecipação MPB; silencia na Seção C |
| Baixo bossa | Quadrada grave | Root + 5ª + cromatismos de passagem, segue harmonia real |
| Batida | Quadrada 25% duty | Padrão João Gilberto — pulso constante do loop |
| Contraponto | Triângulo médio | Responde à melodia; ativo em B e A', silente em A e C |

### Progressão harmônica

```
Seção A (16c) — tema principal
  Dmaj7 | Em7         | A7(9)     | Dmaj7   |
  Gmaj7 | C#m7b5 F#7  | Bm7       | E7      |
  Em7   | Eb7         | Dmaj7/F#  | Bm7     |
  Em7   | A7          | Dmaj7     | A7sus4  |

Seção B (16c) — desenvolvimento, mais tensão harmônica
  Gmaj7   | G#dim   | Dmaj7/F# | E7(9)  |
  F#m7    | B7      | Em7      | Eb7    |
  G#m7b5  | C#7     | F#m7     | B7     |
  Em7     | A7(b9)  | Dmaj7    | F#7    |

Seção C (16c) — respiro (melodia silente, só baixo + batida)
  Bm7 | Em7 | A7 | Dmaj7 | (×4)

Seção A' (16c) — retorno com contraponto ativo (mais cheio)
  igual à Seção A
```

### Padrão rítmico (batida bossa nova em 4/4)

```
1  e  +  a  2  e  +  a  3  e  +  a  4  e  +  a
x  .  .  x  .  x  x  .  .  x  .  x  x  .  x  .
```

### Envelopes

| Voz | Attack | Decay | Sustain | Release |
|---|---|---|---|---|
| Melodia | 20ms | 30ms | 70% | 40ms |
| Baixo | 5ms | rápido | — | — |
| Batida | 0ms | 60ms | — | — |
| Contraponto | 30ms | 40ms | 60% | 50ms |

### Geração

Roda em `Isolate` no boot. Define sequências como `List<(note, duration, waveType)>` por voz por compasso, itera, mixa 4 vozes somando amostras `Int16` com clamp, escreve header WAV. Retorna `Uint8List` ao `AudioService`.

**Custo estimado:** 200–400ms no primeiro boot, ocorre em background.

---

## Settings

### Novos campos em `SettingsState`

```dart
final bool musicEnabled;   // default: true
final bool sfxEnabled;     // default: true
final double musicVolume;  // default: 0.7
final double sfxVolume;    // default: 1.0
```

### UI (`settings_screen.dart`)

Nova seção "Áudio" abaixo das configurações de gameplay:
- Switch: Música de fundo (com slider de volume, aparece quando ativo)
- Switch: Efeitos sonoros (com slider de volume, aparece quando ativo)

---

## Hooks do Jogo

| Arquivo | Evento | Chamada |
|---|---|---|
| `game_notifier.dart` — `useItem(BombType)` | Bomba usada | `audioService.playEffect(bomb2xUsed / bomb3xUsed)` |
| `game_notifier.dart` — `_applyMove()` | Merge ocorreu | `audioService.playEffect(GameSoundEvent.tilesMerged(level))` |
| `game_screen.dart` — listener de estado | `isGameOver == true` | `audioService.playEffect(gameOver)` |
| `victory_choice_dialog.dart` | Dialog exibido | `audioService.playEffect(victoryReached)` |
| `game_screen.dart` — `initState` | Tela abre | `audioService.startMusic()` |
| `game_screen.dart` — `dispose` | Tela fecha | `audioService.pauseMusic()` |

---

## Dependências

Adicionar ao `pubspec.yaml`:
```yaml
flutter_soloud: ^2.x
```

Sem outras dependências externas para síntese — tudo Dart puro.

---

## Fora de Escopo

- Sons de UI (botões, navegação)
- Sons do tutorial
- Variações de música por tela
- Música adaptativa ao estado do jogo
