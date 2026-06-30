import 'dart:math';

import 'package:flutter/material.dart';
// hide Direction — collides with our game engine's Direction enum
import 'package:flutter_animate/flutter_animate.dart' hide Direction;
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

// One tool shown at a time — avoids the long scroll where the undo board was
// hidden below the fold.
enum _ToolStep { bomb, undo, lives }

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
  _ToolStep _step = _ToolStep.bomb;

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
    // Let the success message breathe, then reveal the next tool.
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() => _step = _ToolStep.undo);
    });
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
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() => _step = _ToolStep.lives);
      widget.onUserCompleted?.call();
    });
  }

  // Animated finger nudging the user toward the action button.
  Widget _tapHint() {
    return const Text('👇', style: TextStyle(fontSize: 34))
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -4, end: 8, duration: 700.ms, curve: Curves.easeInOut);
  }

  Widget _toolCard({
    required Widget leading,
    required String title,
    required String subtitle,
  }) {
    return Card(
      color: Colors.white.withValues(alpha: 0.88),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3E2723),
                    ),
                  ),
                  Text(
                    subtitle,
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

  Widget _buildBombSection(double boardSize) {
    final isSelecting = _bombPhase == _BombPhase.selecting;
    final isExploding = _bombPhase == _BombPhase.exploding;
    final isDone = _bombPhase == _BombPhase.done;

    return Column(
      children: [
        _toolCard(
          leading: Image.asset(
            'assets/images/inventory/bomb_3.webp',
            width: 40,
            height: 40,
          ),
          title: 'Bomba 💣',
          subtitle: 'Apaga peças quando você se enrosca.',
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
        else if (_bombPhase == _BombPhase.idle) ...[
          _tapHint(),
          const SizedBox(height: 4),
          ElevatedButton(
            onPressed: () => setState(() => _bombPhase = _BombPhase.selecting),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
            ),
            child: Text(
              'Toque aqui pra usar a bomba 💣',
              style: GoogleFonts.fredoka(fontSize: 15, color: Colors.white),
            ),
          ),
        ] else if (isSelecting)
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
        _toolCard(
          leading: Image.asset(
            'assets/images/inventory/undo_1.webp',
            width: 40,
            height: 40,
          ),
          title: 'Desfazer ↩',
          subtitle: 'Volta a última jogada.',
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
        else ...[
          _tapHint(),
          const SizedBox(height: 4),
          ElevatedButton(
            onPressed: _undoPhase == _UndoPhase.idle ? _onUndoTap : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
            ),
            child: Text(
              'Toque aqui pra desfazer ↩',
              style: GoogleFonts.fredoka(fontSize: 15, color: Colors.white),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLivesSection() {
    return Column(
      children: [
        _toolCard(
          leading: const Icon(Icons.favorite, color: Colors.red, size: 40),
          title: 'Vidas ❤️',
          subtitle:
              'Cada partida custa uma vida. Elas se regeneram com o tempo — sem pressa!',
        ),
        const SizedBox(height: 16),
        OutlinedText(
          text: 'Pronto! É só tocar em Próximo →',
          style: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Cap the board so one tool + card + button fits without scrolling.
    final boardSize = min(screenWidth - 48, 300.0);

    final section = switch (_step) {
      _ToolStep.bomb => _buildBombSection(boardSize),
      _ToolStep.undo => _buildUndoSection(boardSize),
      _ToolStep.lives => _buildLivesSection(),
    };

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
          // key forces a clean swap (and restarts the finger animation) per step
          KeyedSubtree(key: ValueKey(_step), child: section),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
