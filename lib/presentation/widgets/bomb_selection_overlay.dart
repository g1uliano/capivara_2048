import 'dart:math';

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
    final selected = state.selectedBombTiles;
    final board = state.board;

    // Mirror game_screen.dart layout constants
    const headerH = 72.0;
    const inventoryH = 64.0 + 8.0;
    const verticalPad = 8.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Exact same formula as game_screen.dart boardSide
        final boardPixelSize = min(
          constraints.maxWidth - 24,
          constraints.maxHeight - headerH - inventoryH - verticalPad,
        );

        return Container(
          color: const Color(0x80000000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Align label with top of board area
              SizedBox(
                height: headerH,
                child: Center(
                  child: Text(
                    'Selecione $maxTiles tiles para destruir',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              // Expanded matches the Expanded(BoardWidget) in game_screen
              Expanded(
                child: Center(
                  child: SizedBox(
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
                ),
              ),
              // Align cancel button with inventory bar area
              SizedBox(
                height: inventoryH,
                child: Center(
                  child: TextButton(
                    onPressed: notifier.cancelBomb,
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
