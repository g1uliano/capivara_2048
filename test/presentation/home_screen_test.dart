import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capivara_2048/data/models/daily_rewards_state.dart';
import 'package:capivara_2048/data/models/daily_rewards_state_adapter.dart';
import 'package:capivara_2048/data/models/game_state.dart';
import 'package:capivara_2048/data/models/inventory_hive_adapter.dart';
import 'package:capivara_2048/data/models/lives_state_adapter.dart';
import 'package:capivara_2048/data/repositories/game_record_repository.dart';
import 'package:capivara_2048/domain/daily_rewards/daily_rewards_notifier.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:capivara_2048/presentation/controllers/settings_notifier.dart';
import 'package:capivara_2048/presentation/screens/home_screen.dart';
import 'package:capivara_2048/presentation/widgets/lives_indicator.dart';

Future<ProviderScope> _wrap({
  GameState? gameState,
  bool rewardAvailable = false,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final settingsNotifier = SettingsNotifier(prefs);

  final rewardState = rewardAvailable
      ? DailyRewardsState(
          currentDay: 1,
          lastClaimedDate: DateTime.now().subtract(const Duration(days: 2)),
          claimedThisCycle: false,
        )
      : DailyRewardsState(
          currentDay: 1,
          lastClaimedDate: DateTime.now(),
          claimedThisCycle: true,
        );

  final overrides = <Override>[
    settingsProvider.overrideWith((ref) => settingsNotifier),
    gameRecordRepositoryProvider.overrideWithValue(GameRecordRepository()),
    dailyRewardsProvider.overrideWith(
      (ref) => DailyRewardsNotifier(
        ref.read(dailyRewardsRepositoryProvider),
        ref,
      )..debugSetState(rewardState),
    ),
    if (gameState != null)
      gameProvider.overrideWith(
        (ref) => GameNotifier(ref.read(gameEngineProvider), ref)
          ..debugSetState(gameState),
      ),
  ];

  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(home: HomeScreen()),
  );
}

GameState _savedGameState() => GameState(
      board: List.generate(4, (_) => List.filled(4, null)),
      score: 100,
      highScore: 0,
      isGameOver: false,
      hasWon: false,
    );

late Directory _tempDir;

void main() {
  setUpAll(() async {
    _tempDir = await Directory.systemTemp.createTemp('hive_home_v2');
    Hive.init(_tempDir.path);
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(LivesStateAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(InventoryHiveAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(DailyRewardsStateAdapter());
  });
  tearDownAll(() async {
    await Hive.close();
    await _tempDir.delete(recursive: true);
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('HomeScreen não contém LivesIndicator', (tester) async {
    await tester.pumpWidget(await _wrap());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LivesIndicator), findsNothing);
  });

  testWidgets('GameTitleImage presente (Image com path title_)', (tester) async {
    await tester.pumpWidget(await _wrap());
    await tester.pump(const Duration(milliseconds: 500));
    final images = tester.widgetList<Image>(find.byType(Image));
    final hasTitle = images.any((img) {
      final provider = img.image;
      return provider is AssetImage &&
          (provider.assetName.contains('title_orange') ||
              provider.assetName.contains('title_brown'));
    });
    expect(hasTitle, isTrue);
  });

  testWidgets('6 botões ilustrados de home presentes por Key', (tester) async {
    await tester.pumpWidget(await _wrap());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('home_btn_colecao')), findsOneWidget);
    expect(find.byKey(const Key('home_btn_configuracao')), findsOneWidget);
    expect(find.byKey(const Key('home_btn_recompensas')), findsOneWidget);
    expect(find.byKey(const Key('home_btn_ranking')), findsOneWidget);
    expect(find.byKey(const Key('home_btn_loja')), findsOneWidget);
    expect(find.byKey(const Key('home_btn_comojogar')), findsOneWidget);
  });

  testWidgets('"Novo jogo" sempre visível', (tester) async {
    await tester.pumpWidget(await _wrap());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Novo jogo'), findsOneWidget);
  });

  testWidgets('"Continuar Jogo" visível quando há partida salva', (tester) async {
    await tester.pumpWidget(await _wrap(gameState: _savedGameState()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Continuar Jogo'), findsOneWidget);
  });

  testWidgets('"Continuar Jogo" ausente no estado inicial', (tester) async {
    await tester.pumpWidget(await _wrap());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Continuar Jogo'), findsNothing);
  });

  testWidgets('badge "!" visível quando dailyRewardAvailable == true', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(await _wrap(rewardAvailable: true));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('!'), findsOneWidget);
  });

  testWidgets('badge "!" ausente quando dailyRewardAvailable == false', (tester) async {
    await tester.pumpWidget(await _wrap(rewardAvailable: false));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('!'), findsNothing);
  });

  testWidgets('tap em Coleção navega para CollectionScreen', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(await _wrap());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('home_btn_colecao')));
    await tester.pumpAndSettle();
    expect(find.textContaining('animais descobertos'), findsOneWidget);
  });

  testWidgets('tap em Ranking navega para RankingScreen', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(await _wrap());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('home_btn_ranking')));
    await tester.pumpAndSettle();
    expect(find.text('Pessoal'), findsOneWidget);
  });

  testWidgets('tap em Loja navega para ShopScreen', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(await _wrap());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('home_btn_loja')));
    await tester.pumpAndSettle();
    expect(find.text('Loja'), findsWidgets);
  });

  testWidgets('tap em Configurações navega para SettingsScreen', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(await _wrap());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('home_btn_configuracao')));
    await tester.pumpAndSettle();
    expect(find.text('Configurações'), findsWidgets);
  });

  testWidgets('tap em Recompensas navega para DailyRewardsScreen', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(await _wrap());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('home_btn_recompensas')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Recompensa'), findsWidgets);
  });

  testWidgets('tap em ComoJogar abre BottomSheet', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(await _wrap());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('home_btn_comojogar')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Deslize'), findsOneWidget);
  });
}
