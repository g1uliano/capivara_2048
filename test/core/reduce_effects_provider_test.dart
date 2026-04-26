import 'package:capivara_2048/core/providers/reduce_effects_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ReduceEffectsNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(reduceEffectsProvider), false);
    });

    test('toggle flips state and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(reduceEffectsProvider.notifier).toggle();
      expect(container.read(reduceEffectsProvider), true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('reduce_effects'), true);
    });

    test('load restores persisted value', () async {
      SharedPreferences.setMockInitialValues({'reduce_effects': true});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(reduceEffectsProvider.notifier).load();
      expect(container.read(reduceEffectsProvider), true);
    });
  });
}
