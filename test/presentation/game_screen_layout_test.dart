import 'package:capivara_2048/presentation/widgets/pause_button_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameScreen layout', () {
    testWidgets('PauseButtonTile tem tamanho mínimo 48x48', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PauseButtonTile(tileSize: 72, onTap: () {}),
          ),
        ),
      );
      final size = tester.getSize(find.byType(PauseButtonTile));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('PauseButtonTile tem tileSize de 72dp (GameConstants.tileSize)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PauseButtonTile(tileSize: 72, onTap: () {}),
          ),
        ),
      );
      final size = tester.getSize(find.byType(PauseButtonTile));
      expect(size.width, 72.0);
      expect(size.height, 72.0);
    });
  });
}
