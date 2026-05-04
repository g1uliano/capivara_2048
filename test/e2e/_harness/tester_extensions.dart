import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

enum SwipeDirection { up, down, left, right }

extension E2EHelpers on WidgetTester {
  /// Tap a widget identified by a string [Key] and call [pumpAndSettle].
  Future<void> tapByKey(String key) async {
    await tap(find.byKey(Key(key)));
    await pumpAndSettle();
  }

  /// Swipe the game board widget (found by Key 'game_board') in [dir].
  /// Falls back to screen center if the board is not in the tree.
  Future<void> swipeBoard(SwipeDirection dir) async {
    const swipeDistance = 200.0;
    final boardFinder = find.byKey(const Key('game_board'));
    final start = boardFinder.evaluate().isNotEmpty
        ? getCenter(boardFinder)
        : Offset(
            view.physicalSize.width / view.devicePixelRatio / 2,
            view.physicalSize.height / view.devicePixelRatio / 2,
          );

    final delta = switch (dir) {
      SwipeDirection.up    => const Offset(0, -swipeDistance),
      SwipeDirection.down  => const Offset(0, swipeDistance),
      SwipeDirection.left  => const Offset(-swipeDistance, 0),
      SwipeDirection.right => const Offset(swipeDistance, 0),
    };

    await flingFrom(start, delta, 800.0);
    await pumpAndSettle();
  }
}
