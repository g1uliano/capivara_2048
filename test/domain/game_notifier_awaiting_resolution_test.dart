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

  test('cancelBomb while isContinuingWithItem returns to awaiting overlay', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    // Simulate: overlay shown → player tapped "Usar item"
    notifier.startContinueWithItem();
    // Player opened a bomb but then cancelled
    notifier.cancelBomb();
    final s = container.read(gameProvider);
    // Must return to the overlay (not go straight to GameOverModal)
    expect(s.isContinuingWithItem, false);
    expect(s.isAwaitingGameOverResolution, true);
    expect(s.bombMode, null);
  });

  test('startContinueWithItem sets isContinuingWithItem true and isAwaitingGameOverResolution false', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(gameProvider.notifier);
    notifier.setAwaitingResolution(true);
    notifier.startContinueWithItem();
    final s = container.read(gameProvider);
    expect(s.isContinuingWithItem, true);
    expect(s.isAwaitingGameOverResolution, false);
  });
}
