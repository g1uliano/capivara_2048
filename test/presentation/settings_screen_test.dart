import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capivara_2048/presentation/screens/settings_screen.dart';
import 'package:capivara_2048/presentation/controllers/settings_notifier.dart';

Widget _wrap(SettingsNotifier notifier) {
  return ProviderScope(
    overrides: [settingsProvider.overrideWith((ref) => notifier)],
    child: const MaterialApp(home: SettingsScreen()),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('toggle haptic muda estado e persiste', (tester) async {
    SharedPreferences.setMockInitialValues({'settings.haptic_enabled': true});
    final prefs = await SharedPreferences.getInstance();
    final notifier = SettingsNotifier(prefs);
    await tester.pumpWidget(_wrap(notifier));
    await tester.pump();

    expect(notifier.state.hapticEnabled, isTrue);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(notifier.state.hapticEnabled, isFalse);
    expect(prefs.getBool('settings.haptic_enabled'), isFalse);
  });

  testWidgets('toggle idioma para EN persiste', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final notifier = SettingsNotifier(prefs);
    await tester.pumpWidget(_wrap(notifier));
    await tester.pump();

    await tester.tap(find.text('EN'));
    await tester.pump();
    expect(notifier.state.locale, 'en');
    expect(prefs.getString('settings.locale'), 'en');
  });

  testWidgets('sliders de áudio presentes com onChanged null', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final notifier = SettingsNotifier(prefs);
    await tester.pumpWidget(_wrap(notifier));
    await tester.pump();

    final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
    expect(sliders.length, 2);
    for (final slider in sliders) {
      expect(slider.onChanged, isNull);
    }
  });

  testWidgets('"Olha o Bichim! © Catraia Aplicativos" presente', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final notifier = SettingsNotifier(prefs);
    await tester.pumpWidget(_wrap(notifier));
    await tester.pump();

    expect(find.textContaining('Catraia Aplicativos'), findsOneWidget);
  });

  testWidgets('"Disponível na Fase 5" presente', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final notifier = SettingsNotifier(prefs);
    await tester.pumpWidget(_wrap(notifier));
    await tester.pump();

    expect(find.textContaining('Fase 5'), findsOneWidget);
  });
}
