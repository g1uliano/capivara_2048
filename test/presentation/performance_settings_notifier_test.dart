import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capivara_2048/domain/performance/performance_settings.dart';
import 'package:capivara_2048/presentation/controllers/performance_settings_notifier.dart';
import 'package:capivara_2048/presentation/controllers/settings_notifier.dart';

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('PerformanceSettingsNotifier', () {
    test('estado inicial: disabled, full quality, blur on, animations on', () async {
      final c = await _container();
      await c.read(performanceSettingsProvider.notifier).load();
      final s = c.read(performanceSettingsProvider);
      expect(s.enabled, false);
      expect(s.tileQuality, TileQuality.full);
      expect(s.blurEffectsEnabled, true);
      expect(s.animationsEnabled, true);
    });

    test('enable() ativa modo e persiste', () async {
      final c = await _container();
      await c.read(performanceSettingsProvider.notifier).load();
      await c.read(performanceSettingsProvider.notifier).enable();
      expect(c.read(performanceSettingsProvider).enabled, true);
      expect(c.read(performanceSettingsProvider).hasShownSuggestionDialog, true);
    });

    test('disable() desativa modo e persiste', () async {
      final c = await _container();
      await c.read(performanceSettingsProvider.notifier).load();
      await c.read(performanceSettingsProvider.notifier).enable();
      await c.read(performanceSettingsProvider.notifier).disable();
      expect(c.read(performanceSettingsProvider).enabled, false);
    });

    test('setTileQuality() altera e persiste', () async {
      final c = await _container();
      await c.read(performanceSettingsProvider.notifier).load();
      await c.read(performanceSettingsProvider.notifier).setTileQuality(TileQuality.simple);
      expect(c.read(performanceSettingsProvider).tileQuality, TileQuality.simple);
    });

    test('setBlurEffects(false) persiste', () async {
      final c = await _container();
      await c.read(performanceSettingsProvider.notifier).load();
      await c.read(performanceSettingsProvider.notifier).setBlurEffects(false);
      expect(c.read(performanceSettingsProvider).blurEffectsEnabled, false);
    });

    test('setAnimations(false) persiste', () async {
      final c = await _container();
      await c.read(performanceSettingsProvider.notifier).load();
      await c.read(performanceSettingsProvider.notifier).setAnimations(false);
      expect(c.read(performanceSettingsProvider).animationsEnabled, false);
    });

    test('persiste entre reinicializações do container', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Boot 1: ativa performance mode
      final c1 = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      await c1.read(performanceSettingsProvider.notifier).load();
      await c1.read(performanceSettingsProvider.notifier).enable();
      await c1.read(performanceSettingsProvider.notifier).setTileQuality(TileQuality.simple);
      c1.dispose();

      // Boot 2: novo container com mesmas prefs deve carregar estado persistido
      final c2 = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(c2.dispose);
      await c2.read(performanceSettingsProvider.notifier).load();
      expect(c2.read(performanceSettingsProvider).enabled, true);
      expect(c2.read(performanceSettingsProvider).tileQuality, TileQuality.simple);
    });
  });
}
