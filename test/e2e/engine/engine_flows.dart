import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/game_state.dart';
import 'package:capivara_2048/data/models/tile.dart';
import 'package:capivara_2048/domain/game_engine/direction.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import '../_harness/scenario.dart';
import '../_harness/test_harness.dart';
import '../_harness/tester_extensions.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

Future<void> _bootToGame(WidgetTester tester, GameTestHarness harness) async {
  final widget = await tester.runAsync(() => harness.boot());
  await tester.pumpWidget(widget!);
  await tester.pumpAndSettle(const Duration(seconds: 5));
  await tester.gotoGame(harness);
}

List<List<Tile?>> _emptyBoard() =>
    List.generate(4, (_) => List<Tile?>.filled(4, null));

void _setState(GameTestHarness harness, GameState s) =>
    harness.container.read(gameProvider.notifier).debugSetState(s);

GameState _readState(GameTestHarness harness) =>
    harness.container.read(gameProvider);

/// Executa swipe via notifier e para o timer imediatamente.
///
/// `onSwipe` chama `_startTimer()` em moves válidos — o timer periódico de
/// 100 ms ficaria pendente ao fim do teste, causando falha do binding.
/// Chamar `debugSetState` com o estado atual interrompe o timer sem alterar
/// o estado — o mesmo padrão usado pelos testes de Fase 3.1.
void _swipeAndStop(GameTestHarness harness, Direction dir) {
  harness.container.read(gameProvider.notifier).onSwipe(dir);
  // Stop timer immediately (no state change).
  final s = harness.container.read(gameProvider);
  harness.container.read(gameProvider.notifier).debugSetState(s);
}

// ─── engine.swipe_left_merges_correctly ──────────────────────────────────────

final engineSwipeLeftScenario = E2EScenario(
  id: 'engine.swipe_left_merges_correctly',
  title: 'swipe esquerda: dois tiles iguais na mesma linha → merge',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    // Setup: row 0 = [level:2, level:2, null, null]
    final board = _emptyBoard();
    board[0][0] = const Tile(id: 'a', level: 2, row: 0, col: 0);
    board[0][1] = const Tile(id: 'b', level: 2, row: 0, col: 1);
    _setState(harness, GameState(
      board: board, score: 0, highScore: 0, maxLevel: 2,
      isGameOver: false, hasWon: false,
    ));

    _swipeAndStop(harness, Direction.left);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final state = _readState(harness);
    // Dois tiles level:2 → merge em level:3, score += 2^3 = 8
    expect(state.board[0][0]?.level, equals(3),
        reason: 'dois tiles level:2 swipe left → merge em [0][0] level:3');
    expect(state.score, equals(8));
    // Spawn: pelo menos 2 tiles no board (merged + 1 novo)
    final tileCount = state.board.expand((r) => r).whereType<Tile>().length;
    expect(tileCount, greaterThanOrEqualTo(2),
        reason: 'merge gera spawn de novo tile');
  },
);

// ─── engine.swipe_right_merges_correctly ─────────────────────────────────────

final engineSwipeRightScenario = E2EScenario(
  id: 'engine.swipe_right_merges_correctly',
  title: 'swipe direita: dois tiles iguais → merge à direita',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    // Setup: row 0 = [null, null, level:2, level:2]
    final board = _emptyBoard();
    board[0][2] = const Tile(id: 'a', level: 2, row: 0, col: 2);
    board[0][3] = const Tile(id: 'b', level: 2, row: 0, col: 3);
    _setState(harness, GameState(
      board: board, score: 0, highScore: 0, maxLevel: 2,
      isGameOver: false, hasWon: false,
    ));

    _swipeAndStop(harness, Direction.right);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final state = _readState(harness);
    expect(state.board[0][3]?.level, equals(3),
        reason: 'dois tiles level:2 swipe right → merge em [0][3] level:3');
    expect(state.score, equals(8));
  },
);

// ─── engine.swipe_up_merges_correctly ────────────────────────────────────────

final engineSwipeUpScenario = E2EScenario(
  id: 'engine.swipe_up_merges_correctly',
  title: 'swipe cima: dois tiles iguais na mesma coluna → merge em cima',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    // Setup: col 0, rows 0 e 1
    final board = _emptyBoard();
    board[0][0] = const Tile(id: 'a', level: 2, row: 0, col: 0);
    board[1][0] = const Tile(id: 'b', level: 2, row: 1, col: 0);
    _setState(harness, GameState(
      board: board, score: 0, highScore: 0, maxLevel: 2,
      isGameOver: false, hasWon: false,
    ));

    _swipeAndStop(harness, Direction.up);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final state = _readState(harness);
    expect(state.board[0][0]?.level, equals(3),
        reason: 'dois tiles level:2 swipe up → merge em [0][0] level:3');
    expect(state.score, equals(8));
  },
);

// ─── engine.swipe_down_merges_correctly ──────────────────────────────────────

final engineSwipeDownScenario = E2EScenario(
  id: 'engine.swipe_down_merges_correctly',
  title: 'swipe baixo: dois tiles iguais na mesma coluna → merge em baixo',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    // Setup: col 0, rows 2 e 3
    final board = _emptyBoard();
    board[2][0] = const Tile(id: 'a', level: 2, row: 2, col: 0);
    board[3][0] = const Tile(id: 'b', level: 2, row: 3, col: 0);
    _setState(harness, GameState(
      board: board, score: 0, highScore: 0, maxLevel: 2,
      isGameOver: false, hasWon: false,
    ));

    _swipeAndStop(harness, Direction.down);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final state = _readState(harness);
    expect(state.board[3][0]?.level, equals(3),
        reason: 'dois tiles level:2 swipe down → merge em [3][0] level:3');
    expect(state.score, equals(8));
  },
);

// ─── engine.no_op_swipe_doesnt_consume_turn ──────────────────────────────────

final engineNoOpSwipeScenario = E2EScenario(
  id: 'engine.no_op_swipe_doesnt_consume_turn',
  title: 'swipe sem movimento possível → score inalterado, sem novo tile',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    // Tile único em [0][0] — swipe left é no-op (já está na coluna mais à esquerda)
    final board = _emptyBoard();
    board[0][0] = const Tile(id: 'a', level: 2, row: 0, col: 0);
    _setState(harness, GameState(
      board: board, score: 42, highScore: 42, maxLevel: 2,
      isGameOver: false, hasWon: false,
    ));

    // No-op não inicia timer (anyChanged = false), mas _swipeAndStop é seguro aqui tb.
    _swipeAndStop(harness, Direction.left);
    await tester.pump();

    final state = _readState(harness);
    expect(state.score, equals(42), reason: 'no-op não altera score');
    final tileCount = state.board.expand((r) => r).whereType<Tile>().length;
    expect(tileCount, equals(1), reason: 'no-op não spawna novo tile');
  },
);

// ─── engine.score_accumulates ────────────────────────────────────────────────

final engineScoreAccumulatesScenario = E2EScenario(
  id: 'engine.score_accumulates',
  title: 'múltiplos merges acumulam score: primeiro 4, segundo +8 = 12',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    // Primeiro merge: 2× level:1 → level:2, score += 2^2 = 4
    final board1 = _emptyBoard();
    board1[0][0] = const Tile(id: 'a', level: 1, row: 0, col: 0);
    board1[0][1] = const Tile(id: 'b', level: 1, row: 0, col: 1);
    _setState(harness, GameState(
      board: board1, score: 0, highScore: 0, maxLevel: 1,
      isGameOver: false, hasWon: false,
    ));

    _swipeAndStop(harness, Direction.left);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final s1 = _readState(harness);
    expect(s1.score, equals(4),
        reason: 'merge 2×level:1 → level:2, score += 2^2 = 4');

    // Segundo merge: 2× level:2 → level:3, score += 2^3 = 8
    final board2 = _emptyBoard();
    board2[0][0] = const Tile(id: 'c', level: 2, row: 0, col: 0);
    board2[0][1] = const Tile(id: 'd', level: 2, row: 0, col: 1);
    _setState(harness, GameState(
      board: board2, score: s1.score, highScore: s1.highScore, maxLevel: 2,
      isGameOver: false, hasWon: false,
    ));

    _swipeAndStop(harness, Direction.left);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final s2 = _readState(harness);
    expect(s2.score, equals(s1.score + 8),
        reason: 'merge 2×level:2 → level:3, acumula +8 sobre score anterior');
    expect(s2.score, equals(12),
        reason: 'score total: 4 (primeiro merge) + 8 (segundo merge) = 12');
  },
);

// ─── engine.high_score_updates_on_new_record ─────────────────────────────────

final engineHighScoreScenario = E2EScenario(
  id: 'engine.high_score_updates_on_new_record',
  title: 'merge que supera highScore → highScore atualizado',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    // Setup: score=10, highScore=10.
    // Merge 2×level:4 → level:5, gained = 2^5 = 32 → new score = 42 > 10
    final board = _emptyBoard();
    board[0][0] = const Tile(id: 'a', level: 4, row: 0, col: 0);
    board[0][1] = const Tile(id: 'b', level: 4, row: 0, col: 1);
    _setState(harness, GameState(
      board: board, score: 10, highScore: 10, maxLevel: 4,
      isGameOver: false, hasWon: false,
    ));

    _swipeAndStop(harness, Direction.left);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final state = _readState(harness);
    expect(state.score, equals(42), reason: '10 + 2^5 = 42');
    expect(state.highScore, equals(42),
        reason: 'highScore atualizado quando score > highScore anterior');
  },
);

// ─── engine.merge_chain_correct ──────────────────────────────────────────────

final engineMergeChainScenario = E2EScenario(
  id: 'engine.merge_chain_correct',
  title: '[2,2,2,null] swipe left → [3,2,null,spawn] — sem duplo merge',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    // Standard 2048: apenas primeiro par funde; terceiro tile move mas não funde.
    final board = _emptyBoard();
    board[0][0] = const Tile(id: 'a', level: 2, row: 0, col: 0);
    board[0][1] = const Tile(id: 'b', level: 2, row: 0, col: 1);
    board[0][2] = const Tile(id: 'c', level: 2, row: 0, col: 2);
    _setState(harness, GameState(
      board: board, score: 0, highScore: 0, maxLevel: 2,
      isGameOver: false, hasWon: false,
    ));

    _swipeAndStop(harness, Direction.left);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final state = _readState(harness);
    expect(state.board[0][0]?.level, equals(3),
        reason: 'par [a,b] funde em level:3');
    expect(state.board[0][1]?.level, equals(2),
        reason: 'tile c move para [0][1] mas NÃO funde (padrão 2048)');
    // Apenas 1 merge (2^3 = 8), não 2 (que seria 16)
    expect(state.score, equals(8),
        reason: 'somente 1 merge ocorre: score = 8, não 16');
  },
);

// ─── engine.spawn_only_after_valid_move ──────────────────────────────────────

final engineSpawnOnlyAfterValidMoveScenario = E2EScenario(
  id: 'engine.spawn_only_after_valid_move',
  title: 'no-op não spawna tile; move válido spawna exatamente 1 tile',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    // Tile único em [0][0]
    final board = _emptyBoard();
    board[0][0] = const Tile(id: 'a', level: 2, row: 0, col: 0);
    _setState(harness, GameState(
      board: board, score: 0, highScore: 0, maxLevel: 2,
      isGameOver: false, hasWon: false,
    ));

    // No-op: swipe left com tile em [0][0] — nenhum movimento
    _swipeAndStop(harness, Direction.left);
    await tester.pump();

    final countAfterNoOp =
        _readState(harness).board.expand((r) => r).whereType<Tile>().length;
    expect(countAfterNoOp, equals(1), reason: 'no-op não spawna tile');

    // Move válido: swipe right — tile move para [0][3], spawna 1 novo tile
    _swipeAndStop(harness, Direction.right);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final countAfterValid =
        _readState(harness).board.expand((r) => r).whereType<Tile>().length;
    expect(countAfterValid, equals(2),
        reason: 'move válido spawna exatamente 1 novo tile');
  },
);

// ─── engine.gameover_when_no_moves_possible ───────────────────────────────────

final engineGameOverScenario = E2EScenario(
  id: 'engine.gameover_when_no_moves_possible',
  title: 'board cheio com padrão xadrez → qualquer swipe → isGameOver = true',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    // Padrão xadrez 4×4: levels alternados 1 e 2 — sem adjacentes iguais.
    // Board 100% cheio → game over após qualquer swipe.
    //   1 2 1 2
    //   2 1 2 1
    //   1 2 1 2
    //   2 1 2 1
    final board = List.generate(4, (r) => List.generate(4, (c) {
      final level = (r + c) % 2 == 0 ? 1 : 2;
      return Tile(id: 't_${r}_$c', level: level, row: r, col: c);
    }));
    _setState(harness, GameState(
      board: board, score: 0, highScore: 0, maxLevel: 2,
      isGameOver: false, hasWon: false,
    ));

    // Este swipe é no-op (nenhuma linha/coluna move) mas isGameOver é detectado.
    // _stopTimer não é necessário aqui (no-op não inicia timer), mas usamos
    // _swipeAndStop por consistência.
    _swipeAndStop(harness, Direction.left);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final state = _readState(harness);
    expect(state.isGameOver, isTrue,
        reason: 'board cheio sem merges possíveis → isGameOver = true');
  },
);
