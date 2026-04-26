import 'package:capivara_2048/core/providers/reduce_effects_provider.dart';
import 'package:capivara_2048/presentation/widgets/outlined_text.dart';
import 'package:capivara_2048/presentation/widgets/pause_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('PauseOverlay uses BackdropFilter when reduceEffects is false',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: const MaterialApp(
          home: Scaffold(body: PauseOverlay()),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('PauseOverlay has no BackdropFilter when reduceEffects is true',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reduceEffectsProvider.overrideWith((ref) {
            final notifier = ReduceEffectsNotifier();
            notifier.state = true;
            return notifier;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: PauseOverlay()),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('PauseOverlay uses OutlinedText for "Pausado"', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: const MaterialApp(
          home: Scaffold(body: PauseOverlay()),
        ),
      ),
    );

    final pausadoFinder = find.byWidgetPredicate(
      (w) => w is OutlinedText && w.text == 'Pausado',
    );
    expect(pausadoFinder, findsOneWidget);
  });

  testWidgets('PauseOverlay uses OutlinedText for button labels', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: const MaterialApp(
          home: Scaffold(body: PauseOverlay()),
        ),
      ),
    );

    for (final label in ['Continuar', 'Reiniciar', 'Menu']) {
      expect(
        find.byWidgetPredicate((w) => w is OutlinedText && w.text == label),
        findsOneWidget,
        reason: '"$label" should use OutlinedText',
      );
    }
  });

  testWidgets('PauseOverlay uses OutlinedText for reduce-effects label', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: const MaterialApp(
          home: Scaffold(body: PauseOverlay()),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (w) => w is OutlinedText && w.text == 'Reduzir efeitos visuais',
      ),
      findsOneWidget,
    );
  });

  testWidgets('PauseOverlay renders tint overlay Container with black opacity', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: const MaterialApp(
          home: Scaffold(body: PauseOverlay()),
        ),
      ),
    );

    final tintFinder = find.byWidgetPredicate((w) {
      if (w is! Container) return false;
      final color = w.color;
      if (color == null) return false;
      return color.alpha == Colors.black.withOpacity(0.25).alpha &&
             color.red == 0 && color.green == 0 && color.blue == 0;
    });
    expect(tintFinder, findsAtLeastNWidgets(1));
  });
}
