import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:capivara_2048/data/models/game_state.dart';
import 'package:capivara_2048/domain/game_engine/bomb_mode.dart';
import 'package:capivara_2048/domain/game_engine/game_engine.dart';
import 'package:capivara_2048/data/models/item_type.dart';

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
    notifier.startContinueWithItem();
    notifier.cancelBomb();
    final s = container.read(gameProvider);
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

  test('confirmBomb after startContinueWithItem clears isContinuingWithItem and isGameOver', () {
    // Use GameNotifier directly (no Hive) — no consume callback wired.
    final container2 = ProviderContainer(
      overrides: [
        gameProvider.overrideWith((ref) {
          final n = GameNotifier(ref.read(gameEngineProvider), ref);
          n.setConsumeCallback((_) {});
          return n;
        }),
      ],
    );
    addTearDown(container2.dispose);
    final notifier = container2.read(gameProvider.notifier);
    notifier.setAwaitingResolution(true);
    notifier.startContinueWithItem();
    notifier.enterBombMode(BombMode.bomb3, ItemType.bomb3);
    notifier.selectBombTile(0, 0);
    notifier.selectBombTile(0, 1);
    notifier.selectBombTile(0, 2); // 3rd tile auto-confirms
    final s = notifier.state;
    expect(s.isContinuingWithItem, false);
    expect(s.bombMode, null);
    expect(s.isGameOver, false); // tiles removed → board has empty spaces → not game over
  });
}
