import 'package:flutter/material.dart';
import '../../../../data/models/game_state.dart';
import '../../../../domain/game_engine/direction.dart';
import '../../../widgets/board_widget.dart';

class TutorialBoard extends StatelessWidget {
  final GameState state;
  final void Function(Direction) onSwipe;
  final double? size;

  const TutorialBoard({
    super.key,
    required this.state,
    required this.onSwipe,
    this.size,
  });

  Direction? _resolveDirection(Offset velocity) {
    final dx = velocity.dx;
    final dy = velocity.dy;
    if (dx.abs() < 80 && dy.abs() < 80) return null;
    return dx.abs() > dy.abs()
        ? (dx > 0 ? Direction.right : Direction.left)
        : (dy > 0 ? Direction.down : Direction.up);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanEnd: (details) {
        final dir = _resolveDirection(details.velocity.pixelsPerSecond);
        if (dir != null) onSwipe(dir);
      },
      child: BoardWidget(board: state.board, size: size),
    );
  }
}
