import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';

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
}
