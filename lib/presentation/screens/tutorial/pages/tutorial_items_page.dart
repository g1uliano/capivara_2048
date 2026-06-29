import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/game_state.dart';
import '../../../../data/models/tile.dart';
import '../../../../domain/game_engine/direction.dart';
import '../../../../domain/game_engine/game_engine.dart';
import '../../../widgets/board_widget.dart';
import '../../../widgets/bomb_explosion_overlay.dart';
import '../../../widgets/bomb_grid_overlay.dart';
import '../../../widgets/bomb_selection_overlay.dart';
import '../../../widgets/glass_panel.dart';
import '../../../widgets/outlined_text.dart';
import '../../../widgets/vhs_rewind_overlay.dart';

enum _BombPhase { idle, selecting, exploding, done }

enum _UndoPhase { idle, rewinding, done }

class TutorialItemsPage extends StatefulWidget {
  // ponytail: nullable — tutorial screen passes callback, standalone use works without it
  final VoidCallback? onUserCompleted;
  const TutorialItemsPage({super.key, this.onUserCompleted});

  @override
  State<TutorialItemsPage> createState() => _TutorialItemsPageState();
}

class _TutorialItemsPageState extends State<TutorialItemsPage> {
  _BombPhase _bombPhase = _BombPhase.idle;
  Set<(int, int)> _bombSelected = {};
  late GameState _bombState;

  _UndoPhase _undoPhase = _UndoPhase.idle;
  late GameState _undoState;

  static const _bombMaxTiles = 2;

  @override
  void initState() {
    super.initState();
    _bombState = _buildBombBoard();
    _undoState = _buildUndoState();
  }

  GameState _buildBombBoard() {
    final board = List.generate(4, (_) => List<Tile?>.filled(4, null));
    board[0][0] = const Tile(id: 'bb1', level: 3, row: 0, col: 0);
    board[0][2] = const Tile(id: 'bb2', level: 1, row: 0, col: 2);
    board[0][3] = const Tile(id: 'bb3', level: 5, row: 0, col: 3);
    board[1][1] = const Tile(id: 'bb4', level: 2, row: 1, col: 1);
    board[1][3] = const Tile(id: 'bb5', level: 4, row: 1, col: 3);
    board[2][0] = const Tile(id: 'bb6', level: 6, row: 2, col: 0);
    board[2][2] = const Tile(id: 'bb7', level: 3, row: 2, col: 2);
    board[3][1] = const Tile(id: 'bb8', level: 1, row: 3, col: 1);
    board[3][3] = const Tile(id: 'bb9', level: 2, row: 3, col: 3);
    return GameState(
      board: board,
      score: 0,
      highScore: 0,
      isGameOver: false,
      hasWon: false,
      maxLevel: 6,
    );
  }

  GameState _buildUndoState() {
    final board = List.generate(4, (_) => List<Tile?>.filled(4, null));
    board[1][0] = const Tile(id: 'ub1', level: 2, row: 1, col: 0);
    board[1][3] = const Tile(id: 'ub2', level: 2, row: 1, col: 3);
    final pre = GameState(
      board: board,
      score: 0,
      highScore: 0,
      isGameOver: false,
      hasWon: false,
      maxLevel: 2,
    );
    // Run a move so undoStack has the pre-move state for restoration
    return GameEngine(random: Random(13)).move(pre, Direction.right);
  }

  void _onBombTap(int r, int c) {
    if (_bombPhase != _BombPhase.selecting) return;
    final tile = _bombState.board[r][c];
    if (tile == null) return;
    final pos = (r, c);
    setState(() {
      if (_bombSelected.contains(pos)) {
        _bombSelected = Set.from(_bombSelected)..remove(pos);
      } else if (_bombSelected.length < _bombMaxTiles) {
        _bombSelected = {..._bombSelected, pos};
        if (_bombSelected.length == _bombMaxTiles) {
          _bombPhase = _BombPhase.exploding;
        }
      }
    });
  }

  void _onExplodeComplete() {
    if (!mounted) return;
    // removeTiles is static
    final newState = GameEngine.removeTiles(_bombState, _bombSelected.toList());
    setState(() {
      _bombState = newState;
      _bombSelected = {};
      _bombPhase = _BombPhase.done;
    });
    _checkDone();
  }

  void _onUndoTap() {
    if (_undoPhase != _UndoPhase.idle) return;
    setState(() => _undoPhase = _UndoPhase.rewinding);
  }

  void _onVhsComplete() {
    if (!mounted) return;
    // undoStack stores most recent at index 0
    final prev = _undoState.undoStack.isNotEmpty
        ? _undoState.undoStack.first
        : _undoState;
    setState(() {
      _undoState = prev;
      _undoPhase = _UndoPhase.done;
    });
    _checkDone();
  }

  void _checkDone() {
    if (_bombPhase == _BombPhase.done && _undoPhase == _UndoPhase.done) {
      widget.onUserCompleted?.call();
    }
  }

  Widget _buildBombSection(double boardSize) {
    final isSelecting = _bombPhase == _BombPhase.selecting;
    final isExploding = _bombPhase == _BombPhase.exploding;
    final isDone = _bombPhase == _BombPhase.done;

    return Column(
      children: [
        Card(
          color: Colors.white.withValues(alpha: 0.88),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/inventory/bomb_3.webp',
                  width: 40,
                  height: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bomba 💣',
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3E2723),
                        ),
                      ),
                      Text(
                        'Apaga peças quando você se enrosca.',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: boardSize,
          height: boardSize,
          child: Stack(
            children: [
              BoardWidget(board: _bombState.board, size: boardSize),
              if (isSelecting) ...[
                BombDimOverlay(
                  maxTiles: _bombMaxTiles,
                  onCancel: () => setState(() {
                    _bombPhase = _BombPhase.idle;
                    _bombSelected = {};
                  }),
                ),
                BombGridOverlay(
                  board: _bombState.board,
                  selected: _bombSelected,
                  onTapCell: _onBombTap,
                ),
              ],
              if (isExploding)
                BombExplosionOverlay(
                  positions: _bombSelected.toList(),
                  isBomb3: false,
                  onComplete: _onExplodeComplete,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (isDone)
          OutlinedText(
            text: '✓ Você usou a bomba!',
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          )
        else if (_bombPhase == _BombPhase.idle)
          ElevatedButton(
            onPressed: () => setState(() => _bombPhase = _BombPhase.selecting),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
            ),
            child: Text(
              'Encrencou? Toque na bomba 💣',
              style: GoogleFonts.fredoka(fontSize: 15, color: Colors.white),
            ),
          )
        else if (isSelecting)
          OutlinedText(
            text: 'Selecione $_bombMaxTiles peças para destruir',
            style: GoogleFonts.fredoka(fontSize: 14),
          ),
      ],
    );
  }

  Widget _buildUndoSection(double boardSize) {
    final isDone = _undoPhase == _UndoPhase.done;
    final isRewinding = _undoPhase == _UndoPhase.rewinding;

    return Column(
      children: [
        Card(
          color: Colors.white.withValues(alpha: 0.88),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/inventory/undo_1.webp',
                  width: 40,
                  height: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Desfazer ↩',
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3E2723),
                        ),
                      ),
                      Text(
                        'Volta a última jogada.',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: boardSize,
          height: boardSize,
          child: Stack(
            children: [
              BoardWidget(board: _undoState.board, size: boardSize),
              if (isRewinding)
                VhsRewindOverlay(
                  isUndo3: false,
                  onComplete: _onVhsComplete,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (isDone)
          OutlinedText(
            text: '✓ Você desfez a jogada!',
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          ElevatedButton(
            onPressed: _undoPhase == _UndoPhase.idle ? _onUndoTap : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
            ),
            child: Text(
              'Errou? Toque em desfazer ↩',
              style: GoogleFonts.fredoka(fontSize: 15, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildLivesSection() {
    return Card(
      color: Colors.white.withValues(alpha: 0.88),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.red, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vidas ❤️',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3E2723),
                    ),
                  ),
                  Text(
                    'Cada partida custa uma vida. Elas se regeneram com o tempo — sem pressa!',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final boardSize = screenWidth - 48.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Text(
              'Suas ferramentas',
              style: GoogleFonts.fredoka(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          _buildBombSection(boardSize),
          const SizedBox(height: 16),
          _buildUndoSection(boardSize),
          const SizedBox(height: 16),
          _buildLivesSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
