import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:capivara_2048/data/models/game_state.dart';

void main() {
  test('isAwaitingGameOverResolution defaults to false', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(gameProvider).isAwaitingGameOverResolution, false);
  });

  test('setAwaitingResolution emits new state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    notifier.setAwaitingResolution(true);
    expect(container.read(gameProvider).isAwaitingGameOverResolution, true);
    notifier.setAwaitingResolution(false);
    expect(container.read(gameProvider).isAwaitingGameOverResolution, false);
  });

  test('GameState default isAwaitingGameOverResolution is false', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final state = container.read(gameProvider);
    expect(state.isAwaitingGameOverResolution, false);
  });
}
