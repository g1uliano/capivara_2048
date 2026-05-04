import 'dart:io';
import 'package:capivara_2048/data/models/lives_state_adapter.dart';
import 'package:capivara_2048/presentation/widgets/game_header.dart';
import 'package:capivara_2048/presentation/widgets/host_banner.dart';
import 'package:capivara_2048/presentation/widgets/lives_indicator.dart';
import 'package:capivara_2048/presentation/widgets/pause_button_tile.dart';
import 'package:capivara_2048/presentation/widgets/status_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_game_header_test');
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

  group('GameHeader', () {
    testWidgets('renderiza LivesIndicator, HostBanner, StatusPanel e PauseButtonTile', (tester) async {
      await tester.pumpWidget(_wrap(GameHeader(onPauseTap: () {}, hostSize: 152, livesIconSize: 44, pauseSize: 72)));
      await tester.pump(); // pumpAndSettle times out — LivesIndicator has continuous animation
      expect(find.byType(LivesIndicator), findsOneWidget);
      expect(find.byType(HostBanner), findsOneWidget);
      expect(find.byType(StatusPanel), findsOneWidget);
      expect(find.byType(PauseButtonTile), findsOneWidget);
    });

    testWidgets('chama onPauseTap ao tocar no PauseButtonTile', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(GameHeader(onPauseTap: () => tapped = true, hostSize: 152, livesIconSize: 44, pauseSize: 72)));
      await tester.pump(); // pumpAndSettle times out — LivesIndicator has continuous animation
      await tester.tap(find.byType(PauseButtonTile));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('HostBanner está à esquerda do StatusPanel', (tester) async {
      await tester.pumpWidget(_wrap(GameHeader(onPauseTap: () {}, hostSize: 152, livesIconSize: 44, pauseSize: 72)));
      await tester.pump(); // pumpAndSettle times out — LivesIndicator has continuous animation
      final hostPos = tester.getTopLeft(find.byType(HostBanner));
      final statusPos = tester.getTopLeft(find.byType(StatusPanel));
      expect(hostPos.dx, lessThan(statusPos.dx));
    });

    testWidgets('LivesIndicator está horizontalmente centralizado', (tester) async {
      await tester.pumpWidget(_wrap(GameHeader(onPauseTap: () {}, hostSize: 152, livesIconSize: 44, pauseSize: 72)));
      await tester.pump();
      final headerBox = tester.getRect(find.byType(GameHeader));
      final indicatorBox = tester.getRect(find.byType(LivesIndicator));
      final headerCenter = headerBox.left + headerBox.width / 2;
      final indicatorCenter = indicatorBox.left + indicatorBox.width / 2;
      expect(indicatorCenter, closeTo(headerCenter, 2.0));
    });

    testWidgets('HostBanner está colado à esquerda do header', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_wrap(GameHeader(onPauseTap: () {}, hostSize: 152, livesIconSize: 44, pauseSize: 72)));
      await tester.pump();
      final headerBox = tester.getRect(find.byType(GameHeader));
      final hostBox = tester.getRect(find.byType(HostBanner));
      expect(hostBox.left, closeTo(headerBox.left, 2.0));
    });

    testWidgets('PauseButtonTile está à direita do HostBanner', (tester) async {
      await tester.pumpWidget(_wrap(GameHeader(onPauseTap: () {}, hostSize: 152, livesIconSize: 44, pauseSize: 72)));
      await tester.pump();
      final hostBox = tester.getRect(find.byType(HostBanner));
      final pauseBox = tester.getRect(find.byType(PauseButtonTile));
      expect(pauseBox.left, greaterThan(hostBox.right));
    });

    testWidgets('sem overflow em 360dp de largura', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(_wrap(GameHeader(onPauseTap: () {}, hostSize: 152, livesIconSize: 44, pauseSize: 72)));
      await tester.pump(); // pumpAndSettle times out — LivesIndicator has continuous animation
      expect(tester.takeException(), isNull);
    });
  });
}
