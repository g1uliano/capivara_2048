import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../data/models/tile.dart';
import '../../../../domain/game_engine/direction.dart';
import '../../../widgets/tile_widget.dart';

class TutorialMiniBoard extends StatefulWidget {
  final List<Tile?> initialTiles;
  final Set<Direction> acceptedDirections;
  final Tile? mergedResult;
  final VoidCallback onCorrectSwipe;
  final double tileSize;

  const TutorialMiniBoard({
    super.key,
    required this.initialTiles,
    required this.acceptedDirections,
    required this.mergedResult,
    required this.onCorrectSwipe,
    this.tileSize = 90,
  });

  @override
  State<TutorialMiniBoard> createState() => _TutorialMiniBoardState();
}

class _TutorialMiniBoardState extends State<TutorialMiniBoard> {
  late List<Tile?> _tiles;
  bool _resolved = false;
  Timer? _callbackTimer;

  @override
  void initState() {
    super.initState();
    _tiles = List<Tile?>.from(widget.initialTiles);
  }

  Direction? _resolveDirection(Offset velocity) {
    final dx = velocity.dx;
    final dy = velocity.dy;
    if (dx.abs() < 80 && dy.abs() < 80) return null;
    if (dx.abs() > dy.abs()) {
      return dx > 0 ? Direction.right : Direction.left;
    } else {
      return dy > 0 ? Direction.down : Direction.up;
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_resolved) return;

    final direction = _resolveDirection(details.velocity.pixelsPerSecond);
    if (direction == null) return;
    if (!widget.acceptedDirections.contains(direction)) return;

    _resolved = true;

    setState(() {
      _tiles = _applyMove(direction);
    });

    _callbackTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) widget.onCorrectSwipe();
    });
  }

  @override
  void dispose() {
    _callbackTimer?.cancel();
    super.dispose();
  }

  List<Tile?> _applyMove(Direction direction) {
    final n = _tiles.length;
    final result = List<Tile?>.filled(n, null);

    if (widget.mergedResult != null) {
      // Fusion: collapse all tiles into one result
      final bool toEnd =
          direction == Direction.right || direction == Direction.down;
      if (toEnd) {
        result[n - 1] = widget.mergedResult;
      } else {
        result[0] = widget.mergedResult;
      }
    } else {
      // Move only: shift non-null tiles toward the appropriate end
      final nonNull = _tiles.where((t) => t != null).toList();
      final bool toEnd =
          direction == Direction.right || direction == Direction.down;
      if (toEnd) {
        int idx = n - 1;
        for (int i = nonNull.length - 1; i >= 0; i--) {
          result[idx--] = nonNull[i];
        }
      } else {
        int idx = 0;
        for (final t in nonNull) {
          result[idx++] = t;
        }
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanEnd: _handlePanEnd,
      child: Container(
        key: const Key('tutorial_mini_board'),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8D5B7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            _tiles.length,
            (i) => Padding(
              key: Key('tutorial_cell_$i'),
              padding: const EdgeInsets.all(4),
              child: SizedBox(
                width: widget.tileSize,
                height: widget.tileSize,
                child: TileWidget(tile: _tiles[i], size: widget.tileSize),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
