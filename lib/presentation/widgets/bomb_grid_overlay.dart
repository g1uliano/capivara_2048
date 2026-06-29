import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/game_constants.dart';
import '../../data/models/tile.dart';
import '../controllers/game_notifier.dart';

/// Selection grid using the exact same layout as BoardWidget (Column of Rows
/// with Expanded + same padding values), so cells align pixel-perfectly.
/// When [board], [selected] and [onTapCell] are provided,
/// operates in standalone mode (tutorial). Otherwise reads gameProvider.
class BombGridOverlay extends ConsumerWidget {
  // ponytail: optional params — tutorial passes local state, game uses provider default
  final List<List<Tile?>>? board;
  final Set<(int, int)>? selected;
  final void Function(int r, int c)? onTapCell;

  const BombGridOverlay({
    super.key,
    this.board,
    this.selected,
    this.onTapCell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStandalone = board != null;
    assert(
      board == null || onTapCell != null,
      'BombGridOverlay: standalone mode (board != null) requires onTapCell',
    );
    final notifier = isStandalone ? null : ref.read(gameProvider.notifier);
    final state = isStandalone ? null : ref.watch(gameProvider);

    final effectiveBoard = board ?? state!.board;
    final effectiveSelected =
        selected ?? Set<(int, int)>.from(state!.selectedBombTiles);
    final effectiveOnTap = onTapCell ??
        (int r, int c) {
          final tile = effectiveBoard[r][c];
          if (tile == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selecione uma peça com valor'),
                duration: Duration(seconds: 1),
              ),
            );
            return;
          }
          notifier!.selectBombTile(r, c);
        };

    return Padding(
      padding: const EdgeInsets.all(GameConstants.tileSpacing),
      child: Column(
        children: List.generate(GameConstants.boardSize, (r) => Expanded(
          child: Row(
            children: List.generate(GameConstants.boardSize, (c) {
              final isSelected = effectiveSelected.contains((r, c));
              final tile = effectiveBoard[r][c];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(GameConstants.tileSpacing / 2),
                  child: GestureDetector(
                    onTap: () => effectiveOnTap(r, c),
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
