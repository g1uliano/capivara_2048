import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/game_state.dart';
import 'package:capivara_2048/domain/game_engine/game_engine.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:capivara_2048/presentation/controllers/personal_records_notifier.dart';
import 'test_harness.dart';

void main() {
  // Note: these are plain test() not testWidgets() because boot()/teardown()
  // involve real file I/O (Hive) that can't complete inside testWidgets' fake-async
  // zone. The full pumpWidget contract is exercised by the smoke scenarios (Task 6+).

  test('boot() returns a Widget and exposes initialized container', () async {
    final h = GameTestHarness();
    addTearDown(h.teardown);

    final widget = await h.boot();

    expect(widget, isA<Widget>());
    expect(h.container, isA<ProviderContainer>());
    expect(h.container.read(gameProvider), isA<GameState>());
  });

  test('boot() accepts initialGameState override', () async {
    final initial = GameEngine().newGame().copyWith(score: 999);
    final h = GameTestHarness();
    addTearDown(h.teardown);

    await h.boot(initialGameState: initial);

    expect(h.container.read(gameProvider).score, 999);
  });

  test('restart() re-boots with same Hive — state persists across restart', () async {
    final h = GameTestHarness();
    addTearDown(h.teardown);

    // First boot — write something to Hive via personalRecords provider.
    await h.boot();
    await h.container
        .read(personalRecordsProvider.notifier)
        .updateHighestLevel(7);
    expect(
      h.container.read(personalRecordsProvider).highestLevelEver,
      7,
      reason: 'pre-condition: level written to Hive',
    );

    // Cold restart — disposes old container, re-opens Hive boxes.
    await h.restart();

    expect(
      h.container.read(personalRecordsProvider).highestLevelEver,
      7,
      reason: 'restart() must reload Hive — same data, new container',
    );
  });

  test('teardown() cleans up Hive and tempDir without throwing', () async {
    final h = GameTestHarness();
    await h.boot();
    await h.teardown();
    expect(h.tempDir.existsSync(), isFalse);
  });
}
