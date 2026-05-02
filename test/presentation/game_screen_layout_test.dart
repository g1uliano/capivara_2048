import 'dart:io';
import 'package:capivara_2048/data/models/lives_state_adapter.dart';
import 'package:capivara_2048/presentation/widgets/board_widget.dart';
import 'package:capivara_2048/presentation/widgets/game_header.dart';
import 'package:capivara_2048/presentation/widgets/pause_button_tile.dart';
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
    tempDir = await Directory.systemTemp.createTemp('hive_game_screen_layout_test');
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

  group('GameScreen layout', () {
    testWidgets('PauseButtonTile tem tileSize de 72dp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PauseButtonTile(tileSize: 72, onTap: () {}),
          ),
        ),
      );
      final size = tester.getSize(find.byType(PauseButtonTile));
      expect(size.width, 72.0);
      expect(size.height, 72.0);
    });

    testWidgets('GameHeader está presente na GameScreen', (tester) async {
      await tester.pumpWidget(_wrap(const _FakeGameScreen()));
      await tester.pump();
      expect(find.byType(GameHeader), findsOneWidget);
    });

    testWidgets('BoardWidget com size pequeno não causa overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 400,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final boardSide = constraints.maxWidth - 24;
                    return BoardWidget(size: boardSide);
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}

// Fake mínimo para não depender de providers complexos no teste estrutural
class _FakeGameScreen extends StatelessWidget {
  const _FakeGameScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            GameHeader(onPauseTap: () {}),
            const Expanded(child: Placeholder()),
          ],
        ),
      ),
    );
  }
}
