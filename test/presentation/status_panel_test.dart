import 'package:capivara_2048/presentation/widgets/status_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  group('StatusPanel', () {
    testWidgets('renderiza sem PauseButtonTile na subárvore', (tester) async {
      await tester.pumpWidget(_wrap(const StatusPanel()));
      await tester.pump();
      expect(find.byKey(const Key('pause_button')), findsNothing);
    });

    testWidgets('renderiza sem erro', (tester) async {
      await tester.pumpWidget(_wrap(const StatusPanel()));
      await tester.pump();
      expect(find.byType(StatusPanel), findsOneWidget);
    });
  });
}
