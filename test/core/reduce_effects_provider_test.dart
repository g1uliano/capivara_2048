import 'package:capivara_2048/presentation/controllers/performance_settings_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PerformanceSettingsNotifier (blur/reduceEffects)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults blurEffectsEnabled to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(performanceSettingsProvider).blurEffectsEnabled, true);
    });

    test('setBlurEffects(false) flips state and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(performanceSettingsProvider.notifier).load();
      await container.read(performanceSettingsProvider.notifier).setBlurEffects(false);
      expect(container.read(performanceSettingsProvider).blurEffectsEnabled, false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('performance_settings'), contains('blurEffectsEnabled'));
    });

    test('load restores persisted blurEffectsEnabled=false', () async {
      SharedPreferences.setMockInitialValues({
        'performance_settings': '{"blurEffectsEnabled":false,"enabled":false,"tileQuality":0,"animationsEnabled":true,"autoDetectEnabled":true,"hasShownSuggestionDialog":false}',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(performanceSettingsProvider.notifier).load();
      expect(container.read(performanceSettingsProvider).blurEffectsEnabled, false);
    });
  });
}
