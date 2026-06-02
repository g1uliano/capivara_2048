# Design — Reformulação da trilha sonora: Bossa Nova amazônica procedural

**Data:** 2026-06-02
**Fase do roadmap:** 5.1 (sistema de áudio) — iteração de qualidade
**Status:** aprovado para plano de implementação

## Problema

A trilha tema atual (`JungleSequencer`) e os SFX (`SfxrSynth`) não entregam a
experiência desejada:

1. **Timbre "bip-bip" 8-bit** — música usa só ondas `square` + `triangle`; não
   lembra instrumentos MPB (violão de nylon, percussão suave).
2. **Falta ambiência de natureza** — nenhum som de água, vento ou floresta.
3. **Falta voz dos bichos** — nada conecta o áudio aos animais do jogo.
4. **Composição fraca** — o arranjo atual não tem pegada de Bossa Nova de
   verdade (harmonia simplista, batida genérica).

Adicionalmente, faltam SFX para os itens **Desfazer 1** e **Desfazer 3**.

## Decisões fechadas (do brainstorming)

- **Abordagem:** 100% procedural (zero arquivos de áudio). Mantém o app pequeno
  e a arquitetura atual (geração de WAV em isolate no startup).
- **Referência musical:** Bossa Nova clássica (Tom Jobim / João Gilberto) —
  violão de nylon, batida bossa, harmonia jazz, clima calmo e elegante.
- **Bichos:** sons de animais específicos do jogo, mirando nos viáveis de
  sintetizar de forma reconhecível.
- **Integração das vozes:** ambiência de bichos na trilha de fundo **+** voz do
  bicho específico quando o jogador alcança aquele animal pela 1ª vez (novo
  nível máximo) — não em todo merge, para não cansar o ouvido nem matar o clima
  calmo da bossa.

## Esclarecimento técnico

"128-bit" não existe em áudio. Profundidade de bit (16-bit = qualidade de CD)
não é o que enriquece o som — o divisor real é **síntese pura vs. samples
reais**. Como ficamos na síntese pura, o ganho de riqueza vem de **técnicas de
síntese melhores** (Karplus-Strong para cordas, ruído filtrado para natureza) e
de um **sample rate maior** (22050 → 32000 Hz) para clareza nos sons brilhantes.

## Arquitetura

```
lib/domain/audio/
├── synth_core.dart      [NOVO]  DSP reutilizável (Karplus-Strong, ruído, ADSR, LFO)
├── animal_voices.dart   [NOVO]  Vozes sintetizadas dos bichos + pluck de merge
├── jungle_sequencer.dart [REESCRITO] Composição bossa + timbres KS + ambiência
├── sfxr_synth.dart      [EDITADO] Merge delega a animal_voices; +SFX desfazer
├── sound_presets.dart   [EDITADO] Presets de desfazer; mapeamento bicho→nível
├── audio_service.dart   [EDITADO] Novos eventos
├── audio_service_impl.dart [EDITADO] Carregar/tocar novos sons
└── wav_utils.dart       [inalterado]

lib/presentation/controllers/
└── game_notifier.dart   [EDITADO] Disparar AnimalReached, Undo1Used, Undo3Used
```

### Unidade 1 — `synth_core.dart` (núcleo de síntese)

Funções DSP puras, sem estado de Flutter, testáveis isoladamente. Operam sobre
buffers `Float64List`/`Int16List` ou retornam geradores de amostra.

**O que faz:** fornece os blocos de síntese compartilhados por música e SFX.
**Como se usa:** funções estáticas/utilitárias chamadas pelo sequencer e pelas
vozes de bicho.
**Depende de:** apenas `dart:math`, `dart:typed_data`.

Componentes:

- **`SynthCore.pluck(...)` — Karplus-Strong**
  Sintetiza uma corda dedilhada: preenche uma linha de atraso (tamanho =
  `sampleRate / freq`) com ruído, depois lê em loop aplicando filtro lowpass de
  1 polo na realimentação. Parâmetros: `freq`, `durationSamples`, `brightness`
  (ganho da realimentação, 0.90–0.999), `damping` (corte do lowpass). Produz
  timbre de violão de nylon. Saída somada num buffer alvo com `volume` e offset.

- **`SynthCore.filteredNoise(...)` — ruído filtrado**
  Gera white/pink noise e aplica lowpass ou bandpass com cutoff modulado por um
  LFO lento. Base de água (lowpass + AM lenta), vento/folhas (pink + LFO),
  sibilo de cobra (bandpass alto). Parâmetros: `type` (white/pink),
  `filter` (lowpass/bandpass), `cutoff`, `q`, `lfoRate`, `lfoDepth`,
  `durationSamples`, `volume`.

- **`SynthCore.adsr(t, dur, a, d, s, r)`** — envelope ADSR (substitui o
  envelope ad-hoc atual).

- **`SynthCore.lfo(t, rate, depth)`** — oscilador de baixa frequência p/
  vibrato/tremolo.

- **`SynthCore.mix(target, source, offset, volume)`** — soma com clamp em
  `Int16` (centraliza a lógica de mixagem hoje duplicada).

**Constante:** `SynthCore.sampleRate = 32000`. Todos os módulos de áudio passam
a referenciar essa constante (hoje cada arquivo tem o seu `22050` hardcoded).

### Unidade 2 — `jungle_sequencer.dart` (reescrito)

**O que faz:** renderiza o loop de música tema (~85s) como WAV, em isolate.
**Como se usa:** `JungleSequencer.generate()` → `Future<Uint8List>` (assinatura
pública preservada — `audio_service_impl` não muda a chamada).
**Depende de:** `synth_core.dart`, `wav_utils.dart`.

Mudanças de conteúdo:

- **Harmonia bossa real:** progressão de acordes jazz (maj7, m7, dom7 com 9ª) —
  ex.: ciclo de ii–V–I e variações típicas de bossa. Substituir as tríades e os
  `allBarRoots`/`allBarVoicings` atuais por uma tabela de acordes com voicings de
  4 notas.
- **Batida bossa:** padrão sincopado característico (estilo João Gilberto) no
  comping do violão; baixo tocando fundamental/quinta em 1 e 3.
- **Timbres via Karplus-Strong:**
  - Melodia → `SynthCore.pluck` (nylon brilhante).
  - Comping (acordes) → múltiplos `pluck` com pequeno espalhamento de tempo
    (strum) por acorde.
  - Baixo → `pluck` com decaimento longo / `damping` alto (contrabaixo acústico)
    ou sine suave com ADSR.
  - **Remover** todo uso de `square`/`triangle` na música.
- **Camada de ambiência** (volume baixo, sob a música, render contínuo no loop):
  - Água: `filteredNoise` lowpass + AM lenta.
  - Vento/folhas: `filteredNoise` pink + LFO de cutoff.
- **Vozes de bicho ambientais:** chamadas curtas espalhadas em posições
  **determinísticas** (`Random` com seed fixo) ao longo do loop, em volume baixo:
  coaxar de sapo, pio de tucano, cigarra, assobio de boto. Reutiliza
  `AnimalVoices` (Unidade 3).

### Unidade 3 — `animal_voices.dart` (novo)

**O que faz:** sintetiza a voz de cada animal e o pluck de merge.
**Como se usa:** `AnimalVoices.voice(level)` → `Uint8List` (WAV) para SFX de
bicho novo; `AnimalVoices.mergePluck(level)` → `Uint8List` para merge comum;
helpers de baixo nível reusados pela ambiência do sequencer.
**Depende de:** `synth_core.dart`, `wav_utils.dart`.

Mapeamento nível → animal → técnica de síntese:

| Nível | Animal              | Síntese                                                        |
| ----- | ------------------- | -------------------------------------------------------------- |
| 1     | Tanajura (cigarra)  | ruído/saw com AM rápida sustentada (zumbido de inseto)         |
| 2     | Lobo-guará          | **difícil** → chime mágico de destaque                         |
| 3     | Sapo-cururu         | trem de pulsos ~30–60 Hz + formante (coaxar)                   |
| 4     | Tucano              | chirp: sweep de pitch curto + vibrato                          |
| 5     | Sagui               | guincho agudo: sine 4–8 kHz com vibrato rápido                 |
| 6     | Preguiça            | **difícil** → chime mágico de destaque                         |
| 7     | Mico-leão-dourado   | **difícil** → chime mágico de destaque                         |
| 8     | Boto-cor-de-rosa    | assobio ascendente (sine sweep) + cliques                      |
| 9     | Onça-pintada        | **difícil** → chime mágico de destaque                         |
| 10    | Sucuri              | sibilo: `filteredNoise` bandpass alto com envelope             |
| 11    | Capivara Lendária   | **especial triunfante** (mais longo/rico que os demais)        |

- **`mergePluck(level)`** — pluck quente de violão (KS) afinado pela tabela de
  pitches por nível (reaproveita `mergePitches` de `sound_presets`). Sutil,
  curto, para tocar em **toda** fusão sem cansar.
- **`voice(level)`** — a voz do animal da tabela; níveis difíceis caem no chime
  mágico. Tocado só em "bicho novo".

### Unidade 4 — `sfxr_synth.dart` (editado)

- `generateMerge(level)` passa a delegar para `AnimalVoices.mergePluck(level)`
  (mantém a assinatura).
- Adicionar `generateUndo1()` e `generateUndo3()`: varredura de pitch
  **reversa** (frequência subindo no tempo → sensação de "rebobinar"). Undo3
  mais grave e mais longo que Undo1.
- SFX de bomba/vitória/game-over: migrar para `SynthCore.sampleRate` e
  `SynthCore.adsr` por consistência (sem mudar o caráter sonoro).

### Unidade 5 — `sound_presets.dart` (editado)

- Adicionar `undo1` e `undo3` (presets com freqSweep negativo / reverso).
- Manter `mergePitches` (agora consumido por `AnimalVoices`).
- Documentar o mapeamento bicho→nível como referência.

### Unidade 6 — `audio_service.dart` (editado)

Novos eventos no `sealed class GameSoundEvent`:

```dart
class AnimalReached extends GameSoundEvent {
  const AnimalReached(this.level); // 1–11
  final int level;
}
class Undo1Used extends GameSoundEvent { const Undo1Used(); }
class Undo3Used extends GameSoundEvent { const Undo3Used(); }
```

`TilesMerged(level)` permanece (merge comum → pluck).

### Unidade 7 — `audio_service_impl.dart` (editado)

- Em `_loadSfx`: carregar 11 vozes de bicho (`_animalVoices[level]`), `undo1`,
  `undo3`. Os `_mergeSounds` por nível continuam (agora plucks via
  `generateMerge` delegado).
- Em `playEffect`: novos casos para `AnimalReached(level)` → `_animalVoices`,
  `Undo1Used`, `Undo3Used`.

### Unidade 8 — `game_notifier.dart` (editado)

- Em `game_notifier.dart:126` (bloco `if (state.maxLevel > before.maxLevel)`):
  disparar `playEffect(AnimalReached(state.maxLevel))` — é o momento exato de
  "bicho novo". O `TilesMerged` comum continua disparando como hoje
  (`game_notifier.dart:114`); os dois podem coincidir num merge que sobe o
  nível máximo (pluck + voz juntos — aceitável e até bom).
- No método `undo(int steps)` (linha 191): quando retornar `true`, disparar
  `Undo1Used` se `steps == 1`, senão `Undo3Used`.

## Fluxo de dados

```
Startup:
  AudioServiceImpl.init()
    → JungleSequencer.generate()  [isolate]  → WAV música (loadMem)
    → SfxrSynth + AnimalVoices    → WAVs SFX (bombas, 11 plucks merge,
                                     11 vozes bicho, undo1, undo3,
                                     vitória, game over) (loadMem)

Gameplay (game_notifier):
  merge comum            → TilesMerged(level)  → pluck quente
  merge que sobe máximo  → TilesMerged(level) + AnimalReached(level) → pluck + voz
  desfazer 1             → Undo1Used  → varredura reversa curta
  desfazer 3             → Undo3Used  → varredura reversa grave/longa
  música de fundo: leito de água+vento + bichos esparsos (já no loop renderizado)
```

## Sample rate

22050 → **32000 Hz** em todo o módulo de áudio (constante única em
`SynthCore.sampleRate`). Justificativa: sons brilhantes (pássaro, água, sibilo)
ganham nitidez. Custo: loop de 85s mono 16-bit ≈ 5,3 MB em memória (vs. ~3,7 MB)
e render ~45% mais lento — porém roda 1× no isolate no startup. Aceitável.

## Tratamento de erros

- Síntese é determinística e offline; sem I/O de rede/arquivo. Erros
  improváveis. Manter o padrão atual: `AudioServiceStub` quando `FLAVOR` vazio;
  falhas de SoLoud já são toleradas (sons só não tocam).
- Karplus-Strong: garantir `delayLength = sampleRate/freq >= 2` (clamp em
  frequências muito altas) para evitar buffer degenerado.
- ADSR: `assert(attack > 0)` mantido (evita divisão por zero).

## Estratégia de testes (TDD)

Lógica de síntese é puro Dart → testável sem Flutter (regra do projeto).

- **`synth_core_test.dart`** [novo]:
  - `pluck`: comprimento de saída == `durationSamples`; energia decai ao longo
    do tempo (RMS do fim < RMS do início); não estoura `Int16`.
  - `filteredNoise`: saída no range; comprimento correto; lowpass reduz energia
    de alta frequência (sanidade simples).
  - `adsr`: continuidade nas bordas; pico == 1.0 no fim do attack; 0 em t=dur.
- **`jungle_sequencer_test.dart`** [atualizar]: duração total esperada (32 bars ×
  4 × spb no novo sampleRate); WAV válido; pico normalizado dentro do alvo; sem
  clipping.
- **`sfxr_synth_test.dart`** [atualizar]: `generateMerge` delega e produz WAV
  válido; `generateUndo1/3` com durações esperadas e sweep reverso (freq final >
  inicial); regenerar asserts de duração para sampleRate=32000.
- **`audio_service_test.dart`** [atualizar]: novos eventos roteiam para a fonte
  certa (`AnimalReached`, `Undo1Used`, `Undo3Used`); `TilesMerged` continua →
  pluck.
- **`animal_voices_test.dart`** [novo]: `voice(level)` e `mergePluck(level)`
  produzem WAV válido p/ todos os níveis 1–11; níveis difíceis retornam o chime
  (não quebram).

## Fora de escopo

- Samples/arquivos de áudio reais (decisão: 100% procedural).
- Vozes realistas dos animais difíceis (lobo-guará, preguiça, mico, onça) — usam
  chime mágico.
- Mudanças de UI nas Configurações de áudio (controles já existem).
- Vozes de bicho em todo merge (decidido: só em "bicho novo").

## Critérios de sucesso

1. A música tema soa como Bossa Nova com violão de nylon — sem timbre "bip-bip".
2. Há ambiência audível de água/floresta sob a música.
3. Alcançar um animal novo toca uma voz reconhecível (nos viáveis) / chime
   agradável (nos difíceis).
4. Desfazer 1 e Desfazer 3 têm SFX de "rebobinar" distintos.
5. Todos os testes de áudio passam; sem clipping; app continua sem arquivos de
   áudio.
