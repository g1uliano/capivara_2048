import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capivara_2048/presentation/controllers/settings_notifier.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('estado inicial: hapticEnabled=true, locale=pt', () async {
    final prefs = await SharedPreferences.getInstance();
    final notifier = SettingsNotifier(prefs);
    expect(notifier.state.hapticEnabled, isTrue);
    expect(notifier.state.locale, 'pt');
  });

  test('setHaptic(false) persiste em SharedPreferences', () async {
    final prefs = await SharedPreferences.getInstance();
    final notifier = SettingsNotifier(prefs);
    notifier.setHaptic(false);
    expect(notifier.state.hapticEnabled, isFalse);
    expect(prefs.getBool('settings.haptic_enabled'), isFalse);
  });

  test('setLocale("en") persiste em SharedPreferences', () async {
    final prefs = await SharedPreferences.getInstance();
    final notifier = SettingsNotifier(prefs);
    notifier.setLocale('en');
    expect(notifier.state.locale, 'en');
    expect(prefs.getString('settings.locale'), 'en');
  });

  test('carrega valores persistidos ao inicializar', () async {
    SharedPreferences.setMockInitialValues({
      'settings.haptic_enabled': false,
      'settings.locale': 'en',
    });
    final prefs = await SharedPreferences.getInstance();
    final notifier = SettingsNotifier(prefs);
    expect(notifier.state.hapticEnabled, isFalse);
    expect(notifier.state.locale, 'en');
  });
}
