import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capivara_2048/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen shows logo image', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          // precacheFuture já completa: post-await code roda, _navTimer
          // é agendado, e o dispose cancela ele no fim do teste.
          home: SplashScreen(precacheFuture: Future<void>.value()),
        ),
      ),
    );
    await tester.pump(); // first frame
    expect(find.byType(Image), findsOneWidget);
    // Avança 700ms: animação fadeIn (400ms) termina; _navTimer ainda pendente
    // (vai disparar em ~1500ms), mas é cancelado no dispose.
    await tester.pump(const Duration(milliseconds: 700));
  });
}
