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

    testWidgets('has fixed width of twoCellWidth', (tester) async {
      await tester.pumpWidget(_wrap(const HostBanner()));
      await tester.pump();
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(of: find.byType(HostBanner), matching: find.byType(SizedBox)).first,
      );
      // twoCellWidth = 72*2+8 = 152
      expect(sizedBox.width, 152.0);
    });
  });
}
