import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/game_constants.dart';
import '../controllers/game_notifier.dart';

/// Selection grid placed directly inside the board's Stack, so it's
/// pixel-aligned with the board by construction — no coordinate math needed.
class BombGridOverlay extends ConsumerWidget {
  const BombGridOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final state = ref.watch(gameProvider);
    final selected = state.selectedBombTiles;
    final board = state.board;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(GameConstants.boardPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: GameConstants.boardSize,
        mainAxisSpacing: GameConstants.tileSpacing,
        crossAxisSpacing: GameConstants.tileSpacing,
      ),
      itemCount: GameConstants.boardSize * GameConstants.boardSize,
      itemBuilder: (context, index) {
        final r = index ~/ GameConstants.boardSize;
        final c = index % GameConstants.boardSize;
        final isSelected = selected.contains((r, c));
        final tile = board[r][c];

        return GestureDetector(
          onTap: () {
            if (tile == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Selecione um tile com valor'),
                  duration: Duration(seconds: 1),
                ),
              );
              return;
            }
            notifier.selectBombTile(r, c);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.red.withValues(alpha: 0.7)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected ? Colors.red : Colors.white54,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: tile != null
                ? Center(
                    child: Text(
                      '${1 << tile.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
