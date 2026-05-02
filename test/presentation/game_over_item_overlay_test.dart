import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capivara_2048/presentation/screens/game/game_over_item_overlay.dart';

void main() {
  testWidgets('GameOverItemOverlay shows Continuar text', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: GameOverItemOverlay()),
        ),
      ),
    );
    expect(find.text('Continuar?'), findsOneWidget);
    expect(find.text('Usar item'), findsOneWidget);
    expect(find.text('Encerrar'), findsOneWidget);
  });
}
