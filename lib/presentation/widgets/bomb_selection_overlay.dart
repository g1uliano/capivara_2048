import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/game_constants.dart';
import '../../domain/game_engine/bomb_mode.dart';
import '../controllers/game_notifier.dart';

class BombSelectionOverlay extends ConsumerWidget {
  const BombSelectionOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final state = ref.watch(gameProvider);
    final mode = state.bombMode;
    if (mode == null) return const SizedBox.shrink();

    final maxTiles = mode == BombMode.bomb2 ? 2 : 3;
    final selected = notifier.bombSelection;
    final board = state.board;

    // Board pixel size: tiles + gaps + padding
    const double boardPixelSize = GameConstants.boardSize * GameConstants.tileSize +
        (GameConstants.boardSize - 1) * GameConstants.tileSpacing +
        2 * GameConstants.boardPadding;

    return Container(
      color: const Color(0x80000000),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Selecione $maxTiles tiles para destruir',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: boardPixelSize,
            height: boardPixelSize,
            child: GridView.builder(
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
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: notifier.cancelBomb,
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
