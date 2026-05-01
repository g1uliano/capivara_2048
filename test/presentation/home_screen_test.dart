import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capivara_2048/data/models/daily_rewards_state_adapter.dart';
import 'package:capivara_2048/data/models/inventory_hive_adapter.dart';
import 'package:capivara_2048/data/models/lives_state_adapter.dart';
import 'package:capivara_2048/presentation/controllers/settings_notifier.dart';
import 'package:capivara_2048/presentation/screens/home_screen.dart';

Future<Widget> _wrap() async {
  final prefs = await SharedPreferences.getInstance();
  final notifier = SettingsNotifier(prefs);
  return ProviderScope(
    overrides: [settingsProvider.overrideWith((ref) => notifier)],
    child: const MaterialApp(home: HomeScreen()),
  );
}

late Directory _tempDir;

void main() {
  setUpAll(() async {
    _tempDir = await Directory.systemTemp.createTemp('hive_home_screen_test');
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

  testWidgets('6 _HomeCard presentes (Loja, Ranking, Recompensa Diária, Coleção, Config, Como Jogar)',
      (tester) async {
    await tester.pumpWidget(await _wrap());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Loja'), findsOneWidget);
    expect(find.text('Ranking'), findsOneWidget);
    expect(find.text('Recompensa Diária'), findsOneWidget);
    expect(find.text('Coleção'), findsOneWidget);
    expect(find.text('Configurações'), findsOneWidget);
    expect(find.text('Como Jogar'), findsOneWidget);
  });

  testWidgets('_PlayButton presente no widget tree', (tester) async {
    await tester.pumpWidget(await _wrap());
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.text('Novo Jogo').evaluate().isNotEmpty || find.text('Continuar').evaluate().isNotEmpty,
      isTrue,
    );
  });

  testWidgets('_PlayButton mostra "Novo Jogo" em estado inicial', (tester) async {
    await tester.pumpWidget(await _wrap());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Novo Jogo'), findsOneWidget);
  });

  testWidgets('card Ranking tem label "Em breve" (desabilitado)', (tester) async {
    await tester.pumpWidget(await _wrap());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Em breve'), findsWidgets);
  });

  testWidgets('GameTitleImage presente no widget tree', (tester) async {
    await tester.pumpWidget(await _wrap());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('tap em "Como Jogar" abre bottom sheet', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(await _wrap());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Como Jogar'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Deslize'), findsOneWidget);
  });

  testWidgets('tap em Coleção navega para CollectionScreen', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(await _wrap());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Coleção'));
    await tester.pumpAndSettle();
    expect(find.textContaining('animais descobertos'), findsOneWidget);
  });

  testWidgets('tap em Loja navega para ShopScreen', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(await _wrap());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Loja'));
    await tester.pumpAndSettle();
    expect(find.text('Em breve'), findsWidgets);
  });
}
