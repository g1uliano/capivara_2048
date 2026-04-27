import 'package:capivara_2048/presentation/widgets/pause_button_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PauseButtonTile', () {
    testWidgets('renderiza com tileSize correto', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PauseButtonTile(tileSize: 80, onTap: () {}),
        ),
      ));
      final size = tester.getSize(find.byType(PauseButtonTile));
      expect(size.width, 80.0);
      expect(size.height, 80.0);
    });

    testWidgets('mostra ícone pause_circle_filled', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PauseButtonTile(tileSize: 80, onTap: () {}),
        ),
      ));
      expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
    });

    testWidgets('mostra texto "Pausar"', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PauseButtonTile(tileSize: 80, onTap: () {}),
        ),
      ));
      expect(find.text('Pausar'), findsOneWidget);
    });

    testWidgets('chama onTap ao ser tocado', (tester) async {
      var called = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PauseButtonTile(tileSize: 80, onTap: () => called = true),
        ),
      ));
      await tester.tap(find.byType(PauseButtonTile));
      expect(called, isTrue);
    });

    testWidgets('tem Semantics com label "Botão Pausar"', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PauseButtonTile(tileSize: 80, onTap: () {}),
        ),
      ));
      expect(
        find.bySemanticsLabel('Botão Pausar'),
        findsOneWidget,
      );
    });
  });
}
