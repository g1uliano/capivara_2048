# Design — Animações de Bomba (explosão) e Desfazer (efeito VHS)

**Data:** 2026-06-03
**Fase:** 6 (Polimento)
**Status:** aprovado para implementação

## Contexto

O jogo tem dois itens de bomba (Bomb2, Bomb3) e dois de desfazer (Undo1, Undo3).
Atualmente nenhum deles tem feedback visual além do SFX. Este spec adiciona:

1. **Explosão de bomba** — animação sobre cada tile eliminado ao usar Bomb2 ou Bomb3.
2. **Efeito VHS de rebobinar** — overlay de tela inteira estilo fita VHS ao usar Undo1 ou Undo3.

Ambas as animações respeitam `performanceSettings.animationsEnabled`.

## Arquitetura

```
lib/presentation/widgets/
├── bomb_explosion_overlay.dart   [NOVO] overlay de explosão sobre tiles selecionados
└── vhs_rewind_overlay.dart       [NOVO] overlay VHS de tela inteira

lib/presentation/screens/game/
└── game_screen.dart              [EDITADO] adiciona overlays + estado local de animação
```

Nenhum arquivo fora da presentation layer é tocado.

## Unidade 1 — `bomb_explosion_overlay.dart`

**O que faz:** renderiza partículas/flash de explosão sobre cada tile selecionado no momento
em que a bomba é confirmada.

**Como se usa:** inserido no `Stack` do `GameScreen`, acima do `BombGridOverlay`, visível
apenas durante a animação de explosão (~350ms). Recebe a lista de posições dos tiles e a
largura do lado do tabuleiro.

**Depende de:** `flutter_animate`, `performanceSettings`, `GameConstants`.

### Detalhes

- Usa o **mesmo layout** do `BombGridOverlay` (Column de Rows com Expanded + mesmo padding)
  para alinhar pixel-perfect com o tabuleiro.
- Sobre cada célula selecionada renderiza um `CircleExplosion`: círculo que escala de 0→1.4
  com `fadeOut` simultâneo, usando `flutter_animate` (`.animate().scale().fadeOut()`).
  Cor: laranja/vermelho para Bomb2; vermelho intenso + maior para Bomb3.
- Ao terminar a animação (onComplete), o overlay remove-se do `Stack` via callback.
- Se `animationsEnabled == false`: o callback de remoção é chamado imediatamente (0ms),
  sem renderizar nada.

### Parâmetros

```dart
BombExplosionOverlay({
  required List<(int, int)> positions, // tiles a explodir
  required double boardSize,            // largura/altura do tabuleiro em pixels
  required bool isBomb3,               // Bomb3 = efeito maior
  required VoidCallback onComplete,    // remove o overlay do Stack
})
```

## Unidade 2 — `vhs_rewind_overlay.dart`

**O que faz:** cobre a tela inteira com um efeito visual de fita VHS sendo rebobinada enquanto
o estado do jogo reverte.

**Como se usa:** `Positioned.fill` no `Stack` raiz do `GameScreen`. Disparado imediatamente
após `notifier.undo()` retornar `true`. Remove-se ao terminar.

**Depende de:** `flutter_animate`, `dart:math` (para ruído/scanlines).

### Efeito visual (CustomPainter + flutter_animate)

O overlay é um `CustomPaint` com `AnimationController` de duração total:
- **Undo1:** 500ms
- **Undo3:** 750ms (mais dramático)

Camadas do efeito (todas renderizadas no `paint`):

1. **Overlay escuro translúcido:** `Colors.black.withOpacity(0.45)` cobrindo tudo.
2. **Scanlines horizontais:** linhas finas (2px) com espaçamento de 6px, opacity 0.15,
   varrendo de cima pra baixo à medida que a animação progride.
3. **Ruído de deslocamento (glitch):** a cada frame, ~8 faixas horizontais aleatórias da
   tela são deslocadas lateralmente (±10–30px) por um valor pseudoaleatório derivado do
   tempo — simula o instabilidade de VHS. Seed muda por frame.
4. **Flash inicial:** nos primeiros 80ms, flash branco/cinza com opacity que decai
   rapidamente (quadrático).
5. **Linha de rebobinar:** linha horizontal brilhante (branca, 3px) que percorre a tela
   de baixo pra cima durante a animação, como a cabeça de leitura de uma fita.

### Parâmetros

```dart
VhsRewindOverlay({
  required bool isUndo3,         // true = 750ms + efeito mais intenso
  required VoidCallback onComplete,
})
```

### Sem animações

Se `animationsEnabled == false`: o overlay não é inserido no Stack; o `undo()` é executado
normalmente sem efeito visual.

## Integração no GameScreen

`GameScreen` já é `ConsumerStatefulWidget`. Adicionar estado local:

```dart
bool _showBombExplosion = false;
List<(int, int)> _bombExplosionPositions = [];
bool _isBomb3Explosion = false;

bool _showVhsRewind = false;
bool _isUndo3Rewind = false;
```

### Bomba

Em `game_notifier.dart`, `confirmBomb()` já atualiza o estado (tiles removidos) e
emite SFX. A animação de explosão deve acontecer **antes** da remoção para que o
usuário veja os tiles explodirem.

Fluxo ajustado:
1. Usuário seleciona N tiles → `selectBombTile` → ao atingir N, `confirmBomb()` seria
   chamado automaticamente.
2. **Nova lógica:** ao atingir N tiles selecionados, em vez de chamar `confirmBomb()`
   imediatamente, o `GameScreen` detecta que `selectedBombTiles.length == maxTiles`,
   ativa `_showBombExplosion` com as posições, e chama `confirmBomb()` **apenas no
   `onComplete` do overlay**.
3. Para interceptar isso, `selectBombTile` não chama mais `confirmBomb()` internamente
   quando atinge o máximo — o `GameScreen` detecta via `ref.listen` e orquestra.

**Alternativa mais simples (recomendada):** `confirmBomb()` permanece como está
(remove os tiles imediatamente). O `BombExplosionOverlay` é exibido sobre o tabuleiro
**antes** de chamar `confirmBomb()` — ou seja, no `GameScreen`, ao detectar
`selectedBombTiles.length == maxTiles` via `ref.listen(gameProvider)`, exibe a
animação e só depois chama `confirmBomb()`.

Isso exige uma pequena mudança: `selectBombTile` **não** chama `confirmBomb()`
automaticamente quando o máximo é atingido (remover esse auto-confirm interno).
O `GameScreen` passa a ser responsável por chamar `confirmBomb()` no `onComplete`.

### Desfazer

No `game_over_item_overlay.dart`, quando `notifier.undo(1)` ou `notifier.undo(3)` retorna
`true`, em vez de apenas consumir o item, notifica o `GameScreen` para exibir o overlay VHS.

**Mecanismo:** adicionar um `ValueNotifier<_UndoAnimEvent?>` no `GameScreen` (ou usar
um `Provider` simples de evento de UI) que o overlay de game over lê. Mais simples:
passar um callback `onUndoUsed(bool isUndo3)` para o `GameOverItemOverlay`.

O `GameScreen` exibe o overlay VHS; no `onComplete`, o overlay some.

## Arquivos modificados

| Arquivo | Mudança |
| --- | --- |
| `game_screen.dart` | Estado local `_showBombExplosion` / `_showVhsRewind`; overlays no Stack; callback para `BombExplosionOverlay`/`VhsRewindOverlay`; `ref.listen` para detectar bomba cheia; callback `onUndoUsed` para `GameOverItemOverlay` |
| `game_notifier.dart` | Remover auto-confirm interno de bomba (quando `_bombSelection.length == maxTiles`) |
| `game_over_item_overlay.dart` | Aceitar callback `onUndoUsed(bool isUndo3)` |

## Testes

- `bomb_explosion_overlay_test.dart`: renderiza sem erro com `animationsEnabled=true/false`; `onComplete` é chamado.
- `vhs_rewind_overlay_test.dart`: renderiza sem erro; `onComplete` é chamado; sem crash com `isUndo3=true/false`.
- Nenhum teste unitário de game engine necessário (mudança apenas na UI).

## Fora de escopo

- Partículas físicas reais (sem `flame` ou motor de partículas).
- Animação de tiles individuais voltando para trás (o efeito VHS é overlay, não anima os tiles).
- Sons novos (já existem `Bomb2xUsed`, `Bomb3xUsed`, `Undo1Used`, `Undo3Used`).

## Critérios de sucesso

1. Bomb2/Bomb3: flash de explosão visível sobre os tiles antes de sumirem.
2. Undo1/Undo3: overlay VHS cobre a tela inteira por 500ms/750ms.
3. Com `animationsEnabled=false`: nenhum dos dois efeitos aparece.
4. Nenhuma regressão no fluxo de bomba ou desfazer.
