import 'package:capivara_2048/presentation/screens/tutorial/pages/tutorial_items_page.dart';
import 'package:capivara_2048/presentation/widgets/bomb_grid_overlay.dart';
import 'package:capivara_2048/presentation/widgets/bomb_selection_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TutorialItemsPage', () {
    testWidgets('mostra só a ferramenta atual, não bomba e desfazer juntos',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: TutorialItemsPage()),
          ),
        ),
      );

      // Primeiro passo: bomba — botão de bomba visível, desfazer ausente
      expect(find.text('Toque aqui pra usar a bomba 💣'), findsOneWidget);
      expect(find.text('Toque aqui pra desfazer ↩'), findsNothing);

      // Avança o relógio para a animação repetir, evitando timer pendente
      await tester.pump(const Duration(milliseconds: 800));
    });

    testWidgets('seleção mostra instrução legível e a grade, sem o dim overlay',
        (tester) async {
      // Viewport de celular — o tabuleiro de largura cheia caberia fora da tela
      // padrão (800x600) e o botão ficaria intocável.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: TutorialItemsPage()),
          ),
        ),
      );

      await tester.tap(find.text('Toque aqui pra usar a bomba 💣'));
      await tester.pump();

      // Grade de seleção presente; instrução legível fora da grade;
      // BombDimOverlay (rótulo branco sobre células brancas) não é mais usado
      expect(find.byType(BombGridOverlay), findsOneWidget);
      expect(find.text('Toque em 2 peças pra destruir'), findsOneWidget);
      expect(find.byType(BombDimOverlay), findsNothing);

      await tester.pump(const Duration(milliseconds: 800));
    });
  });
}
