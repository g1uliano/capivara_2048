import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:capivara_2048/domain/game_engine/direction.dart';
import 'package:capivara_2048/data/models/tile.dart';
import 'package:capivara_2048/data/models/game_state.dart';

void main() {
  group('GameNotifier timer', () {
    test('elapsedMs starts at 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(gameProvider);
      expect(state.elapsedMs, 0);
    });

    test('isPaused starts false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(gameProvider);
      expect(state.isPaused, false);
    });

    test('pause sets isPaused to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).pause();
      expect(container.read(gameProvider).isPaused, true);
    });

    test('resume sets isPaused to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).pause();
      container.read(gameProvider.notifier).resume();
      expect(container.read(gameProvider).isPaused, false);
    });

    test('restart resets elapsedMs and isPaused', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).pause();
      container.read(gameProvider.notifier).restart();
      final state = container.read(gameProvider);
      expect(state.elapsedMs, 0);
      expect(state.isPaused, false);
    });

    test('restart resets maxLevel to 1', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Simular maxLevel alto (após alguns moves hipotéticos)
      // restart() deve sempre voltar para 1
      container.read(gameProvider.notifier).restart();
      final state = container.read(gameProvider);
      expect(state.maxLevel, 1);
    });
  });

  group('GameNotifier.undo', () {
    test('undo does nothing when undoStack is empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      final before = container.read(gameProvider);
      notifier.undo(1);
      final after = container.read(gameProvider);
      expect(after.board, before.board);
    });

    test('undo(1) restores previous state after a move', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);

      // Set up a board with two adjacent same-value tiles in row 0 that will
      // definitely merge on a left swipe, guaranteeing a valid move.
      final board = List.generate(4, (r) => List<Tile?>.filled(4, null));
      board[0][2] = const Tile(id: 'a', level: 1, row: 0, col: 2);
      board[0][3] = const Tile(id: 'b', level: 1, row: 0, col: 3);
      notifier.state = GameState(
        board: board,
        score: 0,
        highScore: 0,
        isGameOver: false,
        hasWon: false,
      );

      final before = container.read(gameProvider);
      notifier.onSwipe(Direction.left);
      final afterSwipe = container.read(gameProvider);

      // The move must have been valid — fail loudly if the stack is empty.
      expect(afterSwipe.undoStack, isNotEmpty);

      notifier.undo(1);
      final restored = container.read(gameProvider);
      expect(restored.board, before.board);
    });

    test('undo(3) does not throw on a small stack', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(gameProvider.notifier);
      for (final dir in [Direction.left, Direction.right, Direction.left]) {
        notifier.onSwipe(dir);
      }
      expect(() => notifier.undo(3), returnsNormally);
    });
  });
}
