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

  group('LivesStatusBanner countdown timer lógica', () {
    test('timerTextFor: 5 min atrás → exibe 25:00', () {
      final lastRegenAt = DateTime(2026, 1, 1, 12, 0, 0);
      final now = DateTime(2026, 1, 1, 12, 5, 0); // 5 min depois
      expect(LivesStatusBanner.timerTextFor(lastRegenAt, now), '25:00');
    });

    test('timerTextFor: 1 segundo depois → exibe 29:59', () {
      final lastRegenAt = DateTime(2026, 1, 1, 12, 0, 0);
      final now = DateTime(2026, 1, 1, 12, 0, 1);
      expect(LivesStatusBanner.timerTextFor(lastRegenAt, now), '29:59');
    });

    test('timerTextFor: 30 min exatos → exibe 00:00', () {
      final lastRegenAt = DateTime(2026, 1, 1, 12, 0, 0);
      final now = DateTime(2026, 1, 1, 12, 30, 0);
      expect(LivesStatusBanner.timerTextFor(lastRegenAt, now), '00:00');
    });

    test('timerTextFor: além de 30 min → exibe 00:00 (não negativo)', () {
      final lastRegenAt = DateTime(2026, 1, 1, 12, 0, 0);
      final now = DateTime(2026, 1, 1, 12, 35, 0);
      expect(LivesStatusBanner.timerTextFor(lastRegenAt, now), '00:00');
    });

    test('timerTextFor: valores decrementam a cada segundo', () {
      final lastRegenAt = DateTime(2026, 1, 1, 12, 0, 0);
      final t1 = DateTime(2026, 1, 1, 12, 5, 0);  // 25:00
      final t2 = DateTime(2026, 1, 1, 12, 5, 1);  // 24:59
      final text1 = LivesStatusBanner.timerTextFor(lastRegenAt, t1);
      final text2 = LivesStatusBanner.timerTextFor(lastRegenAt, t2);
      expect(text1, '25:00');
      expect(text2, '24:59');
      expect(text1, isNot(equals(text2)));
    });
  });
}
