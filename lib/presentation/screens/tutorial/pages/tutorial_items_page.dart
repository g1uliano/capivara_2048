import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/game_state.dart';
import '../../../../data/models/tile.dart';
import '../../../../domain/game_engine/game_engine.dart';
import '../../../widgets/board_widget.dart';
import '../../../widgets/bomb_explosion_overlay.dart';
import '../../../widgets/bomb_grid_overlay.dart';
import '../../../widgets/glass_panel.dart';
import '../../../widgets/outlined_text.dart';
import '../../../widgets/vhs_rewind_overlay.dart';

// One tool shown at a time — avoids the long scroll where the undo board was
// hidden below the fold.
enum _ToolStep { bomb, undo, lives }

enum _BombPhase { idle, selecting, exploding, done }

enum _UndoPhase { demo, idle, rewinding, done }

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

  _UndoPhase _undoPhase = _UndoPhase.demo;
  late GameState _undoState;

  static const _bombMaxTiles = 2;

  @override
  void initState() {
    super.initState();
    _bombState = _buildBombBoard();
    _undoState = _buildUndoState();
  }

  GameState _buildBombBoard() {
    // Full board, no adjacent pair with equal level — literally stuck (game over).
    // Shows WHY the bomb is useful: no moves left, need to clear space.
    final board = List.generate(4, (_) => List<Tile?>.filled(4, null));
    board[0][0] = const Tile(id: 'bb00', level: 1, row: 0, col: 0);
    board[0][1] = const Tile(id: 'bb01', level: 3, row: 0, col: 1);
    board[0][2] = const Tile(id: 'bb02', level: 2, row: 0, col: 2);
    board[0][3] = const Tile(id: 'bb03', level: 4, row: 0, col: 3);
    board[1][0] = const Tile(id: 'bb10', level: 4, row: 1, col: 0);
    board[1][1] = const Tile(id: 'bb11', level: 2, row: 1, col: 1);
    board[1][2] = const Tile(id: 'bb12', level: 5, row: 1, col: 2);
    board[1][3] = const Tile(id: 'bb13', level: 1, row: 1, col: 3);
    board[2][0] = const Tile(id: 'bb20', level: 2, row: 2, col: 0);
    board[2][1] = const Tile(id: 'bb21', level: 5, row: 2, col: 1);
    board[2][2] = const Tile(id: 'bb22', level: 1, row: 2, col: 2);
    board[2][3] = const Tile(id: 'bb23', level: 3, row: 2, col: 3);
    board[3][0] = const Tile(id: 'bb30', level: 3, row: 3, col: 0);
    board[3][1] = const Tile(id: 'bb31', level: 1, row: 3, col: 1);
    board[3][2] = const Tile(id: 'bb32', level: 4, row: 3, col: 2);
    board[3][3] = const Tile(id: 'bb33', level: 2, row: 3, col: 3);
    return GameState(
      board: board,
      score: 0,
      highScore: 0,
      isGameOver: false,
      hasWon: false,
      maxLevel: 5,
    );
  }

  GameState _buildUndoState() {
    // PRE state: classic corner stack — a good strategic position.
    final preBoard = List.generate(4, (_) => List<Tile?>.filled(4, null));
    preBoard[0][0] = const Tile(id: 'up00', level: 6, row: 0, col: 0);
    preBoard[1][0] = const Tile(id: 'up10', level: 5, row: 1, col: 0);
    preBoard[1][1] = const Tile(id: 'up11', level: 4, row: 1, col: 1);
    preBoard[2][0] = const Tile(id: 'up20', level: 3, row: 2, col: 0);
    preBoard[2][1] = const Tile(id: 'up21', level: 2, row: 2, col: 1);
    preBoard[2][2] = const Tile(id: 'up22', level: 1, row: 2, col: 2);
    preBoard[3][0] = const Tile(id: 'up30', level: 2, row: 3, col: 0);
    preBoard[3][1] = const Tile(id: 'up31', level: 1, row: 3, col: 1);
    final pre = GameState(
      board: preBoard,
      score: 0,
      highScore: 0,
      isGameOver: false,
      hasWon: false,
      maxLevel: 6,
    );

    // POST state: same tiles scattered to the right after a bad swipe — looks worse.
    // Shown to the user first; undo restores pre above (via undoStack).
    final postBoard = List.generate(4, (_) => List<Tile?>.filled(4, null));
    postBoard[0][3] = const Tile(id: 'uo03', level: 6, row: 0, col: 3);
    postBoard[1][2] = const Tile(id: 'uo12', level: 5, row: 1, col: 2);
    postBoard[1][3] = const Tile(id: 'uo13', level: 4, row: 1, col: 3);
    postBoard[2][1] = const Tile(id: 'uo21', level: 2, row: 2, col: 1);
    postBoard[2][2] = const Tile(id: 'uo22', level: 3, row: 2, col: 2);
    postBoard[2][3] = const Tile(id: 'uo23', level: 1, row: 2, col: 3);
    postBoard[3][1] = const Tile(id: 'uo31', level: 1, row: 3, col: 1);
    postBoard[3][2] = const Tile(id: 'uo32', level: 2, row: 3, col: 2);
    postBoard[3][3] = const Tile(id: 'uo33', level: 1, row: 3, col: 3);
    return GameState(
      board: postBoard,
      score: 0,
      highScore: 0,
      isGameOver: false,
      hasWon: false,
      maxLevel: 6,
      undoStack: [pre],
    );
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
      _startUndoDemo();
    });
  }

  void _startUndoDemo() {
    // Plays the auto-move (pre→post): show pre board for 1400ms then switch.
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _undoPhase = _UndoPhase.idle);
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
        // Instruction sits ABOVE the board (outlined, readable). Drawing it on
        // top of the white selection grid would make white text vanish.
        if (isSelecting) ...[
          OutlinedText(
            text: 'Toque em $_bombMaxTiles peças pra destruir',
            style: GoogleFonts.fredoka(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: boardSize,
          height: boardSize,
          child: Stack(
            children: [
              BoardWidget(board: _bombState.board, size: boardSize),
              if (isSelecting)
                BombGridOverlay(
                  board: _bombState.board,
                  selected: _bombSelected,
                  onTapCell: _onBombTap,
                ),
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
          // Cancel lives BELOW the board, outside the grid, so it stays tappable.
          TextButton(
            onPressed: () => setState(() {
              _bombPhase = _BombPhase.idle;
              _bombSelected = {};
            }),
            child: OutlinedText(
              text: 'Cancelar',
              style: GoogleFonts.fredoka(fontSize: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildUndoSection(double boardSize) {
    final isDemo = _undoPhase == _UndoPhase.demo;
    final isDone = _undoPhase == _UndoPhase.done;
    final isRewinding = _undoPhase == _UndoPhase.rewinding;
    // During demo show the PRE board (good position); afterwards show POST (bad).
    final displayBoard = isDemo && _undoState.undoStack.isNotEmpty
        ? _undoState.undoStack.first.board
        : _undoState.board;

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
        if (isDemo) ...[
          OutlinedText(
            text: 'Fazendo uma jogada...',
            style: GoogleFonts.fredoka(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: boardSize,
          height: boardSize,
          child: Stack(
            children: [
              BoardWidget(board: displayBoard, size: boardSize),
              // Auto-swipe animation: 👉 slides right to show the move being made.
              if (isDemo)
                Align(
                  alignment: Alignment.center,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.85,
                      child: const Text('👉', style: TextStyle(fontSize: 48))
                          .animate(onPlay: (c) => c.repeat())
                          .fadeIn(duration: 200.ms)
                          .moveX(
                            begin: -50,
                            end: 50,
                            duration: 700.ms,
                            curve: Curves.easeInOut,
                          )
                          .then(delay: 300.ms)
                          .fadeOut(duration: 200.ms)
                          .then(delay: 300.ms),
                    ),
                  ),
                ),
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
        else if (!isDemo) ...[
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
    // Full content width — same size as the sandbox/game board. The scroll view
    // is the safety net if a tool needs more vertical room.
    final boardSize = screenWidth - 48;

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
