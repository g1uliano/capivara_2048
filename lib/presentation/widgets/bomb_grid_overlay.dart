import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/game_constants.dart';
import '../controllers/game_notifier.dart';

/// Selection grid using the exact same layout as BoardWidget (Column of Rows
/// with Expanded + same padding values), so cells align pixel-perfectly.
class BombGridOverlay extends ConsumerWidget {
  const BombGridOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final state = ref.watch(gameProvider);
    final selected = state.selectedBombTiles;
    final board = state.board;

    return Padding(
      padding: const EdgeInsets.all(GameConstants.tileSpacing),
      child: Column(
        children: List.generate(GameConstants.boardSize, (r) => Expanded(
          child: Row(
            children: List.generate(GameConstants.boardSize, (c) {
              final isSelected = selected.contains((r, c));
              final tile = board[r][c];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(GameConstants.tileSpacing / 2),
                  child: GestureDetector(
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
                            ? Colors.red.shade400
                            : Colors.white,
                        border: Border.all(
                          color: isSelected ? Colors.red.shade700 : Colors.grey.shade300,
                          width: isSelected ? 3 : 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: tile != null
                          ? Center(
                              child: Text(
                                '${1 << tile.level}',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              );
            }),
          ),
        )),
      ),
    );
  }
}
