import 'package:capivara_2048/presentation/screens/debug/animals_gallery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AnimalsGalleryScreen renders without crash', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AnimalsGalleryScreen(),
      ),
    );

    expect(find.byType(AnimalsGalleryScreen), findsOneWidget);
    expect(find.text('Galeria de Animais'), findsOneWidget);
  });

  testWidgets('AnimalsGalleryScreen mostra coluna Host 2×2', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AnimalsGalleryScreen()),
    );
    await tester.pump();
    expect(find.text('Host 2×2'), findsAtLeastNWidgets(1));
  });

  testWidgets('AnimalsGalleryScreen shows all 11 animal names', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AnimalsGalleryScreen(),
      ),
    );

    await tester.pumpAndSettle();

    final expectedNames = [
      'Tanajura', 'Lobo-guará', 'Sapo-cururu', 'Tucano', 'Sagui',
      'Preguiça', 'Mico-leão-dourado', 'Boto-cor-de-rosa',
      'Onça-pintada', 'Sucuri', 'Capivara Lendária',
    ];

    for (final name in expectedNames) {
      // Use "— Name —" pattern to match only animal rows, not the header note.
      final rowFinder = find.textContaining('— $name —');
      await tester.scrollUntilVisible(
        rowFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(rowFinder, findsAtLeastNWidgets(1),
          reason: '$name should appear in the gallery');
    }
  });
}
