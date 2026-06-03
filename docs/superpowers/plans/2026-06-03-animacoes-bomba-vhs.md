# Animações de Bomba (explosão) e Desfazer (efeito VHS) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar animação de explosão ao usar Bomb2/Bomb3 e efeito VHS fullscreen ao usar Undo1/Undo3, ambos respeitando `animationsEnabled`.

**Architecture:** Dois widgets novos (`BombExplosionOverlay`, `VhsRewindOverlay`). O auto-confirm de bomba é removido do `game_notifier` para que o `GameScreen` possa exibir a explosão antes de confirmar. Para undo, um callback `onUndoUsed(bool isUndo3)` é adicionado ao `InventoryBar` e ao `GameOverItemOverlay`; o `GameScreen` escuta e exibe o VHS.

**Tech Stack:** Flutter/Dart, `flutter_animate`, `CustomPainter`, `flutter_riverpod`.

**Spec:** `docs/superpowers/specs/2026-06-03-animacoes-bomba-vhs-design.md`

---

## File Map

| Arquivo | Operação |
| --- | --- |
| `lib/presentation/controllers/game_notifier.dart` | Editar — remover auto-confirm no `selectBombTile` |
| `lib/presentation/widgets/bomb_explosion_overlay.dart` | **Criar** — explosão sobre tiles selecionados |
| `lib/presentation/widgets/vhs_rewind_overlay.dart` | **Criar** — efeito VHS fullscreen |
| `lib/presentation/widgets/inventory_bar.dart` | Editar — adicionar callback `onUndoUsed` |
| `lib/presentation/screens/game/game_over_item_overlay.dart` | Editar — adicionar callback `onUndoUsed` |
| `lib/presentation/screens/game/game_screen.dart` | Editar — wiring de estado local + overlays |
| `test/presentation/widgets/bomb_explosion_overlay_test.dart` | **Criar** |
| `test/presentation/widgets/vhs_rewind_overlay_test.dart` | **Criar** |

---

## Task 1: game_notifier — remover auto-confirm do selectBombTile

**Files:**
- Modify: `lib/presentation/controllers/game_notifier.dart:322-341`

- [ ] **Step 1: Localizar e remover o bloco de auto-confirm**

Em `lib/presentation/controllers/game_notifier.dart`, dentro de `selectBombTile`, remover as linhas:

```dart
      if (_bombSelection.length == maxTiles) {
        confirmBomb();
        return;
      }
```

O método completo após a edição deve ficar:

```dart
  void selectBombTile(int row, int col) {
    final mode = state.bombMode;
    if (mode == null) return;
    final maxTiles = mode == BombMode.bomb2 ? 2 : 3;

    final pos = (row, col);
    if (_bombSelection.contains(pos)) {
      _bombSelection = _bombSelection.where((p) => p != pos).toList();
    } else if (_bombSelection.length < maxTiles) {
      _bombSelection = [..._bombSelection, pos];
    }
    // Emit updated selection so overlay rebuilds on every selection change,
    // including the final selection (GameScreen will detect and confirm).
    state = state.copyWith(
      selectedBombTiles: List.unmodifiable(_bombSelection),
    );
  }
```

- [ ] **Step 2: Verify analyze**

Run: `flutter analyze lib/presentation/controllers/game_notifier.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/controllers/game_notifier.dart
git commit -m "feat(anim): game_notifier — remover auto-confirm de bomba (GameScreen confirma pós-animação)"
```

---

## Task 2: BombExplosionOverlay (novo widget)

**Files:**
- Create: `lib/presentation/widgets/bomb_explosion_overlay.dart`
- Create: `test/presentation/widgets/bomb_explosion_overlay_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/presentation/widgets/bomb_explosion_overlay_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capivara_2048/presentation/widgets/bomb_explosion_overlay.dart';

void main() {
  group('BombExplosionOverlay', () {
    testWidgets('renderiza sem crash com posições válidas', (tester) async {
      bool completed = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 300,
                child: BombExplosionOverlay(
                  positions: const [(0, 0), (1, 2)],
                  isBomb3: false,
                  onComplete: () => completed = true,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(BombExplosionOverlay), findsOneWidget);
    });

    testWidgets('onComplete é chamado após a animação', (tester) async {
      bool completed = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 300,
                child: BombExplosionOverlay(
                  positions: const [(0, 0)],
                  isBomb3: true,
                  onComplete: () => completed = true,
                ),
              ),
            ),
          ),
        ),
      );
      // Avançar além da duração da animação (350ms + margem)
      await tester.pump(const Duration(milliseconds: 500));
      expect(completed, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/widgets/bomb_explosion_overlay_test.dart`
Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 3: Create the widget**

Create `lib/presentation/widgets/bomb_explosion_overlay.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/game_constants.dart';

/// Shows explosion particles over each selected bomb tile.
/// Uses the same grid layout as BombGridOverlay for pixel-perfect alignment.
class BombExplosionOverlay extends StatefulWidget {
  const BombExplosionOverlay({
    super.key,
    required this.positions,
    required this.isBomb3,
    required this.onComplete,
  });

  final List<(int, int)> positions;
  final bool isBomb3;
  final VoidCallback onComplete;

  static const _duration = Duration(milliseconds: 350);

  @override
  State<BombExplosionOverlay> createState() => _BombExplosionOverlayState();
}

class _BombExplosionOverlayState extends State<BombExplosionOverlay> {
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(BombExplosionOverlay._duration, () {
      if (mounted && !_completed) {
        _completed = true;
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                    padding: const EdgeInsets.all(
                      GameConstants.tileSpacing / 2,
                    ),
                    child: widget.positions.contains((r, c))
                        ? _ExplosionCell(isBomb3: widget.isBomb3)
                        : const SizedBox.expand(),
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

class _ExplosionCell extends StatelessWidget {
  const _ExplosionCell({required this.isBomb3});
  final bool isBomb3;

  @override
  Widget build(BuildContext context) {
    final color = isBomb3 ? Colors.red.shade600 : Colors.orange.shade500;
    final size = isBomb3 ? 1.6 : 1.3;
    return Center(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.85),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.6),
              blurRadius: 12,
              spreadRadius: 4,
            ),
          ],
        ),
      )
          .animate()
          .scale(
            begin: const Offset(0.2, 0.2),
            end: Offset(size, size),
            duration: BombExplosionOverlay._duration,
            curve: Curves.easeOutCubic,
          )
          .fadeOut(
            delay: const Duration(milliseconds: 150),
            duration: const Duration(milliseconds: 200),
          ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/widgets/bomb_explosion_overlay_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/bomb_explosion_overlay.dart test/presentation/widgets/bomb_explosion_overlay_test.dart
git commit -m "feat(anim): BombExplosionOverlay — flash de explosão sobre tiles da bomba"
```

---

## Task 3: VhsRewindOverlay (novo widget)

**Files:**
- Create: `lib/presentation/widgets/vhs_rewind_overlay.dart`
- Create: `test/presentation/widgets/vhs_rewind_overlay_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/presentation/widgets/vhs_rewind_overlay_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/presentation/widgets/vhs_rewind_overlay.dart';

void main() {
  group('VhsRewindOverlay', () {
    testWidgets('renderiza sem crash — undo1', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VhsRewindOverlay(
              isUndo3: false,
              onComplete: () {},
            ),
          ),
        ),
      );
      expect(find.byType(VhsRewindOverlay), findsOneWidget);
    });

    testWidgets('renderiza sem crash — undo3', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VhsRewindOverlay(
              isUndo3: true,
              onComplete: () {},
            ),
          ),
        ),
      );
      expect(find.byType(VhsRewindOverlay), findsOneWidget);
    });

    testWidgets('onComplete é chamado ao terminar', (tester) async {
      bool completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VhsRewindOverlay(
              isUndo3: false,
              onComplete: () => completed = true,
            ),
          ),
        ),
      );
      // Undo1 = 500ms; avançar além disso
      await tester.pump(const Duration(milliseconds: 600));
      expect(completed, isTrue);
    });

    testWidgets('undo3 dura mais que undo1', (tester) async {
      // Undo1: completa em 500ms. Verificar que undo3 NÃO completa em 500ms.
      bool completed3 = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VhsRewindOverlay(
              isUndo3: true,
              onComplete: () => completed3 = true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(completed3, isFalse);
      // Avançar além de 750ms — agora deve completar
      await tester.pump(const Duration(milliseconds: 300));
      expect(completed3, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/widgets/vhs_rewind_overlay_test.dart`
Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 3: Create the widget**

Create `lib/presentation/widgets/vhs_rewind_overlay.dart`:

```dart
import 'dart:math';
import 'package:flutter/material.dart';

/// Full-screen VHS rewind effect overlay.
/// A CustomPainter animates scanlines, glitch bands, a rewind line,
/// and a brief white flash — all drawn on top of the game content below.
class VhsRewindOverlay extends StatefulWidget {
  const VhsRewindOverlay({
    super.key,
    required this.isUndo3,
    required this.onComplete,
  });

  final bool isUndo3;
  final VoidCallback onComplete;

  @override
  State<VhsRewindOverlay> createState() => _VhsRewindOverlayState();
}

class _VhsRewindOverlayState extends State<VhsRewindOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final duration = widget.isUndo3
        ? const Duration(milliseconds: 750)
        : const Duration(milliseconds: 500);
    _controller = AnimationController(vsync: this, duration: duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          widget.onComplete();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _VhsPainter(
          progress: _controller.value,
          isUndo3: widget.isUndo3,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _VhsPainter extends CustomPainter {
  const _VhsPainter({required this.progress, required this.isUndo3});

  final double progress;
  final bool isUndo3;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dark translucent overlay
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0x88000000),
    );

    // 2. Horizontal scanlines
    final scanPaint = Paint()..color = const Color(0x26000000);
    for (double y = 0; y < size.height; y += 6) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2), scanPaint);
    }

    // 3. White flash at the beginning (first 25% of animation)
    if (progress < 0.25) {
      final flashOpacity = (1.0 - progress / 0.25) * 0.55;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Color.fromRGBO(255, 255, 255, flashOpacity),
      );
    }

    // 4. Rewind line (bright horizontal bar moving bottom to top)
    final lineY = size.height * (1.0 - progress);
    canvas.drawRect(
      Rect.fromLTWH(0, lineY - 1, size.width, 4),
      Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, lineY, size.width, 2),
      Paint()..color = Colors.white,
    );

    // 5. Glitch bands (random horizontal offsets, seeded by frame)
    final rng = Random((progress * 1000).toInt());
    final bandCount = isUndo3 ? 10 : 6;
    final glitchPaint = Paint();
    for (int i = 0; i < bandCount; i++) {
      final y = rng.nextDouble() * size.height;
      final h = rng.nextDouble() * 3 + 1;
      final xOff = (rng.nextDouble() - 0.5) * 16;
      final opacity = rng.nextDouble() * 0.25 + 0.08;
      glitchPaint.color = Color.fromRGBO(255, 255, 255, opacity);
      canvas.drawRect(Rect.fromLTWH(xOff, y, size.width, h), glitchPaint);
    }
  }

  @override
  bool shouldRepaint(_VhsPainter old) => old.progress != progress;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/widgets/vhs_rewind_overlay_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/vhs_rewind_overlay.dart test/presentation/widgets/vhs_rewind_overlay_test.dart
git commit -m "feat(anim): VhsRewindOverlay — efeito VHS fullscreen para desfazer"
```

---

## Task 4: InventoryBar — adicionar callback onUndoUsed

**Files:**
- Modify: `lib/presentation/widgets/inventory_bar.dart`

- [ ] **Step 1: Adicionar o parâmetro e as chamadas**

Em `lib/presentation/widgets/inventory_bar.dart`, adicionar o parâmetro `onUndoUsed` na classe `InventoryBar` e chamá-lo nas funções `useUndo1` e `useUndo3`:

```dart
class InventoryBar extends ConsumerWidget {
  const InventoryBar({
    super.key,
    this.onTapWhenEmpty,
    this.pulsingItems = const {},
    this.iconSize = GameConstants.inventoryIconSize,
    this.onUndoUsed,                          // <-- ADD
  });

  final void Function(ItemType)? onTapWhenEmpty;
  final Set<ItemType> pulsingItems;
  final double iconSize;
  final void Function(bool isUndo3)? onUndoUsed; // <-- ADD
```

Na função `useUndo1`, após `ref.read(inventoryProvider.notifier).consume(ItemType.undo1);`:
```dart
      if (undone) {
        ref.read(inventoryProvider.notifier).consume(ItemType.undo1);
        onUndoUsed?.call(false);              // <-- ADD
      }
```

Na função `useUndo3`, mesma coisa:
```dart
      if (undone) {
        ref.read(inventoryProvider.notifier).consume(ItemType.undo3);
        onUndoUsed?.call(true);               // <-- ADD
      }
```

O arquivo completo das funções `useUndo1` e `useUndo3` após a edição:

```dart
    Future<void> useUndo1() async {
      final ok = await showConfirmUseDialog(
        context: context,
        itemName: 'Desfazer 1',
        description: 'Desfaz o último movimento.',
        pngPath: 'assets/images/inventory/undo_1.webp',
      );
      if (!ok) return;
      final undone = ref.read(gameProvider.notifier).undo(1);
      if (undone) {
        ref.read(inventoryProvider.notifier).consume(ItemType.undo1);
        onUndoUsed?.call(false);
      }
    }

    Future<void> useUndo3() async {
      final ok = await showConfirmUseDialog(
        context: context,
        itemName: 'Desfazer 3',
        description: 'Desfaz os últimos 3 movimentos.',
        pngPath: 'assets/images/inventory/undo_3.webp',
      );
      if (!ok) return;
      final undone = ref.read(gameProvider.notifier).undo(3);
      if (undone) {
        ref.read(inventoryProvider.notifier).consume(ItemType.undo3);
        onUndoUsed?.call(true);
      }
    }
```

- [ ] **Step 2: Verify analyze**

Run: `flutter analyze lib/presentation/widgets/inventory_bar.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/inventory_bar.dart
git commit -m "feat(anim): InventoryBar — callback onUndoUsed para VHS"
```

---

## Task 5: GameOverItemOverlay — adicionar callback onUndoUsed

**Files:**
- Modify: `lib/presentation/screens/game/game_over_item_overlay.dart`

- [ ] **Step 1: Adicionar o parâmetro no widget e a chamada em _useItem**

Em `lib/presentation/screens/game/game_over_item_overlay.dart`:

**1. Mudar `GameOverItemOverlay` para aceitar o callback:**

```dart
class GameOverItemOverlay extends ConsumerStatefulWidget {
  const GameOverItemOverlay({super.key, this.onUndoUsed}); // <-- ADD param

  final void Function(bool isUndo3)? onUndoUsed;          // <-- ADD field

  @override
  ConsumerState<GameOverItemOverlay> createState() =>
      _GameOverItemOverlayState();
}
```

**2. Chamar o callback em `_useItem` para os casos de undo:**

```dart
  void _useItem(ItemType type) {
    _hapticController.stop();
    final notifier = ref.read(gameProvider.notifier);
    switch (type) {
      case ItemType.bomb2:
        notifier.startContinueWithItem();
        notifier.enterBombMode(BombMode.bomb2, type);
      case ItemType.bomb3:
        notifier.startContinueWithItem();
        notifier.enterBombMode(BombMode.bomb3, type);
      case ItemType.undo1:
        final undone = notifier.undo(1);
        if (undone) {
          ref.read(inventoryProvider.notifier).consume(type);
          widget.onUndoUsed?.call(false);    // <-- ADD
        }
        notifier.startContinueWithItem();
      case ItemType.undo3:
        final undone = notifier.undo(3);
        if (undone) {
          ref.read(inventoryProvider.notifier).consume(type);
          widget.onUndoUsed?.call(true);     // <-- ADD
        }
        notifier.startContinueWithItem();
    }
  }
```

- [ ] **Step 2: Verify analyze**

Run: `flutter analyze lib/presentation/screens/game/game_over_item_overlay.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/screens/game/game_over_item_overlay.dart
git commit -m "feat(anim): GameOverItemOverlay — callback onUndoUsed para VHS"
```

---

## Task 6: GameScreen — wiring completo (estado local + overlays)

**Files:**
- Modify: `lib/presentation/screens/game/game_screen.dart`

- [ ] **Step 1: Adicionar imports**

No topo de `lib/presentation/screens/game/game_screen.dart`, adicionar:

```dart
import '../../widgets/bomb_explosion_overlay.dart';
import '../../widgets/vhs_rewind_overlay.dart';
import '../../../domain/game_engine/bomb_mode.dart';
import '../../controllers/performance_settings_notifier.dart';
```

(Verificar se `performance_settings_notifier.dart` já está importado — ele já está na linha 29. Verificar se `bomb_mode.dart` já está importado — não está, precisa adicionar.)

- [ ] **Step 2: Adicionar estado local na classe `_GameScreenState`**

Logo após os campos existentes (`_shopItem`, `_pulsingItems`, `_fpsMonitorNotifier`), adicionar:

```dart
  // Bomb explosion state
  bool _showBombExplosion = false;
  List<(int, int)> _bombExplosionPositions = [];
  bool _isBomb3Explosion = false;

  // VHS rewind state
  bool _showVhsRewind = false;
  bool _isUndo3Rewind = false;
```

- [ ] **Step 3: Adicionar `_handleUndoUsed` e `_onBombExplosionComplete`**

Adicionar dois métodos auxiliares antes de `build`:

```dart
  void _handleUndoUsed(bool isUndo3) {
    final animEnabled = ref.read(
      performanceSettingsProvider.select((s) => s.animationsEnabled),
    );
    if (!animEnabled) return;
    setState(() {
      _showVhsRewind = true;
      _isUndo3Rewind = isUndo3;
    });
  }

  void _onBombExplosionComplete() {
    ref.read(gameProvider.notifier).confirmBomb();
    setState(() {
      _showBombExplosion = false;
      _bombExplosionPositions = [];
    });
  }
```

- [ ] **Step 4: Adicionar ref.listen para detectar bomba cheia**

No método `build`, dentro do bloco de `ref.listen<GameState>(gameProvider, ...)` existente (que começa na linha ~108), adicionar detecção de bomba cheia ao final do corpo do listener:

```dart
    ref.listen<GameState>(gameProvider, (previous, current) {
      // ... código existente de isGameOver, pendingMilestone ...

      // Detectar seleção de bomba completa → mostrar explosão
      if (current.bombMode != null && previous?.bombMode != null) {
        final maxTiles = current.bombMode == BombMode.bomb2 ? 2 : 3;
        final prevCount = previous?.selectedBombTiles.length ?? 0;
        if (current.selectedBombTiles.length == maxTiles &&
            prevCount < maxTiles &&
            !_showBombExplosion) {
          final animEnabled = ref.read(
            performanceSettingsProvider.select((s) => s.animationsEnabled),
          );
          if (animEnabled) {
            setState(() {
              _showBombExplosion = true;
              _bombExplosionPositions =
                  List<(int, int)>.from(current.selectedBombTiles);
              _isBomb3Explosion = current.bombMode == BombMode.bomb3;
            });
          } else {
            // Sem animação: confirma imediatamente
            ref.read(gameProvider.notifier).confirmBomb();
          }
        }
      }
    });
```

- [ ] **Step 5: Adicionar `BombExplosionOverlay` no Stack interno do tabuleiro**

No Stack interno (dentro do `LayoutBuilder` do tabuleiro, onde já existe `BombGridOverlay`), adicionar o overlay de explosão após `BombGridOverlay`:

```dart
                                    return Stack(
                                      children: [
                                        // ... GestureDetector com BoardWidget ...
                                        if (state.bombMode != null)
                                          const Positioned.fill(
                                            child: BombGridOverlay(),
                                          ),
                                        if (_showBombExplosion)        // <-- ADD
                                          Positioned.fill(             // <-- ADD
                                            child: BombExplosionOverlay( // <-- ADD
                                              positions: _bombExplosionPositions, // <-- ADD
                                              isBomb3: _isBomb3Explosion,         // <-- ADD
                                              onComplete: _onBombExplosionComplete, // <-- ADD
                                            ),                         // <-- ADD
                                          ),                           // <-- ADD
                                      ],
                                    );
```

- [ ] **Step 6: Adicionar `VhsRewindOverlay` no Stack externo (fullscreen)**

No Stack externo (logo antes do fechamento, onde estão `PauseOverlay`, `BombDimOverlay` etc.), adicionar:

```dart
                  if (_showVhsRewind)                     // <-- ADD
                    Positioned.fill(                       // <-- ADD
                      child: VhsRewindOverlay(             // <-- ADD
                        isUndo3: _isUndo3Rewind,           // <-- ADD
                        onComplete: () => setState(        // <-- ADD
                          () => _showVhsRewind = false,    // <-- ADD
                        ),                                 // <-- ADD
                      ),                                   // <-- ADD
                    ),                                     // <-- ADD
```

- [ ] **Step 7: Passar callbacks para InventoryBar e GameOverItemOverlay**

**InventoryBar** (linha ~279): passar o callback `onUndoUsed`:

```dart
                        AbsorbPointer(
                          absorbing: state.isAwaitingGameOverResolution,
                          child: InventoryBar(
                            iconSize: invIconSz,
                            onTapWhenEmpty: _openShop,
                            pulsingItems: _pulsingItems,
                            onUndoUsed: _handleUndoUsed,   // <-- ADD
                          ),
                        ),
```

**GameOverItemOverlay** (linha ~294): mudar de `const` para instância com callback:

```dart
                  if (state.isAwaitingGameOverResolution && hasAnyItem)
                    Positioned.fill(                        // <-- REMOVE const
                      child: GameOverItemOverlay(
                        onUndoUsed: _handleUndoUsed,       // <-- ADD
                      ),
                    ),
```

- [ ] **Step 8: Verify analyze**

Run: `flutter analyze lib/presentation/screens/game/game_screen.dart`
Expected: `No issues found!`

- [ ] **Step 9: Run all widget tests**

Run: `flutter test test/presentation/widgets/`
Expected: PASS — `bomb_explosion_overlay_test` e `vhs_rewind_overlay_test` passam.

- [ ] **Step 10: Commit**

```bash
git add lib/presentation/screens/game/game_screen.dart
git commit -m "feat(anim): GameScreen — wiring explosão bomba + VHS desfazer"
```

---

## Task 7: Verificação final + docs

**Files:** nenhum código (verificação e release notes).

- [ ] **Step 1: Rodar testes relevantes**

Run: `flutter test test/presentation/widgets/ test/domain/`
Expected: todos passam; zero regressões.

- [ ] **Step 2: Analyze geral**

Run: `flutter analyze lib/presentation/`
Expected: `No issues found!`

- [ ] **Step 3: Smoke manual no dispositivo**

Run: `flutter run --flavor tst --dart-define=FLAVOR=dev`

Verificar:
- Bomb2: selecionar 2 tiles → flash laranja explode → tiles somem.
- Bomb3: selecionar 3 tiles → flash vermelho maior explode → tiles somem.
- Undo1 (inventário): usar → overlay VHS 500ms → tabuleiro reverte.
- Undo3 (inventário): usar → overlay VHS 750ms mais intenso → 3 estados revertidos.
- Undo1/Undo3 (game over overlay): mesmos efeitos.
- Com animações desativadas nas Configurações: nenhum dos efeitos aparece.

- [ ] **Step 4: Atualizar CHANGELOG e bump de versão**

Em `pubspec.yaml`:
```yaml
version: 1.9.30+36
```

Em `CHANGELOG.md`, adicionar abaixo de `## [Unreleased]`:

```markdown
## [1.9.30] — 2026-06-03

### Added

- **Animação de explosão nas bombas**: ao usar Bomba 2 ou Bomba 3, cada tile selecionado exibe um flash circular de explosão antes de ser removido — laranja para Bomb2, vermelho para Bomb3
- **Efeito VHS ao desfazer**: ao usar Desfazer 1 ou Desfazer 3, um overlay de tela inteira simula uma fita VHS sendo rebobinada (scanlines, glitch, linha de rebobinagem). Undo3 tem duração e intensidade maiores
- Ambas as animações respeitam a configuração "Animações" em Configurações → Desempenho
```

- [ ] **Step 5: Commit final**

```bash
git add pubspec.yaml CHANGELOG.md
git commit -m "chore(release): v1.9.30+36 — animações explosão bomba + VHS desfazer"
```

---

## Notas de implementação

- **Por que remover o auto-confirm em Task 1:** `selectBombTile` chamava `confirmBomb()` imediatamente ao atingir o máximo, sem emitir o estado intermediário com a seleção completa. A animação precisa ser exibida ANTES de remover os tiles — então o `GameScreen` passa a ser responsável por chamar `confirmBomb()` no `onComplete` do overlay.
- **Sem animação:** quando `animationsEnabled == false`, `GameScreen` chama `confirmBomb()` imediatamente (sem overlay). Para undo, simplesmente não cria o VhsRewindOverlay.
- **Race condition:** o `_showBombExplosion` flag evita duplo-disparo se `ref.listen` for chamado mais de uma vez.
- **BombGridOverlay continua visível** durante a explosão (ficam sobrepostos no mesmo Stack) — o player vê a seleção e depois o flash por cima.
- **`GameOverItemOverlay` deixa de ser `const`** porque passa a receber um callback — isso é correto e esperado.
