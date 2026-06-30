import 'package:capivara_2048/presentation/screens/tutorial/pages/tutorial_items_page.dart';
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
  });
}
