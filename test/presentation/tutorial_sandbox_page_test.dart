import 'package:capivara_2048/presentation/screens/tutorial/pages/tutorial_sandbox_page.dart';
import 'package:capivara_2048/presentation/screens/tutorial/widgets/tutorial_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Simulates pressing "Próximo" immediately when the page marks a step done.
void Function({required bool animated, VoidCallback? action}) _autoNext() {
  return ({required bool animated, VoidCallback? action}) {
    if (animated && action != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => action());
    }
  };
}

void main() {
  group('TutorialSandboxPage gating', () {
    testWidgets('step A avança para B após swipe válido + Próximo', (tester) async {
      bool completed = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TutorialSandboxPage(
                onUserCompleted: () => completed = true,
                boardSize: 200,
                setNextState: _autoNext(),
              ),
            ),
          ),
        ),
      );

      // Step A deve estar ativo
      expect(find.text('Deslize pra mover tudo'), findsOneWidget);
      expect(find.text('Junte dois iguais num só bicho'), findsNothing);

      // Simula swipe pra direita via GestureDetector (TutorialBoard interno)
      await tester.fling(
        find.byType(GestureDetector).first,
        const Offset(200, 0),
        800,
      );
      await tester.pump();

      // addPostFrameCallback do _autoNext dispara na próxima frame
      await tester.pump();
      // pump extra pra animações
      await tester.pump(const Duration(milliseconds: 100));

      // Step B deve estar ativo
      expect(find.text('Junte dois iguais num só bicho'), findsOneWidget);
      expect(completed, isFalse);
    });

    testWidgets('step B avança para C após merge + Próximo', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TutorialSandboxPage(
                onUserCompleted: () {},
                boardSize: 200,
                setNextState: _autoNext(),
              ),
            ),
          ),
        ),
      );

      // Advance to step B via a right swipe on step A
      await tester.fling(
        find.byType(GestureDetector).first,
        const Offset(200, 0),
        800,
      );
      await tester.pump();
      await tester.pump(); // addPostFrameCallback
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Junte dois iguais num só bicho'), findsOneWidget);

      // Step B: swipe left to merge the two tanajuras (level 1)
      await tester.fling(
        find.byType(GestureDetector).first,
        const Offset(-200, 0),
        800,
      );
      await tester.pump();
      await tester.pump(); // addPostFrameCallback
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Agora é com você!'), findsOneWidget);
    });
  });
}
