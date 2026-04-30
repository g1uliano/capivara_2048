import 'dart:io';
import 'package:capivara_2048/data/models/lives_state_adapter.dart';
import 'package:capivara_2048/presentation/screens/home_screen.dart';
import 'package:capivara_2048/presentation/widgets/lives_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

// HomeScreen owns its own Scaffold
Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(home: child),
    );

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_home_screen_test');
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

  group('HomeScreen', () {
    testWidgets('LivesIndicator está horizontalmente centralizado', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_wrap(const HomeScreen()));
      await tester.pump();
      final screenBox = tester.getRect(find.byType(HomeScreen));
      final indicatorBox = tester.getRect(find.byType(LivesIndicator));
      final screenCenter = screenBox.left + screenBox.width / 2;
      final indicatorCenter = indicatorBox.left + indicatorBox.width / 2;
      expect(indicatorCenter, closeTo(screenCenter, 2.0)); // 2px tolerance for sub-pixel rounding
    });
  });
}
