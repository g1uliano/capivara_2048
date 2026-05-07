import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capivara_2048/presentation/controllers/settings_notifier.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('estado inicial: hapticEnabled=true, locale=pt', () async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final state = container.read(settingsProvider);
    expect(state.hapticEnabled, isTrue);
    expect(state.locale, 'pt');
  });

  test('setHaptic(false) persiste em SharedPreferences', () async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    container.read(settingsProvider.notifier).setHaptic(false);
    expect(container.read(settingsProvider).hapticEnabled, isFalse);
    expect(prefs.getBool('settings.haptic_enabled'), isFalse);
  });

  test('setLocale("en") persiste em SharedPreferences', () async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    container.read(settingsProvider.notifier).setLocale('en');
    expect(container.read(settingsProvider).locale, 'en');
    expect(prefs.getString('settings.locale'), 'en');
  });

  test('carrega valores persistidos ao inicializar', () async {
    SharedPreferences.setMockInitialValues({
      'settings.haptic_enabled': false,
      'settings.locale': 'en',
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final state = container.read(settingsProvider);
    expect(state.hapticEnabled, isFalse);
    expect(state.locale, 'en');
  });
}
