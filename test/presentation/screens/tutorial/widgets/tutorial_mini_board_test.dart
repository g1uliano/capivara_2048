import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/tile.dart';
import 'package:capivara_2048/domain/game_engine/direction.dart';
import 'package:capivara_2048/presentation/screens/tutorial/widgets/tutorial_mini_board.dart';

Tile makeTile(int level) =>
    Tile(id: 'test_$level', level: level, row: 0, col: 0);

void main() {
  group('TutorialMiniBoard', () {
    testWidgets('renders N cells from initialTiles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TutorialMiniBoard(
              initialTiles: [makeTile(1), null],
              acceptedDirections: const {Direction.right},
              mergedResult: null,
              onCorrectSwipe: () {},
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('tutorial_cell_0')), findsOneWidget);
      expect(find.byKey(const Key('tutorial_cell_1')), findsOneWidget);
    });

    testWidgets('correct swipe calls onCorrectSwipe after delay', (
      tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TutorialMiniBoard(
                initialTiles: [makeTile(1), null],
                acceptedDirections: const {Direction.right},
                mergedResult: null,
                onCorrectSwipe: () => called = true,
              ),
            ),
          ),
        ),
      );
      await tester.fling(
        find.byKey(const Key('tutorial_mini_board')),
        const Offset(200, 0),
        1000,
      );
      // Wait past the 600ms delay
      await tester.pump(const Duration(milliseconds: 700));
      expect(called, true);
    });

    testWidgets('wrong direction does not call onCorrectSwipe', (tester) async {
      var called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TutorialMiniBoard(
                initialTiles: [makeTile(1), null],
                acceptedDirections: const {Direction.right},
                mergedResult: null,
                onCorrectSwipe: () => called = true,
              ),
            ),
          ),
        ),
      );
      await tester.fling(
        find.byKey(const Key('tutorial_mini_board')),
        const Offset(-200, 0),
        1000,
      );
      await tester.pump(const Duration(milliseconds: 700));
      expect(called, false);
    });
  });
}
