import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:capivara_2048/app.dart';
import 'package:capivara_2048/data/models/lives_state.dart';
import 'package:capivara_2048/data/models/lives_state_adapter.dart';

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => '/tmp/test_hive';
}

void main() {
  setUpAll(() async {
    PathProviderPlatform.instance = _FakePathProvider();
    await Hive.initFlutter('/tmp/test_hive');
    if (!Hive.isAdapterRegistered(LivesStateAdapter().typeId)) {
      Hive.registerAdapter(LivesStateAdapter());
    }
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Suppress GoogleFonts network errors in test environment.
    GoogleFonts.config.allowRuntimeFetching = false;

    await tester.pumpWidget(const ProviderScope(child: CapivaraApp()));
    expect(find.byType(CapivaraApp), findsOneWidget);
  }, skip: true);
}
