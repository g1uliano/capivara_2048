import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capivara_2048/data/models/tile.dart';
import 'package:capivara_2048/domain/performance/performance_settings.dart';
import 'package:capivara_2048/presentation/controllers/performance_settings_notifier.dart';
import 'package:capivara_2048/presentation/widgets/tile_widget.dart';

/// Test-only notifiers that return a fixed TileQuality without reading SharedPreferences.
class _FullQualityNotifier extends PerformanceSettingsNotifier {
  @override
  PerformanceSettings build() => const PerformanceSettings(tileQuality: TileQuality.full);
}

class _FullOpacityNotifier extends PerformanceSettingsNotifier {
  @override
  PerformanceSettings build() => const PerformanceSettings(tileQuality: TileQuality.fullOpacity);
}

class _SimpleQualityNotifier extends PerformanceSettingsNotifier {
  @override
  PerformanceSettings build() => const PerformanceSettings(tileQuality: TileQuality.simple);
}

Widget _buildTile(Tile? tile, PerformanceSettingsNotifier Function() notifierFactory) {
  return ProviderScope(
    overrides: [
      performanceSettingsProvider.overrideWith(notifierFactory),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: TileWidget(tile: tile, size: 80),
      ),
    ),
  );
}

void main() {
  group('TileWidget quality variants', () {
    final tile = Tile(id: 'a', level: 4, row: 0, col: 0);

    testWidgets('TileQuality.full mostra Image com Opacity 0.27', (tester) async {
      await tester.pumpWidget(_buildTile(tile, _FullQualityNotifier.new));
      await tester.pump();
      final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacity.opacity, closeTo(0.27, 0.01));
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('TileQuality.fullOpacity mostra Image sem Opacity wrapper', (tester) async {
      await tester.pumpWidget(_buildTile(tile, _FullOpacityNotifier.new));
      await tester.pump();
      expect(find.byType(Opacity), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('TileQuality.simple não mostra Image', (tester) async {
      await tester.pumpWidget(_buildTile(tile, _SimpleQualityNotifier.new));
      await tester.pump();
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('TileQuality.simple exibe nome do animal', (tester) async {
      await tester.pumpWidget(_buildTile(tile, _SimpleQualityNotifier.new));
      await tester.pump();
      // Nível 4 = Tucano
      expect(find.text('Tucano'), findsOneWidget);
    });

    testWidgets('tile null sempre renderiza célula vazia independente do quality', (tester) async {
      await tester.pumpWidget(_buildTile(null, _SimpleQualityNotifier.new));
      await tester.pump();
      expect(find.byType(Image), findsNothing);
    });
  });
}
