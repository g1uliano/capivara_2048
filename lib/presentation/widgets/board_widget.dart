import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/game_constants.dart';
import '../controllers/game_notifier.dart';
import 'tile_widget.dart';

class BoardWidget extends ConsumerWidget {
  final double? size;
  const BoardWidget({super.key, this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(gameProvider).board;
    final screenWidth = MediaQuery.of(context).size.width;
    final boardSize = size ?? (screenWidth - GameConstants.boardPadding * 2);
    final tileSize = (boardSize - GameConstants.tileSpacing * (GameConstants.boardSize + 1)) /
        GameConstants.boardSize;

    return Container(
      width: boardSize,
      height: boardSize,
      decoration: BoxDecoration(
        color: const Color(0xFFE8D5B7),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(GameConstants.tileSpacing),
      child: Column(
        children: List.generate(GameConstants.boardSize, (r) =>
          Expanded(
            child: Row(
              children: List.generate(GameConstants.boardSize, (c) =>
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(GameConstants.tileSpacing / 2),
                    child: TileWidget(tile: board[r][c], size: tileSize),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
