import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capivara_2048/presentation/widgets/bomb_explosion_overlay.dart';

void main() {
  group('BombExplosionOverlay', () {
    testWidgets('renderiza sem crash com posições válidas', (tester) async {
      bool completed = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 300,
                child: BombExplosionOverlay(
                  positions: const [(0, 0), (1, 2)],
                  isBomb3: false,
                  onComplete: () => completed = true,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(BombExplosionOverlay), findsOneWidget);
      // Flush pending timer to avoid "pending timers" error
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('onComplete é chamado após a animação', (tester) async {
      bool completed = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 300,
                child: BombExplosionOverlay(
                  positions: const [(0, 0)],
                  isBomb3: true,
                  onComplete: () => completed = true,
                ),
              ),
            ),
          ),
        ),
      );
      // Avançar além da duração da animação (350ms + margem)
      await tester.pump(const Duration(milliseconds: 500));
      expect(completed, isTrue);
    });
  });
}
