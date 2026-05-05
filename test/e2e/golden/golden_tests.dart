// test/e2e/golden/golden_tests.dart
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/core/theme/app_theme.dart';
import 'package:capivara_2048/data/models/game_state.dart';
import 'package:capivara_2048/data/models/tile.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:capivara_2048/presentation/screens/home_screen.dart';
import 'package:capivara_2048/presentation/screens/game/game_screen.dart';
import 'package:capivara_2048/presentation/screens/collection_screen.dart';
import 'package:capivara_2048/presentation/screens/daily_rewards/daily_rewards_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../_harness/test_harness.dart';

// ---------------------------------------------------------------------------
// Viewports
// ---------------------------------------------------------------------------
const _viewports = <Size>[Size(360, 640), Size(414, 894), Size(800, 1280)];

// ---------------------------------------------------------------------------
// Wrapper helper
// ---------------------------------------------------------------------------

/// Envolve [child] no UncontrolledProviderScope do harness + MaterialApp com
/// o tema da app. Usado por todos os golden tests.
Widget _wrap(GameTestHarness harness, Widget child) {
  return UncontrolledProviderScope(
    container: harness.container,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: child,
    ),
  );
}

/// Tabuleiro mid-game com tiles nos níveis 1–4 em posições espalhadas.
GameState _midGameState() {
  final board = List.generate(4, (_) => List<Tile?>.filled(4, null));
  board[0][0] = const Tile(id: 'g1', level: 3, row: 0, col: 0);
  board[0][2] = const Tile(id: 'g2', level: 1, row: 0, col: 2);
  board[1][1] = const Tile(id: 'g3', level: 4, row: 1, col: 1);
  board[1][3] = const Tile(id: 'g4', level: 2, row: 1, col: 3);
  board[2][0] = const Tile(id: 'g5', level: 1, row: 2, col: 0);
  board[2][2] = const Tile(id: 'g6', level: 2, row: 2, col: 2);
  board[3][1] = const Tile(id: 'g7', level: 3, row: 3, col: 1);
  board[3][3] = const Tile(id: 'g8', level: 1, row: 3, col: 3);
  return GameState(
    board: board,
    score: 420,
    highScore: 840,
    isGameOver: false,
    hasWon: false,
    maxLevel: 4,
  );
}

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

/// Registra todos os golden tests. Chamado pelo main() de run_all_test.dart.
void runGoldenTests() {
  _homeScreenGoldenTests();
  _gameScreenGoldenTests();
  _pauseOverlayGoldenTests();
  _collectionScreenGoldenTests();
  _dailyRewardsScreenGoldenTests();
}

// ---------------------------------------------------------------------------
// HomeScreen (3 viewports)
// ---------------------------------------------------------------------------

void _homeScreenGoldenTests() {
  for (final size in _viewports) {
    final w = size.width.toInt();
    final h = size.height.toInt();

    group('golden — HomeScreen ${w}x$h', () {
      late GameTestHarness harness;

      setUp(() async {
        harness = GameTestHarness();
        await harness.boot();
      });

      tearDown(() async {
        await harness.teardown();
      });

      goldenTest(
        'home_${w}x$h',
        fileName: 'home_${w}x$h',
        constraints: BoxConstraints.tight(size),
        builder: () => _wrap(harness, const HomeScreen()),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// GameScreen (3 viewports) — board mid-game pré-configurado
// ---------------------------------------------------------------------------

void _gameScreenGoldenTests() {
  for (final size in _viewports) {
    final w = size.width.toInt();
    final h = size.height.toInt();

    group('golden — GameScreen ${w}x$h', () {
      late GameTestHarness harness;

      setUp(() async {
        harness = GameTestHarness();
        await harness.boot();
        // Configura tabuleiro mid-game para a snapshot ser não-trivial.
        harness.container
            .read(gameProvider.notifier)
            .debugSetState(_midGameState());
      });

      tearDown(() async {
        await harness.teardown();
      });

      goldenTest(
        'game_${w}x$h',
        fileName: 'game_${w}x$h',
        constraints: BoxConstraints.tight(size),
        builder: () => _wrap(harness, const GameScreen()),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// PauseOverlay (3 viewports) — GameScreen + pause ativo
// ---------------------------------------------------------------------------

void _pauseOverlayGoldenTests() {
  for (final size in _viewports) {
    final w = size.width.toInt();
    final h = size.height.toInt();

    group('golden — PauseOverlay ${w}x$h', () {
      late GameTestHarness harness;

      setUp(() async {
        harness = GameTestHarness();
        await harness.boot();
        harness.container
            .read(gameProvider.notifier)
            .debugSetState(_midGameState());
      });

      tearDown(() async {
        await harness.teardown();
      });

      goldenTest(
        'pause_${w}x$h',
        fileName: 'pause_${w}x$h',
        constraints: BoxConstraints.tight(size),
        pumpBeforeTest: (tester) async {
          // Toca no botão de pause (identificado pelo Semantics label).
          final pauseFinder = find.bySemanticsLabel('Botão Pausar');
          expect(
            pauseFinder,
            findsOneWidget,
            reason: 'PauseButtonTile deve estar presente na GameScreen',
          );
          await tester.tap(pauseFinder);
          await tester.pumpAndSettle();
        },
        builder: () => _wrap(harness, const GameScreen()),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// CollectionScreen (3 viewports)
// ---------------------------------------------------------------------------

void _collectionScreenGoldenTests() {
  for (final size in _viewports) {
    final w = size.width.toInt();
    final h = size.height.toInt();

    group('golden — CollectionScreen ${w}x$h', () {
      late GameTestHarness harness;

      setUp(() async {
        harness = GameTestHarness();
        await harness.boot();
      });

      tearDown(() async {
        await harness.teardown();
      });

      goldenTest(
        'collection_${w}x$h',
        fileName: 'collection_${w}x$h',
        constraints: BoxConstraints.tight(size),
        builder: () => _wrap(harness, const CollectionScreen()),
      );
    });
  }
}

// ---------------------------------------------------------------------------
// DailyRewardsScreen (3 viewports)
// ---------------------------------------------------------------------------

void _dailyRewardsScreenGoldenTests() {
  for (final size in _viewports) {
    final w = size.width.toInt();
    final h = size.height.toInt();

    group('golden — DailyRewardsScreen ${w}x$h', () {
      late GameTestHarness harness;

      setUp(() async {
        harness = GameTestHarness();
        await harness.boot();
      });

      tearDown(() async {
        await harness.teardown();
      });

      goldenTest(
        'daily_${w}x$h',
        fileName: 'daily_${w}x$h',
        constraints: BoxConstraints.tight(size),
        builder: () => _wrap(harness, const DailyRewardsScreen()),
      );
    });
  }
}
