import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/presentation/widgets/milestone_ranking_dialog.dart';
import 'package:capivara_2048/presentation/controllers/post_game_controller.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

// Helper: open the dialog via a button tap
Future<void> openDialog(WidgetTester tester, PostGameSummary summary) async {
  await tester.pumpWidget(
    wrap(
      Builder(
        builder: (ctx) {
          return ElevatedButton(
            onPressed: () => MilestoneRankingDialog.show(ctx, summary),
            child: const Text('Open'),
          );
        },
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pump();                              // inicia abertura do dialog
  await tester.pump(const Duration(milliseconds: 300)); // conclui animação de entrada
}

void main() {
  group('MilestoneRankingDialog', () {
    testWidgets('milestone 11 with position: shows ranking and time', (
      tester,
    ) async {
      const summary = PostGameSummary(
        milestone: 11,
        rankingPosition: 3,
        timeMs: 277000, // 04:37
        earnedCombo: false,
      );
      await openDialog(tester, summary);

      expect(find.textContaining('Ranking Global'), findsOneWidget);
      expect(find.textContaining('3º'), findsOneWidget);
      expect(find.textContaining('04:37'), findsOneWidget);
      expect(find.text('Ver Ranking'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
    });

    testWidgets('milestone 11 without position: omits ranking line', (
      tester,
    ) async {
      const summary = PostGameSummary(
        milestone: 11,
        rankingPosition: null,
        timeMs: 180000, // 03:00
        earnedCombo: false,
      );
      await openDialog(tester, summary);

      expect(find.textContaining('lugar'), findsNothing);
      expect(find.textContaining('03:00'), findsOneWidget);
    });

    testWidgets('milestone 12: shows Peixe-boi and time', (tester) async {
      const summary = PostGameSummary(
        milestone: 12,
        timeMs: 734000, // 12:14
        earnedCombo: false,
      );
      await openDialog(tester, summary);

      expect(find.textContaining('Peixe-boi'), findsOneWidget);
      expect(find.textContaining('12:14'), findsOneWidget);
      expect(find.text('Ver Ranking'), findsNothing); // only in milestone 11
    });

    testWidgets('milestone 13: shows Jacaré and times count', (tester) async {
      const summary = PostGameSummary(
        milestone: 13,
        timeMs: 0,
        timesReached8192: 3,
        earnedCombo: false,
      );
      await openDialog(tester, summary);

      expect(find.textContaining('Jacaré'), findsOneWidget);
      expect(find.textContaining('3'), findsWidgets);
      expect(find.textContaining('vezes'), findsOneWidget);
    });

    testWidgets('earnedCombo true: shows reward line', (tester) async {
      const summary = PostGameSummary(
        milestone: 11,
        rankingPosition: 5,
        timeMs: 120000, // 02:00
        earnedCombo: true,
      );
      await openDialog(tester, summary);

      expect(find.textContaining('Recorde'), findsOneWidget);
      expect(find.textContaining('vida'), findsOneWidget);
    });

    testWidgets('earnedCombo false: no reward line', (tester) async {
      const summary = PostGameSummary(
        milestone: 11,
        rankingPosition: 5,
        timeMs: 120000,
        earnedCombo: false,
      );
      await openDialog(tester, summary);

      expect(find.textContaining('Recorde'), findsNothing);
    });

    testWidgets('milestone 11: ConfettiWidget presente', (tester) async {
      const summary = PostGameSummary(
        milestone: 11,
        rankingPosition: 1,
        timeMs: 120000,
        earnedCombo: false,
      );
      await openDialog(tester, summary);
      expect(find.byType(ConfettiWidget), findsOneWidget);
    });

    testWidgets('milestone 12: ConfettiWidget presente', (tester) async {
      const summary = PostGameSummary(
        milestone: 12,
        timeMs: 300000,
        earnedCombo: false,
      );
      await openDialog(tester, summary);
      expect(find.byType(ConfettiWidget), findsOneWidget);
    });

    testWidgets('milestone 13: ConfettiWidget presente', (tester) async {
      const summary = PostGameSummary(
        milestone: 13,
        timeMs: 0,
        timesReached8192: 1,
        earnedCombo: false,
      );
      await openDialog(tester, summary);
      expect(find.byType(ConfettiWidget), findsOneWidget);
    });
  });
}
