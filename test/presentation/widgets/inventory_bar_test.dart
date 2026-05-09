import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/game_state.dart';
import 'package:capivara_2048/data/models/tile.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:capivara_2048/presentation/widgets/inventory_bar.dart';

List<List<Tile?>> _board(int tileCount) {
  final board = List.generate(4, (_) => List<Tile?>.filled(4, null));
  var placed = 0;
  for (var r = 0; r < 4 && placed < tileCount; r++) {
    for (var c = 0; c < 4 && placed < tileCount; c++) {
      board[r][c] = Tile(id: 'tile_$placed', level: 1, row: r, col: c);
      placed++;
    }
  }
  return board;
}

GameState _gameState(int tileCount) => GameState(
      board: _board(tileCount),
      score: 0,
      highScore: 0,
      isGameOver: false,
      hasWon: false,
    );

class _FakeGameNotifier extends GameNotifier {
  final GameState _initial;
  _FakeGameNotifier(this._initial);

  @override
  GameState build() => _initial;
}

void main() {
  group('InventoryBar — Bomba 3 piece count guard', () {
    testWidgets('renders bomb3 button', (tester) async {
      final gs = _gameState(5);
      final container = ProviderContainer(overrides: [
        gameProvider.overrideWith(() => _FakeGameNotifier(gs)),
      ]);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: InventoryBar())),
        ),
      );
      expect(find.byKey(const Key('inventory_bomb3')), findsOneWidget);
    });
  });
}
