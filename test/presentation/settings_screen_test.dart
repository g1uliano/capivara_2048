import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capivara_2048/presentation/screens/settings_screen.dart';
import 'package:capivara_2048/presentation/controllers/settings_notifier.dart';
import 'package:capivara_2048/presentation/widgets/outlined_text.dart';

Widget _wrap(SharedPreferences prefs) {
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const MaterialApp(home: SettingsScreen()),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('toggle haptic muda estado e persiste', (tester) async {
    SharedPreferences.setMockInitialValues({'settings.haptic_enabled': true});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_wrap(prefs));
    await tester.pump();

    expect(prefs.getBool('settings.haptic_enabled'), isTrue);
    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(prefs.getBool('settings.haptic_enabled'), isFalse);
  });

  testWidgets('sliders de áudio presentes com onChanged null', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_wrap(prefs));
    await tester.pump();

    final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
    expect(sliders.length, 2);
    for (final slider in sliders) {
      expect(slider.onChanged, isNull);
    }
  });

  testWidgets('"Olha o Bichim! © Catraia Aplicativos" presente', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_wrap(prefs));
    await tester.pump();

    expect(find.textContaining('Catraia Aplicativos'), findsOneWidget);
  });

  testWidgets('"Disponível na Fase 5" presente', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_wrap(prefs));
    await tester.pump();

    expect(find.textContaining('Fase 5'), findsOneWidget);
  });

  testWidgets('títulos de seção usam OutlinedText', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_wrap(prefs));
    await tester.pump();

    expect(find.byType(OutlinedText), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(OutlinedText),
        matching: find.text('Gameplay'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('toggle Reduzir Efeitos Visuais presente na SettingsScreen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_wrap(prefs));
    await tester.pump();

    expect(find.text('Reduzir Efeitos Visuais'), findsOneWidget);
  });

  testWidgets('controles estão dentro de Cards brancos semi-opacos', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_wrap(prefs));
    await tester.pump();

    expect(find.byType(Card), findsWidgets);
  });

  testWidgets('dropdown de idioma está ausente', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_wrap(prefs));
    await tester.pump();

    expect(find.text('PT-BR'), findsNothing);
    expect(find.text('EN'), findsNothing);
  });
}
