import 'package:capivara_2048/presentation/widgets/lives_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget w) =>
    MaterialApp(home: Scaffold(body: Center(child: w)));

void main() {
  group('LivesStatusBanner estados', () {
    testWidgets('current=5 → cor verde e texto "Completo"', (tester) async {
      await tester.pumpWidget(_wrap(LivesStatusBanner(
        current: 5,
        previousCurrent: 5,
        lastRegenAt: DateTime.now(),
      )));
      expect(find.text('Completo'), findsOneWidget);
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(LivesStatusBanner),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF66BB6A));
    });

    testWidgets('current=6 → cor dourada e texto "Bônus"', (tester) async {
      await tester.pumpWidget(_wrap(LivesStatusBanner(
        current: 6,
        previousCurrent: 5,
        lastRegenAt: DateTime.now(),
      )));
      expect(find.text('Bônus'), findsOneWidget);
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(LivesStatusBanner),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFFFD54F));
    });

    testWidgets('current=15 → cor dourada e texto "Bônus"', (tester) async {
      await tester.pumpWidget(_wrap(LivesStatusBanner(
        current: 15,
        previousCurrent: 15,
        lastRegenAt: DateTime.now(),
      )));
      expect(find.text('Bônus'), findsOneWidget);
    });

    testWidgets('current=50 → cor dourada e texto "Bônus" (>15 é Bônus)', (tester) async {
      await tester.pumpWidget(_wrap(LivesStatusBanner(
        current: 50,
        previousCurrent: 50,
        lastRegenAt: DateTime.now(),
      )));
      expect(find.text('Bônus'), findsOneWidget);
    });

    testWidgets('current=4 → cor laranja-âmbar e texto contendo "Restando"', (tester) async {
      await tester.pumpWidget(_wrap(LivesStatusBanner(
        current: 4,
        previousCurrent: 5,
        lastRegenAt: DateTime.now(),
      )));
      expect(find.textContaining('Restando'), findsOneWidget);
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(LivesStatusBanner),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFFFA726));
    });

    testWidgets('current=1 → cor laranja-âmbar e texto contendo "Restando"', (tester) async {
      await tester.pumpWidget(_wrap(LivesStatusBanner(
        current: 1,
        previousCurrent: 2,
        lastRegenAt: DateTime.now(),
      )));
      expect(find.textContaining('Restando'), findsOneWidget);
    });

    testWidgets('current=0 → cor vermelha e texto "Sem vidas" (sem timer)', (tester) async {
      await tester.pumpWidget(_wrap(LivesStatusBanner(
        current: 0,
        previousCurrent: 1,
        lastRegenAt: DateTime.now(),
      )));
      expect(find.text('Sem vidas'), findsOneWidget);
      expect(find.textContaining('Restando'), findsNothing);
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(LivesStatusBanner),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFEF5350));
    });

    testWidgets('largura fixa 120dp', (tester) async {
      await tester.pumpWidget(_wrap(LivesStatusBanner(
        current: 5,
        previousCurrent: 5,
        lastRegenAt: DateTime.now(),
      )));
      final size = tester.getSize(find.byType(LivesStatusBanner));
      expect(size.width, 120.0);
    });

    testWidgets('AnimatedSwitcher presente', (tester) async {
      await tester.pumpWidget(_wrap(LivesStatusBanner(
        current: 5,
        previousCurrent: 5,
        lastRegenAt: DateTime.now(),
      )));
      expect(find.byType(AnimatedSwitcher), findsOneWidget);
    });
  });
}
