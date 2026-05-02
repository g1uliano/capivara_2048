import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capivara_2048/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen shows logo image', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SplashScreen()),
      ),
    );
    // Pump one frame to render the widget without advancing the 1500ms timer.
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    // Cancel animations (≤600ms) so no pending animation timers remain on dispose.
    await tester.pump(const Duration(milliseconds: 700));
  });
}
