import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/game_state.dart';
import 'package:capivara_2048/data/models/tile.dart';

List<List<Tile?>> _board(int markerLevel) {
  final b = List.generate(4, (_) => List<Tile?>.filled(4, null));
  b[0][0] = Tile(id: 'm$markerLevel', level: markerLevel, row: 0, col: 0);
  return b;
}

GameState _snapshot(int score) => GameState(
      board: _board(score == 0 ? 1 : score),
      score: score,
      highScore: 100,
      isGameOver: false,
      hasWon: false,
    );

void main() {
  group('GameState undoStack persistence', () {
    test('round-trip preserva o histórico (mais recente primeiro)', () {
      final state = GameState(
        board: _board(9),
        score: 50,
        highScore: 100,
        isGameOver: false,
        hasWon: false,
        undoStack: [_snapshot(3), _snapshot(2), _snapshot(1)],
      );
      final restored = GameState.fromJson(state.toJson());
      expect(restored.undoStack.length, 3);
      expect(restored.undoStack[0].score, 3);
      expect(restored.undoStack[2].score, 1);
    });

    test('limita o histórico persistido às 20 jogadas mais recentes', () {
      // move() insere o mais recente no topo (índice 0).
      final stack = List.generate(50, (i) => _snapshot(i));
      final state = GameState(
        board: _board(9),
        score: 999,
        highScore: 100,
        isGameOver: false,
        hasWon: false,
        undoStack: stack,
      );
      final restored = GameState.fromJson(state.toJson());
      expect(restored.undoStack.length, 20);
      expect(restored.undoStack.first.score, 0); // mais recente preservado
      expect(restored.undoStack.last.score, 19);
    });

    test('estado sem histórico round-trip resulta em stack vazio', () {
      final restored = GameState.fromJson(_snapshot(10).toJson());
      expect(restored.undoStack, isEmpty);
    });

    test('json antigo sem campo undoStack restaura stack vazio (compat)', () {
      final json = _snapshot(10).toJson();
      json.remove('undoStack');
      final restored = GameState.fromJson(json);
      expect(restored.undoStack, isEmpty);
    });

    test('entradas do histórico restauram com isPaused=false', () {
      final state = GameState(
        board: _board(9),
        score: 50,
        highScore: 100,
        isGameOver: false,
        hasWon: false,
        undoStack: [_snapshot(1)],
      );
      final restored = GameState.fromJson(state.toJson());
      expect(restored.undoStack.first.isPaused, false);
    });
  });
}
