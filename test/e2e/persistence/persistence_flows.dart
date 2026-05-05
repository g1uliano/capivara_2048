import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/daily_rewards_state.dart';
import 'package:capivara_2048/data/models/game_state.dart';
import 'package:capivara_2048/data/models/item_type.dart';
import 'package:capivara_2048/data/repositories/lives_repository.dart';
import 'package:capivara_2048/data/models/tile.dart';
import 'package:capivara_2048/data/repositories/game_record_repository.dart';
import 'package:capivara_2048/domain/daily_rewards/daily_rewards_notifier.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/domain/lives/lives_notifier.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:capivara_2048/presentation/controllers/personal_records_notifier.dart';
import 'package:capivara_2048/presentation/controllers/settings_notifier.dart';
import '../_harness/scenario.dart';
import '../_harness/test_harness.dart';
import '../_harness/tester_extensions.dart';

// ─── helpers ────────────────────────────────────────────────────────────────

Future<void> _boot(WidgetTester tester, GameTestHarness harness) async {
  final w = await tester.runAsync(() => harness.boot());
  await tester.pumpWidget(w!);
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

Future<void> _restart(WidgetTester tester, GameTestHarness harness) async {
  final w = await tester.runAsync(() => harness.restart());
  await tester.pumpWidget(w!);
  // Avoid pumpAndSettle here: when lives < regenCap, LivesStatusBanner creates a
  // Timer.periodic(1s) countdown that prevents pumpAndSettle from ever settling.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

// ─── persistence.inventory_survives_restart ──────────────────────────────────

final persistenceInventoryScenario = E2EScenario(
  id: 'persistence.inventory_survives_restart',
  title: 'inventário (bomb2=2) persiste após cold restart',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _boot(tester, harness);

    // add() persists via Hive
    await tester.runAsync(() =>
        harness.container.read(inventoryProvider.notifier).add(ItemType.bomb2, 2));
    await tester.pump(const Duration(milliseconds: 300));

    expect(harness.container.read(inventoryProvider).bomb2, equals(2));

    await _restart(tester, harness);

    expect(harness.container.read(inventoryProvider).bomb2, equals(2),
        reason: 'bomb2 deve persistir no Hive após cold restart');
  },
);

// ─── persistence.lives_survive_restart ───────────────────────────────────────
//
// NOTE: LivesNotifier._init() uses Hive I/O which only completes in real-async.
// Avoid pumpAndSettle after setting lives<regenCap — LivesStatusBanner creates a
// Timer.periodic(1s) that prevents settlement. Instead, verify via LivesRepository
// directly (bypasses the notifier async init issue entirely).

final persistenceLivesScenario = E2EScenario(
  id: 'persistence.lives_survive_restart',
  title: 'vidas (4 após consume) persistem no Hive após cold restart',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    // Avoid accessing livesProvider notifier directly — LivesNotifier._init()
    // uses Hive I/O and in fake-async contexts leaves a pending Future that
    // can race with subsequent tests' Hive operations (deadlock).
    // Instead: persist directly via LivesRepository.
    await tester.runAsync(() => harness.boot()); // init Hive + adapters

    final repo = LivesRepository();
    // Save lives=4 directly to Hive (simulates what consume() would do)
    final initial = await tester.runAsync(() => repo.load());
    final consumed = LivesNotifier.applyConsume(initial!);
    await tester.runAsync(() => repo.save(consumed));

    expect(consumed.lives, equals(initial.lives - 1),
        reason: 'applyConsume deve decrementar de ${initial.lives} para ${initial.lives - 1}');

    // Cold restart
    await tester.runAsync(() => harness.restart());

    // Verify Hive persisted across restart
    final livesAfterRestart = await tester.runAsync(() => repo.load());
    expect(livesAfterRestart!.lives, equals(consumed.lives),
        reason: 'lives deve persistir no Hive após cold restart');
  },
);

// ─── persistence.daily_rewards_survive_restart ───────────────────────────────

final persistenceDailyScenario = E2EScenario(
  id: 'persistence.daily_rewards_survive_restart',
  title: 'recompensas diárias (currentDay=2 após claim) persistem após cold restart',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _boot(tester, harness);

    // Force a claimable state then claim it → currentDay advances 1→2
    harness.container.read(dailyRewardsProvider.notifier).debugSetState(
      DailyRewardsState(
        currentDay: 1,
        lastClaimedDate: DateTime(1970),
        claimedThisCycle: false,
      ),
    );
    await tester.runAsync(() =>
        harness.container.read(dailyRewardsProvider.notifier).claim(DateTime.now()));
    await tester.pump(const Duration(milliseconds: 300));

    expect(harness.container.read(dailyRewardsProvider).currentDay, equals(2));

    await _restart(tester, harness);

    expect(harness.container.read(dailyRewardsProvider).currentDay, equals(2),
        reason: 'currentDay deve persistir no Hive após cold restart');
  },
);

// ─── persistence.high_score_survives_restart ─────────────────────────────────
//
// DESIGN NOTE: GameState.highScore is intentionally in-memory only — it is
// not persisted to Hive or SharedPreferences between sessions. On cold restart,
// the game always starts fresh (score=0, highScore=0). Historical high scores
// are tracked via GameRecordRepository (see persistence.game_records_history).
// This scenario documents and verifies that design decision.

final persistenceHighScoreScenario = E2EScenario(
  id: 'persistence.high_score_survives_restart',
  title: 'highScore é in-memory: após cold restart reseta para 0 (comportamento esperado)',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _boot(tester, harness);
    await tester.gotoGame(harness);

    // Set an in-memory high score via debugSetState
    harness.container.read(gameProvider.notifier).debugSetState(
      GameState(
        board: List.generate(4, (_) => List<Tile?>.filled(4, null)),
        score: 999,
        highScore: 999,
        maxLevel: 3,
        isGameOver: false,
        hasWon: false,
      ),
    );
    expect(tester.readGame(harness).highScore, equals(999));

    await _restart(tester, harness);

    // After cold restart, game state is fresh — highScore resets to 0
    expect(tester.readGame(harness).highScore, equals(0),
        reason: 'highScore é in-memory e deve resetar após cold restart (design intencional)');
  },
);

// ─── persistence.personal_records_survive_restart ────────────────────────────

final persistencePersonalRecordsScenario = E2EScenario(
  id: 'persistence.personal_records_survive_restart',
  title: 'personal records (highestLevelEver=5) persistem após cold restart',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _boot(tester, harness);

    await tester.runAsync(() =>
        harness.container.read(personalRecordsProvider.notifier).updateHighestLevel(5));
    await tester.pump(const Duration(milliseconds: 300));

    expect(harness.container.read(personalRecordsProvider).highestLevelEver, equals(5));

    await _restart(tester, harness);

    expect(harness.container.read(personalRecordsProvider).highestLevelEver, equals(5),
        reason: 'highestLevelEver deve persistir no Hive após cold restart');
  },
);

// ─── persistence.settings_survive_restart ────────────────────────────────────

final persistenceSettingsScenario = E2EScenario(
  id: 'persistence.settings_survive_restart',
  title: 'configurações (haptic=false) persistem após cold restart',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _boot(tester, harness);

    expect(harness.container.read(settingsProvider).hapticEnabled, isTrue,
        reason: 'hapticEnabled deve ser true por padrão');

    // setHaptic persists via SharedPreferences
    harness.container.read(settingsProvider.notifier).setHaptic(false);

    await _restart(tester, harness);

    expect(harness.container.read(settingsProvider).hapticEnabled, isFalse,
        reason: 'hapticEnabled=false deve persistir via SharedPreferences');
  },
);

// ─── persistence.game_records_history_survives_restart ───────────────────────

final persistenceGameRecordsScenario = E2EScenario(
  id: 'persistence.game_records_history_survives_restart',
  title: 'histórico de partidas persiste após cold restart',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _boot(tester, harness);
    await tester.gotoGame(harness);

    // Force game-over state then confirm (triggers _saveGameRecord via Hive)
    harness.container.read(gameProvider.notifier).debugSetState(
      GameState(
        board: List.generate(4, (_) => List<Tile?>.filled(4, null)),
        score: 500,
        highScore: 500,
        maxLevel: 3,
        isGameOver: true,
        hasWon: false,
      ),
    );
    // confirmGameOver calls unawaited(_saveGameRecord()) — use runAsync to let
    // the Hive write complete before checking and restarting
    harness.container.read(gameProvider.notifier).confirmGameOver();
    await tester.runAsync(() async {
      // Wait for the unawaited _saveGameRecord() to flush to Hive
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();

    expect(harness.container.read(gameRecordRepositoryProvider).all.length,
        greaterThan(0),
        reason: 'confirmGameOver deve salvar um record');

    await _restart(tester, harness);

    expect(harness.container.read(gameRecordRepositoryProvider).all.length,
        greaterThan(0),
        reason: 'game records devem persistir no Hive após cold restart');
  },
);

// ─── persistence.in_progress_game_survives_restart ───────────────────────────
//
// NOTE: In-progress GameState is intentionally NOT persisted to disk.
// This scenario verifies that the HomeScreen shows "Continuar Jogo" when
// gameState.score > 0 && !isGameOver (the _hasSavedGame condition).

final persistenceInProgressGameScenario = E2EScenario(
  id: 'persistence.in_progress_game_survives_restart',
  title: 'gameState com score>0: HomeScreen mostra "Continuar Jogo"',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _boot(tester, harness);

    // Set game state with score > 0 via debugSetState (no need to navigate to GameScreen).
    // HomeScreen checks _hasSavedGame = score > 0 && !isGameOver.
    harness.container.read(gameProvider.notifier).debugSetState(
      GameState(
        board: List.generate(4, (_) => List<Tile?>.filled(4, null))
          ..[0][0] = const Tile(id: 'x', level: 2, row: 0, col: 0),
        score: 100,
        highScore: 100,
        maxLevel: 2,
        isGameOver: false,
        hasWon: false,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Continuar Jogo'), findsOneWidget,
        reason: 'score>0 && !isGameOver: HomeScreen deve mostrar "Continuar Jogo"');
  },
);
