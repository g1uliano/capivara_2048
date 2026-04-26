import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:capivara_2048/domain/game_engine/direction.dart';

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
      final before = container.read(gameProvider);
      notifier.onSwipe(Direction.left);
      final afterSwipe = container.read(gameProvider);
      if (afterSwipe.undoStack.isNotEmpty) {
        notifier.undo(1);
        final restored = container.read(gameProvider);
        expect(restored.board, before.board);
      }
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
