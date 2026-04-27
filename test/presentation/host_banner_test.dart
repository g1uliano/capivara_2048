import 'package:capivara_2048/presentation/widgets/host_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  group('HostBanner', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_wrap(const HostBanner()));
      await tester.pump();
      expect(find.byType(HostBanner), findsOneWidget);
    });

    testWidgets('has width equal to tileSize by default', (tester) async {
      await tester.pumpWidget(_wrap(const HostBanner()));
      await tester.pump();
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(of: find.byType(HostBanner), matching: find.byType(SizedBox)).first,
      );
      // tileSize = 72.0 (GameConstants.tileSize)
      expect(sizedBox.width, 72.0);
    });
  });
}
