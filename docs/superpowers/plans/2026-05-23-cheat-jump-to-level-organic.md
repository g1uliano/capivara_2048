# Cheat Menu — "Ir para Nível" Orgânico — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fazer o cheat "Ir para Nível N" configurar o tabuleiro com dois tiles adjacentes de nível N-1 (ao invés de colocar um tile de nível N diretamente), permitindo testar o fluxo de milestone organicamente.

**Architecture:** Mudança cirúrgica em `debugJumpToLevel` no `game_notifier.dart`: novo layout do board com par adjacente + `maxLevel: targetLevel - 1`. Testes existentes atualizados para refletir o novo contrato.

**Tech Stack:** Flutter/Dart, Riverpod, flutter_test

---

### Task 1: Atualizar testes de `debugJumpToLevel`

**Files:**
- Modify: `test/presentation/game_notifier_debug_test.dart`

- [ ] **Step 1: Atualizar teste "sets maxLevel to target"**

O contrato mudou: `maxLevel` agora é `targetLevel - 1`.

Substitui no arquivo `test/presentation/game_notifier_debug_test.dart`:

```dart
    test('sets maxLevel to targetLevel minus 1', () {
      container.read(gameProvider.notifier).debugJumpToLevel(7);
      expect(container.read(gameProvider).maxLevel, 6);
    });
```

- [ ] **Step 2: Substituir teste "board contains tile at targetLevel"**

O board não tem mais tile em targetLevel — tem dois tiles em targetLevel-1, adjacentes.

Substitui o teste `'board contains tile at targetLevel'` por:

```dart
    test('board contains exactly two tiles at targetLevel - 1', () {
      container.read(gameProvider.notifier).debugJumpToLevel(7);
      final board = container.read(gameProvider).board;
      final tilesAtTarget = board
          .expand((row) => row)
          .whereType<Tile>()
          .where((t) => t.level == 6)
          .toList();
      expect(tilesAtTarget.length, 2);
    });

    test('the two merge tiles are adjacent (same row, consecutive cols)', () {
      container.read(gameProvider.notifier).debugJumpToLevel(7);
      final board = container.read(gameProvider).board;
      final mergeTiles = board
          .expand((row) => row)
          .whereType<Tile>()
          .where((t) => t.level == 6)
          .toList();
      expect(mergeTiles.length, 2);
      // ambos na linha 0, colunas 2 e 3
      final rows = mergeTiles.map((t) => t.row).toSet();
      final cols = mergeTiles.map((t) => t.col).toList()..sort();
      expect(rows.length, 1);
      expect(cols[1] - cols[0], 1);
    });
```

- [ ] **Step 3: Rodar os testes para confirmar que falham**

```bash
flutter test test/presentation/game_notifier_debug_test.dart
```

Esperado: falhas em `sets maxLevel to targetLevel minus 1`, `board contains exactly two tiles at targetLevel - 1`, `the two merge tiles are adjacent`.

---

### Task 2: Implementar novo `debugJumpToLevel`

**Files:**
- Modify: `lib/presentation/controllers/game_notifier.dart:214-251`

- [ ] **Step 1: Substituir o corpo de `debugJumpToLevel`**

Localiza o método (linha ~214) e substitui o corpo completo:

```dart
  @visibleForTesting
  void debugJumpToLevel(int targetLevel) {
    if (!kDebugMode) return;

    const uuid = Uuid();
    Tile makeTile(int level, int row, int col) =>
        Tile(id: uuid.v4(), level: level, row: row, col: col);
    int lvl(int delta) => max(1, targetLevel - delta);

    final board = List.generate(4, (_) => List<Tile?>.filled(4, null));
    board[0][2] = makeTile(lvl(1), 0, 2); // merge tile 1
    board[0][3] = makeTile(lvl(1), 0, 3); // merge tile 2 — adjacente, swipe direita os junta
    board[1][3] = makeTile(lvl(2), 1, 3);
    board[2][0] = makeTile(lvl(4), 2, 0);
    board[2][2] = makeTile(lvl(3), 2, 2);
    board[3][0] = makeTile(1, 3, 0);
    board[3][2] = makeTile(1, 3, 2);

    final score = board
        .expand((row) => row)
        .whereType<Tile>()
        .fold(0, (sum, t) => sum + (1 << t.level));

    _stopTimer();
    _firestoreSaveTimer?.cancel();
    _timerStarted = true;
    _reachedMilestones.clear();
    _populateMilestonesFromMaxLevel(targetLevel - 1);
    state = GameState(
      board: board,
      score: score,
      highScore: max(state.highScore, score),
      maxLevel: targetLevel - 1,
      hasWon: false,
      isGameOver: false,
      isPaused: false,
      elapsedMs: state.elapsedMs,
    );
  }
```

Diferenças-chave vs. versão anterior:
- Par de merge em `[0][2]` e `[0][3]` (ambos `lvl(1)`)
- `maxLevel: targetLevel - 1` (não mais `targetLevel`)
- Linha `if (targetLevel >= 11) _handleMilestoneReached(targetLevel)` **removida**

- [ ] **Step 2: Rodar os testes**

```bash
flutter test test/presentation/game_notifier_debug_test.dart
```

Esperado: todos os 9 testes passando.

- [ ] **Step 3: Rodar a suite completa para verificar regressões**

```bash
flutter test
```

Esperado: sem novas falhas.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/controllers/game_notifier.dart \
        test/presentation/game_notifier_debug_test.dart \
        docs/superpowers/specs/2026-05-23-cheat-jump-to-level-organic-design.md \
        docs/superpowers/plans/2026-05-23-cheat-jump-to-level-organic.md
git commit -m "fix(cheat): debugJumpToLevel configura board pré-merge ao invés de injetar tile direto"
```
