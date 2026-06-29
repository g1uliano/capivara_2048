# Tutorial interativo — sandbox 4×4 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir o tutorial 1D fraco por um tabuleiro 4×4 guiado que ensina as regras reais do jogo (todas as peças deslizam juntas; só iguais se unem) e uma demo interativa das ferramentas com os overlays visuais reais.

**Architecture:** Cada página interativa cria uma instância local de `GameEngine` + `GameState` (com `Random` semeado) e dirige o motor de verdade sem tocar no `gameProvider` global. Widgets visuais reais (`BombExplosionOverlay`, `VhsRewindOverlay`, `BombGridOverlay`, `BombDimOverlay`) são reusados via parâmetros opcionais, mantendo o comportamento global intacto.

**Tech Stack:** Flutter, Riverpod, `flutter_animate`, `google_fonts`, `GameEngine` (puro Dart), `GameState`, `Tile`, `Direction`, `BombMode`

---

## Mapa de arquivos

| Ação | Arquivo |
|------|---------|
| Editar | `lib/presentation/widgets/board_widget.dart` |
| Editar | `lib/presentation/widgets/bomb_grid_overlay.dart` |
| Editar | `lib/presentation/widgets/bomb_selection_overlay.dart` |
| Criar | `lib/presentation/screens/tutorial/widgets/tutorial_board.dart` |
| Criar | `lib/presentation/screens/tutorial/pages/tutorial_sandbox_page.dart` |
| Reescrever | `lib/presentation/screens/tutorial/pages/tutorial_items_page.dart` |
| Editar | `lib/presentation/screens/tutorial/tutorial_screen.dart` |
| Deletar | `lib/presentation/screens/tutorial/widgets/tutorial_mini_board.dart` |
| Deletar | `lib/presentation/screens/tutorial/pages/tutorial_movement_page.dart` |
| Deletar | `lib/presentation/screens/tutorial/pages/tutorial_fusion_page.dart` |
| Criar | `test/presentation/tutorial_sandbox_page_test.dart` |

---

### Task 1: BoardWidget — parâmetro `board` opcional

Torna `BoardWidget` reutilizável fora do `gameProvider`, sem quebrar nenhum caller existente.

**Files:**
- Modify: `lib/presentation/widgets/board_widget.dart`

- [ ] **Step 1: Editar BoardWidget**

Substituir o arquivo inteiro:

```dart
// lib/presentation/widgets/board_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/game_constants.dart';
import '../controllers/game_notifier.dart';
import 'tile_widget.dart';

class BoardWidget extends ConsumerWidget {
  final double? size;
  // ponytail: optional override — tutorial passes local state, game uses provider
  final List<List<Tile?>>? board;

  const BoardWidget({super.key, this.size, this.board});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = this.board ?? ref.watch(gameProvider).board;
    final screenWidth = MediaQuery.of(context).size.width;
    final boardSize = size ?? (screenWidth - GameConstants.boardPadding * 2);
    final tileSize =
        (boardSize - GameConstants.tileSpacing * (GameConstants.boardSize + 1)) /
            GameConstants.boardSize;

    return Container(
      width: boardSize,
      height: boardSize,
      decoration: BoxDecoration(
        color: const Color(0xFFE8D5B7),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(GameConstants.tileSpacing),
      child: Column(
        children: List.generate(
          GameConstants.boardSize,
          (r) => Expanded(
            child: Row(
              children: List.generate(
                GameConstants.boardSize,
                (c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(GameConstants.tileSpacing / 2),
                    child: TileWidget(tile: board[r][c], size: tileSize),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

Note: the import for `Tile` must be added. Check if `TileWidget` already imports it indirectly; if not, add:
```dart
import '../../data/models/tile.dart';
```

- [ ] **Step 2: Verificar que o jogo compila sem erros**

```bash
flutter analyze lib/presentation/widgets/board_widget.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/board_widget.dart
git commit -m "refactor(board): param board opcional para reuso no tutorial"
```

---

### Task 2: BombGridOverlay + BombDimOverlay — params opcionais

Permite que o tutorial passe estado local em vez de ler `gameProvider`. Comportamento global inalterado quando params omitidos.

**Files:**
- Modify: `lib/presentation/widgets/bomb_grid_overlay.dart`
- Modify: `lib/presentation/widgets/bomb_selection_overlay.dart`

- [ ] **Step 1: Editar BombGridOverlay**

```dart
// lib/presentation/widgets/bomb_grid_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/game_constants.dart';
import '../../data/models/tile.dart';
import '../controllers/game_notifier.dart';

/// Selection grid using the exact same layout as BoardWidget.
/// When [board], [selected], [maxTiles] and [onTapCell] are provided,
/// operates in standalone mode (tutorial). Otherwise reads gameProvider.
class BombGridOverlay extends ConsumerWidget {
  // ponytail: optional params — tutorial passes local state, game uses provider default
  final List<List<Tile?>>? board;
  final Set<(int, int)>? selected;
  final int? maxTiles;
  final void Function(int r, int c)? onTapCell;

  const BombGridOverlay({
    super.key,
    this.board,
    this.selected,
    this.maxTiles,
    this.onTapCell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In standalone mode all four optional params must be provided together.
    final isStandalone = board != null;
    final notifier = isStandalone ? null : ref.read(gameProvider.notifier);
    final state = isStandalone ? null : ref.watch(gameProvider);

    final effectiveBoard = board ?? state!.board;
    final effectiveSelected =
        selected ?? state!.selectedBombTiles.toSet() as Set<(int, int)>;
    final effectiveMaxTiles =
        maxTiles ?? (state!.bombMode?.name == 'bomb2' ? 2 : 3);
    final effectiveOnTap = onTapCell ??
        (int r, int c) {
          final tile = effectiveBoard[r][c];
          if (tile == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selecione uma peça com valor'),
                duration: Duration(seconds: 1),
              ),
            );
            return;
          }
          notifier!.selectBombTile(r, c);
        };

    return Padding(
      padding: const EdgeInsets.all(GameConstants.tileSpacing),
      child: Column(
        children: List.generate(
          GameConstants.boardSize,
          (r) => Expanded(
            child: Row(
              children: List.generate(GameConstants.boardSize, (c) {
                final isSelected = effectiveSelected.contains((r, c));
                final tile = effectiveBoard[r][c];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(GameConstants.tileSpacing / 2),
                    child: GestureDetector(
                      onTap: () => effectiveOnTap(r, c),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.red.shade400 : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? Colors.red.shade700
                                : Colors.grey.shade300,
                            width: isSelected ? 3 : 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: tile != null
                            ? Center(
                                child: Text(
                                  '${1 << tile.level}',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
```

Note: `state!.selectedBombTiles` is `List<(int, int)>`. Cast `toSet()` or use a proper cast — check the type and adjust if `Set<(int, int)>` doesn't compile directly. If needed: `Set<(int, int)>.from(state!.selectedBombTiles)`.

- [ ] **Step 2: Editar BombDimOverlay**

Em `lib/presentation/widgets/bomb_selection_overlay.dart`, adicionar params opcionais à classe `BombDimOverlay`:

```dart
// lib/presentation/widgets/bomb_selection_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/game_engine/bomb_mode.dart';
import '../controllers/game_notifier.dart';

/// Full-screen dim + label + cancel button.
/// When [maxTiles] and [onCancel] are provided, operates in standalone mode (tutorial).
class BombDimOverlay extends ConsumerWidget {
  // ponytail: optional params — tutorial passes local state, game uses provider default
  final int? maxTiles;
  final VoidCallback? onCancel;

  const BombDimOverlay({super.key, this.maxTiles, this.onCancel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStandalone = maxTiles != null;
    final notifier = isStandalone ? null : ref.read(gameProvider.notifier);
    final state = isStandalone ? null : ref.watch(gameProvider);

    // In global mode, hide when not in bomb mode.
    if (!isStandalone) {
      final mode = state!.bombMode;
      if (mode == null) return const SizedBox.shrink();
    }

    final effectiveMaxTiles =
        maxTiles ?? (state?.bombMode == BombMode.bomb2 ? 2 : 3);
    final effectiveOnCancel = onCancel ?? notifier!.cancelBomb;

    return Stack(
      children: [
        IgnorePointer(
          child: Container(color: const Color(0x60000000)),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    'Selecione $effectiveMaxTiles peças para destruir',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Center(
                child: TextButton(
                  onPressed: effectiveOnCancel,
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Analisar e compilar**

```bash
flutter analyze lib/presentation/widgets/bomb_grid_overlay.dart lib/presentation/widgets/bomb_selection_overlay.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/widgets/bomb_grid_overlay.dart lib/presentation/widgets/bomb_selection_overlay.dart
git commit -m "refactor(bomb-overlays): params opcionais para reuso no tutorial"
```

---

### Task 3: TutorialBoard widget

Widget de swipe que envolve `BoardWidget` e traduz gestos em `Direction`.

**Files:**
- Create: `lib/presentation/screens/tutorial/widgets/tutorial_board.dart`

- [ ] **Step 1: Criar tutorial_board.dart**

```dart
// lib/presentation/screens/tutorial/widgets/tutorial_board.dart
import 'package:flutter/material.dart';
import '../../../../data/models/game_state.dart';
import '../../../../domain/game_engine/direction.dart';
import '../../../widgets/board_widget.dart';

class TutorialBoard extends StatelessWidget {
  final GameState state;
  final void Function(Direction) onSwipe;
  final double? size;

  const TutorialBoard({
    super.key,
    required this.state,
    required this.onSwipe,
    this.size,
  });

  Direction? _resolveDirection(Offset velocity) {
    final dx = velocity.dx;
    final dy = velocity.dy;
    if (dx.abs() < 80 && dy.abs() < 80) return null;
    return dx.abs() > dy.abs()
        ? (dx > 0 ? Direction.right : Direction.left)
        : (dy > 0 ? Direction.down : Direction.up);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanEnd: (details) {
        final dir = _resolveDirection(details.velocity.pixelsPerSecond);
        if (dir != null) onSwipe(dir);
      },
      child: BoardWidget(board: state.board, size: size),
    );
  }
}
```

- [ ] **Step 2: Analisar**

```bash
flutter analyze lib/presentation/screens/tutorial/widgets/tutorial_board.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/screens/tutorial/widgets/tutorial_board.dart
git commit -m "feat(tutorial): TutorialBoard widget (swipe → Direction)"
```

---

### Task 4: Escrever o teste com falha para o gating do sandbox

**Files:**
- Create: `test/presentation/tutorial_sandbox_page_test.dart`

- [ ] **Step 1: Criar o arquivo de teste**

```dart
// test/presentation/tutorial_sandbox_page_test.dart
import 'package:capivara_2048/presentation/screens/tutorial/pages/tutorial_sandbox_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TutorialSandboxPage gating', () {
    testWidgets('step A avança para B após swipe válido', (tester) async {
      bool completed = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TutorialSandboxPage(
                onUserCompleted: () => completed = true,
              ),
            ),
          ),
        ),
      );

      // Step A deve estar ativo: instrução de mover visível
      expect(find.text('Deslize pra mover tudo'), findsOneWidget);
      // Step B instrução NÃO visível ainda
      expect(find.text('Junte dois iguais num só bicho'), findsNothing);

      // Simula swipe pra direita no TutorialBoard
      await tester.fling(
        find.byType(TutorialSandboxPage),
        const Offset(200, 0),
        800,
      );
      await tester.pump();

      // Aguarda o timer de transição (600 ms)
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Step B deve agora estar ativo
      expect(find.text('Junte dois iguais num só bicho'), findsOneWidget);
      // completed não disparado ainda (exige passo C)
      expect(completed, isFalse);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste — deve FALHAR (arquivo não existe)**

```bash
flutter test test/presentation/tutorial_sandbox_page_test.dart
```

Expected: FAIL — "Target of URI doesn't exist" ou "class not found".

---

### Task 5: TutorialSandboxPage — implementar máquina de estado dos 3 passos

**Files:**
- Create: `lib/presentation/screens/tutorial/pages/tutorial_sandbox_page.dart`

- [ ] **Step 1: Criar tutorial_sandbox_page.dart**

```dart
// lib/presentation/screens/tutorial/pages/tutorial_sandbox_page.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/game_state.dart';
import '../../../../data/models/tile.dart';
import '../../../../domain/game_engine/direction.dart';
import '../../../../domain/game_engine/game_engine.dart';
import '../../../widgets/glass_panel.dart';
import '../../../widgets/outlined_text.dart';
import '../widgets/tutorial_board.dart';

enum _SandboxStep { movement, unite, free }

class TutorialSandboxPage extends StatefulWidget {
  final VoidCallback onUserCompleted;
  const TutorialSandboxPage({super.key, required this.onUserCompleted});

  @override
  State<TutorialSandboxPage> createState() => _TutorialSandboxPageState();
}

class _TutorialSandboxPageState extends State<TutorialSandboxPage> {
  _SandboxStep _step = _SandboxStep.movement;
  late GameEngine _engine;
  late GameState _state;
  int _fusions = 0;
  bool _stepDone = false; // shows success message before advancing

  @override
  void initState() {
    super.initState();
    _engine = GameEngine(random: Random(42));
    _state = _buildStepAState();
  }

  // Step A: 4 tiles all different levels, spread so any swipe moves them visibly.
  GameState _buildStepAState() {
    final board = List.generate(4, (_) => List<Tile?>.filled(4, null));
    board[0][0] = const Tile(id: 'a1', level: 1, row: 0, col: 0);
    board[1][2] = const Tile(id: 'a2', level: 2, row: 1, col: 2);
    board[2][0] = const Tile(id: 'a3', level: 3, row: 2, col: 0);
    board[3][3] = const Tile(id: 'a4', level: 4, row: 3, col: 3);
    return GameState(
      board: board,
      score: 0,
      highScore: 0,
      isGameOver: false,
      hasWon: false,
      maxLevel: 4,
    );
  }

  // Step B: two tanajuras (level 1) in same row + one different tile.
  // Swipe left: [1, null, 1, 3] → [2, 3, null, null] — iguais se unem, diferente não.
  GameState _buildStepBState() {
    final board = List.generate(4, (_) => List<Tile?>.filled(4, null));
    board[1][0] = const Tile(id: 'b1', level: 1, row: 1, col: 0);
    board[1][2] = const Tile(id: 'b2', level: 1, row: 1, col: 2);
    board[1][3] = const Tile(id: 'b3', level: 3, row: 1, col: 3);
    return GameState(
      board: board,
      score: 0,
      highScore: 0,
      isGameOver: false,
      hasWon: false,
      maxLevel: 3,
    );
  }

  // Step C: start from step B result; engine runs normally from here.
  GameState _buildStepCState() => _state;

  bool _boardChanged(GameState prev, GameState next) {
    // A valid move always spawns a new tile, increasing tile count.
    int count(GameState s) =>
        s.board.expand((r) => r).whereType<Tile>().length;
    return count(next) > count(prev);
  }

  void _onSwipe(Direction dir) {
    if (_stepDone && _step != _SandboxStep.free) return;
    final prev = _state;
    final next = _engine.move(prev, dir);
    if (!_boardChanged(prev, next)) return;

    setState(() => _state = next);

    switch (_step) {
      case _SandboxStep.movement:
        setState(() => _stepDone = true);
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          setState(() {
            _step = _SandboxStep.unite;
            _stepDone = false;
            _engine = GameEngine(random: Random(1));
            _state = _buildStepBState();
          });
        });
      case _SandboxStep.unite:
        final united = next.score > prev.score;
        if (united) {
          setState(() => _stepDone = true);
          Future.delayed(const Duration(milliseconds: 700), () {
            if (!mounted) return;
            setState(() {
              _step = _SandboxStep.free;
              _stepDone = false;
              _engine = GameEngine();
              // keep board as-is: result of the unite move
            });
          });
        }
      case _SandboxStep.free:
        if (next.score > prev.score) {
          _fusions++;
          if (_fusions >= 2 && !_stepDone) {
            setState(() => _stepDone = true);
            widget.onUserCompleted();
          }
        }
    }
  }

  String get _title {
    switch (_step) {
      case _SandboxStep.movement:
        return 'Deslize pra mover tudo';
      case _SandboxStep.unite:
        return 'Junte dois iguais num só bicho';
      case _SandboxStep.free:
        return 'Agora é com você!';
    }
  }

  String get _subtitle {
    switch (_step) {
      case _SandboxStep.movement:
        return 'Arraste o dedo em qualquer direção — todos os bichos vão juntos pra parede.';
      case _SandboxStep.unite:
        return 'Deslize pra juntar as duas tanajuras num só bicho. O bicho diferente não vai se juntar.';
      case _SandboxStep.free:
        return 'Junte mais alguns bichos e veja o que acontece!';
    }
  }

  String get _successMessage {
    switch (_step) {
      case _SandboxStep.movement:
        return '✓ Viu? Todos foram juntos!';
      case _SandboxStep.unite:
        return '✓ Você criou um bicho novo! 🎉';
      case _SandboxStep.free:
        return '✓ Você pegou o jeito! 🌿';
    }
  }

  String get _hint {
    switch (_step) {
      case _SandboxStep.movement:
        return '👉 Deslize o dedo em qualquer direção';
      case _SandboxStep.unite:
        return '👉 Deslize pra juntar as tanajuras';
      case _SandboxStep.free:
        return '👉 Continue jogando e junte mais bichos';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                Text(
                  _title,
                  style: GoogleFonts.fredoka(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _subtitle,
                  style: GoogleFonts.fredoka(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TutorialBoard(
            key: ValueKey(_step),
            state: _state,
            onSwipe: _onSwipe,
          ),
          const SizedBox(height: 20),
          AnimatedOpacity(
            opacity: _stepDone ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: OutlinedText(
              text: _successMessage,
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: _stepDone ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            child: OutlinedText(
              text: _hint,
              style: GoogleFonts.fredoka(fontSize: 14),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 1.0, end: 1.03, duration: 1500.ms),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Rodar o teste — deve PASSAR**

```bash
flutter test test/presentation/tutorial_sandbox_page_test.dart
```

Expected: PASS.

Se o teste falhar por causa do `fling` não atingir o `TutorialBoard` (o widget raiz da page é `Padding`, não `TutorialBoard`): no teste, trocar `find.byType(TutorialSandboxPage)` por `find.byType(TutorialBoard)`.

- [ ] **Step 3: Verificar análise**

```bash
flutter analyze lib/presentation/screens/tutorial/pages/tutorial_sandbox_page.dart lib/presentation/screens/tutorial/widgets/tutorial_board.dart
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/screens/tutorial/pages/tutorial_sandbox_page.dart test/presentation/tutorial_sandbox_page_test.dart
git commit -m "feat(tutorial): TutorialSandboxPage com 3 passos (mover/unir/livre)"
```

---

### Task 6: TutorialItemsPage — demo interativa com overlays reais

Reescreve a página de ferramentas: a criança toca na bomba e no desfazer e vê os mesmos efeitos visuais do jogo real.

**Files:**
- Rewrite: `lib/presentation/screens/tutorial/pages/tutorial_items_page.dart`

- [ ] **Step 1: Reescrever tutorial_items_page.dart**

```dart
// lib/presentation/screens/tutorial/pages/tutorial_items_page.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/game_state.dart';
import '../../../../data/models/tile.dart';
import '../../../../domain/game_engine/direction.dart';
import '../../../../domain/game_engine/game_engine.dart';
import '../../../widgets/bomb_explosion_overlay.dart';
import '../../../widgets/bomb_grid_overlay.dart';
import '../../../widgets/bomb_selection_overlay.dart';
import '../../../widgets/glass_panel.dart';
import '../../../widgets/lives_indicator.dart';
import '../../../widgets/outlined_text.dart';
import '../../../widgets/vhs_rewind_overlay.dart';
import '../widgets/tutorial_board.dart';

enum _ItemsStep { bomb, undo, lives }

class TutorialItemsPage extends StatefulWidget {
  final VoidCallback onUserCompleted;
  const TutorialItemsPage({super.key, required this.onUserCompleted});

  @override
  State<TutorialItemsPage> createState() => _TutorialItemsPageState();
}

class _TutorialItemsPageState extends State<TutorialItemsPage> {
  _ItemsStep _step = _ItemsStep.bomb;
  late GameEngine _engine;
  late GameState _state;

  // Bomb
  bool _inBombSelection = false;
  Set<(int, int)> _bombSelected = {};
  bool _showExplosion = false;
  List<(int, int)> _explosionPositions = [];
  bool _bombDone = false;

  // Undo
  bool _showVhs = false;
  bool _undoDone = false;

  @override
  void initState() {
    super.initState();
    _engine = GameEngine(random: Random(7));
    _state = _buildBombBoard();
  }

  // Crowded board with no adjacent equal tiles (stuck feeling).
  GameState _buildBombBoard() {
    final board = List.generate(4, (_) => List<Tile?>.filled(4, null));
    // checkerboard pattern: levels alternate 1/2/3/4 such that no neighbours match
    const levels = [
      [1, 2, 3, 4],
      [3, 4, 1, 2],
      [2, 1, 4, 3],
      [4, 3, 2, 1],
    ];
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        board[r][c] = Tile(
          id: 'bomb_${r}_$c',
          level: levels[r][c],
          row: r,
          col: c,
        );
      }
    }
    return GameState(
      board: board,
      score: 0,
      highScore: 0,
      isGameOver: false,
      hasWon: false,
      maxLevel: 4,
    );
  }

  void _onBombButtonTapped() {
    setState(() => _inBombSelection = true);
  }

  void _onSelectBombTile(int r, int c) {
    if (_state.board[r][c] == null) return;
    final newSelected = {..._bombSelected, (r, c)};
    setState(() => _bombSelected = newSelected);

    if (newSelected.length >= 2) {
      // Enough tiles selected — trigger explosion
      setState(() {
        _showExplosion = true;
        _explosionPositions = newSelected.toList();
        _inBombSelection = false;
      });
    }
  }

  void _onExplosionComplete() {
    final cleared = GameEngine.removeTiles(_state, _explosionPositions);
    // Make one move so undoStack has a state to restore.
    final moved = _engine.move(cleared, Direction.right);
    setState(() {
      _state = moved;
      _showExplosion = false;
      _bombSelected = {};
      _bombDone = true;
    });
    // Small delay then switch to undo step.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _step = _ItemsStep.undo);
    });
  }

  void _onUndoButtonTapped() {
    setState(() => _showVhs = true);
  }

  void _onVhsComplete() {
    // Restore previous state from undoStack (most recent = index 0).
    final previous = _state.undoStack.isNotEmpty ? _state.undoStack[0] : _state;
    setState(() {
      _state = previous;
      _showVhs = false;
      _undoDone = true;
    });
    // Switch to lives step.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _step = _ItemsStep.lives);
        widget.onUserCompleted();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildContent(),
            ],
          ),
        ),
        // Bomb overlays (real widgets, standalone mode)
        if (_inBombSelection) ...[
          Positioned.fill(
            child: BombDimOverlay(
              maxTiles: 2,
              onCancel: () => setState(() {
                _inBombSelection = false;
                _bombSelected = {};
              }),
            ),
          ),
          Positioned.fill(
            child: BombGridOverlay(
              board: _state.board,
              selected: _bombSelected,
              maxTiles: 2,
              onTapCell: _onSelectBombTile,
            ),
          ),
        ],
        if (_showExplosion)
          Positioned.fill(
            child: BombExplosionOverlay(
              positions: _explosionPositions,
              isBomb3: false,
              onComplete: _onExplosionComplete,
            ),
          ),
        if (_showVhs)
          Positioned.fill(
            child: VhsRewindOverlay(
              isUndo3: false,
              onComplete: _onVhsComplete,
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    final titles = {
      _ItemsStep.bomb: 'Bomba 💣',
      _ItemsStep.undo: 'Desfazer ↩',
      _ItemsStep.lives: 'Vidas ❤️',
    };
    final subtitles = {
      _ItemsStep.bomb:
          'Se travar, use a bomba pra apagar algumas peças e abrir espaço.',
      _ItemsStep.undo:
          'Errou uma jogada? Toque em desfazer pra voltar atrás.',
      _ItemsStep.lives:
          'Cada partida usa uma vida. Elas se regeneram com o tempo.',
    };
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        children: [
          Text(
            titles[_step]!,
            style: GoogleFonts.fredoka(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitles[_step]!,
            style: GoogleFonts.fredoka(
              fontSize: 15,
              height: 1.5,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_step) {
      case _ItemsStep.bomb:
        return _BombDemo(
          state: _state,
          bombDone: _bombDone,
          onBombTapped: _onBombButtonTapped,
        );
      case _ItemsStep.undo:
        return _UndoDemo(
          state: _state,
          undoDone: _undoDone,
          onUndoTapped: _onUndoButtonTapped,
        );
      case _ItemsStep.lives:
        return const _LivesDemo();
    }
  }
}

// ── Bomb demo ──────────────────────────────────────────────────────────────

class _BombDemo extends StatelessWidget {
  final GameState state;
  final bool bombDone;
  final VoidCallback onBombTapped;

  const _BombDemo({
    required this.state,
    required this.bombDone,
    required this.onBombTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Static board (no swipe in bomb step; selection via BombGridOverlay overlay)
        BoardPreview(state: state),
        const SizedBox(height: 16),
        AnimatedOpacity(
          opacity: bombDone ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          child: ElevatedButton.icon(
            onPressed: bombDone ? null : onBombTapped,
            icon: Image.asset(
              'assets/images/inventory/bomb_3.webp',
              width: 32,
              height: 32,
            ),
            label: Text(
              'Usar bomba',
              style: GoogleFonts.fredoka(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: bombDone ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: OutlinedText(
            text: '✓ A bomba apagou as peças!',
            style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ── Undo demo ──────────────────────────────────────────────────────────────

class _UndoDemo extends StatelessWidget {
  final GameState state;
  final bool undoDone;
  final VoidCallback onUndoTapped;

  const _UndoDemo({
    required this.state,
    required this.undoDone,
    required this.onUndoTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BoardPreview(state: state),
        const SizedBox(height: 16),
        AnimatedOpacity(
          opacity: undoDone ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          child: ElevatedButton.icon(
            onPressed: undoDone ? null : onUndoTapped,
            icon: Image.asset(
              'assets/images/inventory/undo_1.webp',
              width: 32,
              height: 32,
            ),
            label: Text(
              'Desfazer jogada',
              style: GoogleFonts.fredoka(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: undoDone ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: OutlinedText(
            text: '✓ A jogada voltou!',
            style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ── Lives demo ─────────────────────────────────────────────────────────────

class _LivesDemo extends StatelessWidget {
  const _LivesDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        // Show the real LivesIndicator in display-only mode.
        // It reads from livesProvider — wrap in ProviderScope override if needed
        // to show a static 3/3 lives for the tutorial.
        // ponytail: show static hearts instead of live provider to avoid
        // coupling tutorial to livesProvider; add live indicator if needed later.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.favorite, color: Colors.red, size: 40),
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedText(
          text: 'Você começa com 3 vidas.\nElas voltam sozinhas com o tempo.',
          style: GoogleFonts.fredoka(fontSize: 15, height: 1.5),
        ),
      ],
    );
  }
}

// ── BoardPreview (static board display, no swipe) ──────────────────────────

class BoardPreview extends StatelessWidget {
  final GameState state;
  const BoardPreview({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    // Uses BoardWidget with local board — no gesture detection needed here.
    return IgnorePointer(
      child: BoardWidget(board: state.board),
    );
  }
}
```

Note: `BoardPreview` uses `BoardWidget` — add the import at the top of the file:
```dart
import '../../../widgets/board_widget.dart';
```

- [ ] **Step 2: Analisar**

```bash
flutter analyze lib/presentation/screens/tutorial/pages/tutorial_items_page.dart
```

Expected: no errors. If `LivesIndicator` import is unused (replaced by static hearts), remove that import.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/screens/tutorial/pages/tutorial_items_page.dart
git commit -m "feat(tutorial): TutorialItemsPage com demo interativa bomba/desfazer/vidas"
```

---

### Task 7: TutorialScreen — ligar as 4 páginas e limpar arquivos antigos

**Files:**
- Modify: `lib/presentation/screens/tutorial/tutorial_screen.dart`
- Delete: `lib/presentation/screens/tutorial/widgets/tutorial_mini_board.dart`
- Delete: `lib/presentation/screens/tutorial/pages/tutorial_movement_page.dart`
- Delete: `lib/presentation/screens/tutorial/pages/tutorial_fusion_page.dart`

- [ ] **Step 1: Reescrever tutorial_screen.dart**

```dart
// lib/presentation/screens/tutorial/tutorial_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/tutorial_controller.dart';
import 'pages/tutorial_welcome_page.dart';
import 'pages/tutorial_sandbox_page.dart';
import 'pages/tutorial_items_page.dart';
import 'pages/tutorial_finale_page.dart';
import 'widgets/tutorial_scaffold.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  // Tracks completion of interactive pages (pages 1 and 2, 0-indexed)
  bool _page1Done = false;
  bool _page2Done = false;

  static const _totalPages = 4;

  bool get _canGoNext {
    if (_currentPage == 1) return _page1Done;
    if (_currentPage == 2) return _page2Done;
    return true;
  }

  String get _nextLabel =>
      _currentPage == _totalPages - 1 ? 'Começar 🌿' : 'Próximo →';

  void _goNext() {
    if (_currentPage == _totalPages - 1) {
      _complete();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _goBack() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _complete() async {
    await ref.read(tutorialControllerProvider.notifier).markCompleted();
    if (mounted) Navigator.of(context).pop();
  }

  void _onPage1Done() => setState(() => _page1Done = true);
  void _onPage2Done() => setState(() => _page2Done = true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TutorialScaffold(
      currentPage: _currentPage,
      totalPages: _totalPages,
      canGoNext: _canGoNext,
      nextLabel: _nextLabel,
      onBack: _currentPage == 0 ? null : _goBack,
      onNext: _goNext,
      onSkip: _complete,
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _currentPage = i),
        children: [
          const TutorialWelcomePage(),
          TutorialSandboxPage(onUserCompleted: _onPage1Done),
          TutorialItemsPage(onUserCompleted: _onPage2Done),
          const TutorialFinalePage(),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Remover arquivos antigos**

```bash
git rm lib/presentation/screens/tutorial/widgets/tutorial_mini_board.dart
git rm lib/presentation/screens/tutorial/pages/tutorial_movement_page.dart
git rm lib/presentation/screens/tutorial/pages/tutorial_fusion_page.dart
```

- [ ] **Step 3: Verificar análise geral**

```bash
flutter analyze lib/
```

Expected: no errors. Se houver imports órfãos em outros arquivos apontando para os arquivos deletados, removê-los.

- [ ] **Step 4: Rodar a suite de testes completa**

```bash
flutter test
```

Expected: todos os testes passam. Se algum golden test falhar, é esperado — o CI os regenera automaticamente (ver nota no spec).

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/screens/tutorial/tutorial_screen.dart
git commit -m "feat(tutorial): integra sandbox 4×4 e demo ferramentas; remove páginas 1D antigas

- TutorialScreen: 4 páginas (era 5), gating nas páginas 1 e 2
- Remove tutorial_mini_board, tutorial_movement_page, tutorial_fusion_page"
```

---

## Self-Review

### Cobertura do spec

| Requisito do spec | Tarefa |
|---|---|
| BoardWidget param board opcional | Task 1 |
| BombGridOverlay params opcionais | Task 2 |
| BombDimOverlay params opcionais | Task 2 |
| TutorialBoard widget (swipe → Direction) | Task 3 |
| Sandbox passo A: mover tudo | Task 5 |
| Sandbox passo B: unir dois iguais (+ animal diferente não une) | Task 5 |
| Sandbox passo C: jogo livre, gradua com 2 uniões | Task 5 |
| Demo bomba: BombDimOverlay + BombGridOverlay standalone + BombExplosionOverlay | Task 6 |
| Demo desfazer: VhsRewindOverlay + undoStack local | Task 6 |
| Demo vidas: corações + texto curto | Task 6 |
| TutorialScreen 4 páginas, gating páginas 1 e 2 | Task 7 |
| Deletar tutorial_mini_board, tutorial_movement_page, tutorial_fusion_page | Task 7 |
| Widget test gating sandbox | Task 4 + 5 |
| Goldens precisam regenerar no CI | nota em Task 7 Step 4 |
| Texto UI em PT-BR, sem termos em inglês | aplicado em todos os textos |
| Verbo "unir/juntar" nunca "fundir" | aplicado em Task 5 textos |
| GlassPanel para blocos instrução, Fredoka, OutlinedText | aplicado Tasks 5 e 6 |

### Placeholders e riscos

- **`selectedBombTiles` cast**: `List<(int, int)>` → `Set<(int, int)>` em `BombGridOverlay`. O cast `.toSet()` funciona; se o tipo exato não aceitar, usar `Set<(int, int)>.from(...)`. O implementador deve verificar e ajustar.
- **Import `Tile` em `BoardWidget`**: verificar se já está disponível via `TileWidget`; adicionar import direto se necessário.
- **`TutorialItemsPage` não recebe `onUserCompleted` nas páginas antigas**: a reescrita adiciona esse parâmetro — `TutorialScreen` já passa `onUserCompleted: _onPage2Done`.
- **Goldens do tutorial**: vão falhar localmente após mudança de 5 para 4 páginas. CI regenera. Não é bug.
