# Design — Remoção da música de fundo + encerramento da fase 5

**Data:** 2026-06-03
**Status:** aprovado para implementação

## Contexto

A trilha tema procedural (`JungleSequencer`) foi implementada na fase 5.2 mas a
decisão final é removê-la do produto. O jogo fica apenas com **SFX procedurais**
(`SfxrSynth` + `AnimalVoices`). Simultaneamente, a fase 5 de polimento visual é
encerrada — itens não implementados (PNG→WebP, novo visual Recompensas Diárias,
fundo exclusivo) são descartados.

## Escopo

### Arquivos deletados

- `lib/domain/audio/jungle_sequencer.dart`
- `test/domain/audio/jungle_sequencer_test.dart`

### Código removido (cirúrgico, por arquivo)

| Arquivo | O que sai |
| --- | --- |
| `lib/domain/audio/audio_service.dart` | Métodos da interface: `startMusic`, `pauseMusic`, `stopMusic`, `setMusicVolume`, `setMusicEnabled` |
| `lib/domain/audio/audio_service_stub.dart` | Implementações dos mesmos 5 métodos |
| `lib/domain/audio/audio_service_impl.dart` | Campos `_music`, `_musicHandle`, `_musicEnabled`, `_musicVolume`; método `_loadMusic()`; 5 métodos públicos; import de `jungle_sequencer.dart`; chamada `_loadMusic()` em `init()` |
| `lib/presentation/controllers/settings_notifier.dart` | Campos `musicEnabled`, `musicVolume`; constantes `_musicEnabledKey`, `_musicVolumeKey`; leitura/escrita em `_load()`; métodos `setMusicEnabled()`, `setMusicVolume()`; parâmetros em `copyWith()` |
| `lib/presentation/screens/settings_screen.dart` | Bloco "Música de fundo" inteiro: `SwitchListTile` + `if (settings.musicEnabled)` com `Slider` de volume |
| `lib/presentation/screens/game/game_screen.dart` | Chamada `startMusic()` em `didChangeDependencies` e chamada `pauseMusic()` em `didPush/didPopNext` |
| `lib/domain/audio/animal_voices.dart` | Método `voiceSamples(int level)` — era usado exclusivamente pelo `JungleSequencer._renderAnimals()`; com a música removida fica código morto |
| `test/domain/audio/audio_service_test.dart` | Grupo/teste `music control methods do not throw` |

### O que permanece intacto

- `SynthCore` (DSP foundation)
- `AnimalVoices.voice(level)` e `AnimalVoices.mergePluck(level)` (SFX)
- `SfxrSynth` e todos os presets (`bomb2x`, `bomb3x`, `undo1`, `undo3`)
- `sound_presets.dart`
- `wav_utils.dart`
- Todos os eventos de SFX: `Bomb2xUsed`, `Bomb3xUsed`, `TilesMerged`, `AnimalReached`, `Undo1Used`, `Undo3Used`, `VictoryReached`, `GameOver`
- Controles de SFX nas Configurações (switch + slider de volume)
- `settings_notifier`: `sfxEnabled`, `sfxVolume`, `setSfxEnabled()`, `setSfxVolume()`

### CAPIVARA_2048_DESIGN.md

Atualizar as seguintes seções para refletir o sistema real implementado:

1. **Nota de áudio (linha ~11):** substituir "segue em Fase 6" por descrição do sistema SFX procedural atual.
2. **Tabela de stack (linha ~52):** substituir `audioplayers`/`just_audio` → `flutter_soloud`; atualizar descrição para "SFX procedural".
3. **Estrutura de pastas (linha ~155):** remover `sounds/animals/`, `sounds/ui/`, `music/` (esses diretórios não existem; o áudio é 100% em memória).
4. **Seção de áudio/fase 6 (linha ~1673):** substituir o placeholder por descrição do sistema implementado: SFX procedural Dart puro, `SfxrSynth` (bomba, merge, vitória, game over, desfazer 1/3), `AnimalVoices` (voz do bicho ao atingir novo nível máximo, pluck de merge), `SynthCore` (Karplus-Strong, filteredNoise, ADSR/LFO, 32kHz), `flutter_soloud` para playback. Sem música de fundo.
5. **Tela de Configurações — chaves de persistência (linha ~1129):** remover `settings.music_volume`.
6. **Tela de Configurações — UI (linha ~747 e ~974):** remover referências a slider de música.

### Encerramento fase 5 + docs

- `CLAUDE.md`: fase 5 → ✅; fase 5.2 → ✅ (já está); fase atual → **Fase 6**
- `AGENTS.md`: idem
- `CHANGELOG.md`: entrada para v1.9.29 descrevendo remoção da música + fechamento fase 5
- Bump de versão em `pubspec.yaml`: `1.9.28+34` → `1.9.29+35`

## Critérios de sucesso

1. `flutter test test/domain/audio/` passa sem nenhum teste de sequencer.
2. `flutter analyze lib/` sem erros relacionados a música.
3. Tela de Configurações não tem mais controle de "Música de fundo".
4. `GameScreen` não chama mais `startMusic`/`pauseMusic`.
5. `CAPIVARA_2048_DESIGN.md` documenta o sistema de SFX como implementado.
6. Fase 5 marcada como ✅ e fase atual = 6.

## Fora de escopo

- Itens da fase 5 não implementados (PNG→WebP, novo visual Recompensas Diárias, fundo exclusivo) — descartados sem implementar.
- Remoção de `SynthCore.filteredNoise` ou `SynthCore.pluck` — ainda usados por `AnimalVoices`.
- Mudanças nos SFX existentes.
