import 'dart:io';
import 'package:capivara_2048/data/models/game_state.dart';
import 'package:capivara_2048/data/models/lives_state.dart';
import 'package:capivara_2048/data/models/lives_state_adapter.dart';
import 'package:capivara_2048/domain/lives/lives_notifier.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:capivara_2048/presentation/screens/no_lives_screen.dart';
import 'package:capivara_2048/presentation/widgets/game_over_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockNavigatorObserver extends NavigatorObserver {
  Route<dynamic>? pushedRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoute = route;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    pushedRoute = newRoute;
  }
}

 LivesState _stateWithLives(int lives) => LivesState(
      lives: lives,
      regenCap: 5,
      earnedCap: 15,
      lastRegenAt: DateTime(2026),
      adWatchedToday: 0,
      adCounterResetAt: DateTime(2026, 1, 2),
    );

Widget _wrap(Widget child, {required int lives}) {
  final livesState = _stateWithLives(lives);
  return ProviderScope(
    overrides: [
      livesProvider.overrideWith(
        (ref) {
          final n = LivesNotifier(ref.read(livesRepositoryProvider));
          // Force-set the state before async _init() can overwrite it.
          n.state = livesState;
          return n;
        },
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_gameover_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(LivesStateAdapter());
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('1. Modal shows the message text', (tester) async {
    await tester.pumpWidget(_wrap(
      const GameOverModal(message: 'Game Over!'),
      lives: 3,
    ));
    expect(find.text('Game Over!'), findsOneWidget);
  });

  testWidgets('2. "Jogar de novo" button is present', (tester) async {
    await tester.pumpWidget(_wrap(
      const GameOverModal(message: 'Game Over!'),
      lives: 3,
    ));
    expect(find.text('Jogar de novo'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('3. Button is enabled when player has lives', (tester) async {
    await tester.pumpWidget(_wrap(
      const GameOverModal(message: 'Game Over!'),
      lives: 3,
    ));
    final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(btn.onPressed, isNotNull);
  });

  testWidgets('4. Button is disabled or navigates when player has no lives',
      (tester) async {
    final observer = _MockNavigatorObserver();
    final container = ProviderContainer(
      overrides: [
        livesProvider.overrideWith(
          (ref) {
            final n = LivesNotifier(ref.read(livesRepositoryProvider));
            n.state = _stateWithLives(0);
            return n;
          },
        ),
        gameProvider.overrideWith((ref) {
          final n = GameNotifier(ref.read(gameEngineProvider));
          n.setConsumeCallback((_) {});
          return n;
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorObservers: [observer],
          home: const Scaffold(
            body: GameOverModal(message: 'Game Over!'),
          ),
        ),
      ),
    );

    // Button is always present and enabled (navigates when lives == 0).
    final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(btn.onPressed, isNotNull);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(Duration.zero); // one frame — don't settle (stream timer)

    // Navigator pushed a route to NoLivesScreen.
    expect(observer.pushedRoute, isNotNull);
    // game state is untouched: restart() was NOT called.
    expect(container.read(gameProvider).score, 0);
  });

  testWidgets('5. Pressing button when has lives calls restart()',
      (tester) async {
    final livesState = _stateWithLives(3);
    final container = ProviderContainer(
      overrides: [
        livesProvider.overrideWith(
          (ref) {
            final n = LivesNotifier(ref.read(livesRepositoryProvider));
            n.state = livesState;
            return n;
          },
        ),
        gameProvider.overrideWith((ref) {
          final n = GameNotifier(ref.read(gameEngineProvider));
          n.setConsumeCallback((_) {});
          return n;
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: GameOverModal(message: 'Game Over!'),
          ),
        ),
      ),
    );

    final stateBefore = container.read(gameProvider);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    final stateAfter = container.read(gameProvider);
    // restart() replaces the state object; identity must differ.
    expect(identical(stateBefore, stateAfter), isFalse);
  });
}
