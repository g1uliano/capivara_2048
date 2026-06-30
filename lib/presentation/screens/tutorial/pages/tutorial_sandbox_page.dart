import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../data/models/game_state.dart';
import '../../../../data/models/tile.dart';
import '../../../../domain/game_engine/direction.dart' as game;
import '../../../../domain/game_engine/game_engine.dart';
import '../../../widgets/glass_panel.dart';
import '../../../widgets/outlined_text.dart';
import '../widgets/tutorial_board.dart';

enum _SandboxStep { movement, unite, free }

class TutorialSandboxPage extends StatefulWidget {
  final VoidCallback onUserCompleted;
  // ponytail: boardSize permite injetar tamanho fixo nos testes
  final double? boardSize;
  const TutorialSandboxPage({super.key, required this.onUserCompleted, this.boardSize});

  @override
  State<TutorialSandboxPage> createState() => _TutorialSandboxPageState();
}

class _TutorialSandboxPageState extends State<TutorialSandboxPage> {
  _SandboxStep _step = _SandboxStep.movement;
  late GameEngine _engine;
  late GameState _state;
  int _fusions = 0;
  bool _stepDone = false;

  @override
  void initState() {
    super.initState();
    _engine = GameEngine(random: Random(42));
    _state = _buildStepAState();
  }

  GameState _buildStepAState() {
    final board = List.generate(4, (_) => List<Tile?>.filled(4, null));
    board[0][0] = const Tile(id: 'a1', level: 1, row: 0, col: 0);
    board[1][2] = const Tile(id: 'a2', level: 2, row: 1, col: 2);
    board[2][0] = const Tile(id: 'a3', level: 3, row: 2, col: 0);
    board[3][3] = const Tile(id: 'a4', level: 4, row: 3, col: 3);
    return GameState(
      board: board,
      score: 0,
      highScore: 0,
      isGameOver: false,
      hasWon: false,
      maxLevel: 4,
    );
  }

  GameState _buildStepBState() {
    final board = List.generate(4, (_) => List<Tile?>.filled(4, null));
    board[1][0] = const Tile(id: 'b1', level: 1, row: 1, col: 0);
    board[1][2] = const Tile(id: 'b2', level: 1, row: 1, col: 2);
    board[1][3] = const Tile(id: 'b3', level: 3, row: 1, col: 3);
    return GameState(
      board: board,
      score: 0,
      highScore: 0,
      isGameOver: false,
      hasWon: false,
      maxLevel: 3,
    );
  }

  bool _boardChanged(GameState prev, GameState next) {
    int count(GameState s) =>
        s.board.expand((r) => r).whereType<Tile>().length;
    return next.score > prev.score || count(next) > count(prev);
  }

  void _onSwipe(game.Direction dir) {
    if (_stepDone && _step != _SandboxStep.free) return;
    final prev = _state;
    final next = _engine.move(prev, dir);
    if (!_boardChanged(prev, next)) return;

    setState(() => _state = next);

    switch (_step) {
      case _SandboxStep.movement:
        setState(() => _stepDone = true);
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          setState(() {
            _step = _SandboxStep.unite;
            _stepDone = false;
            _engine = GameEngine(random: Random(1));
            _state = _buildStepBState();
          });
        });
      case _SandboxStep.unite:
        if (next.score > prev.score) {
          setState(() => _stepDone = true);
          Future.delayed(const Duration(milliseconds: 700), () {
            if (!mounted) return;
            setState(() {
              _step = _SandboxStep.free;
              _stepDone = false;
              _engine = GameEngine();
            });
          });
        }
      case _SandboxStep.free:
        if (next.score > prev.score) {
          _fusions++;
          if (_fusions >= 2 && !_stepDone) {
            setState(() => _stepDone = true);
            widget.onUserCompleted();
          }
        }
    }
  }

  String get _title {
    switch (_step) {
      case _SandboxStep.movement:
        return 'Deslize pra mover tudo';
      case _SandboxStep.unite:
        return 'Junte dois iguais num só bicho';
      case _SandboxStep.free:
        return 'Agora é com você!';
    }
  }

  String get _subtitle {
    switch (_step) {
      case _SandboxStep.movement:
        return 'Arraste o dedo em qualquer direção — todos os bichos vão juntos pra parede.';
      case _SandboxStep.unite:
        return 'Deslize pra juntar as duas tanajuras num só bicho. O bicho diferente não vai se juntar.';
      case _SandboxStep.free:
        return 'Junte mais alguns bichos e veja o que acontece!';
    }
  }

  String get _successMessage {
    switch (_step) {
      case _SandboxStep.movement:
        return '✓ Viu? Todos foram juntos!';
      case _SandboxStep.unite:
        return '✓ Você criou um bicho novo! 🎉';
      case _SandboxStep.free:
        return '✓ Você pegou o jeito! 🌿';
    }
  }

  String get _hint {
    switch (_step) {
      case _SandboxStep.movement:
        return '👉 Deslize o dedo em qualquer direção';
      case _SandboxStep.unite:
        return '👉 Deslize pra juntar as tanajuras';
      case _SandboxStep.free:
        return '👉 Continue jogando e junte mais bichos';
    }
  }

  Widget _swipeHint() {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.85,
        child: const Text('☝️', style: TextStyle(fontSize: 48))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveX(begin: -40, end: 40, duration: 800.ms, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                Text(
                  _title,
                  style: GoogleFonts.fredoka(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _subtitle,
                  style: GoogleFonts.fredoka(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              TutorialBoard(
                key: ValueKey(_step),
                state: _state,
                onSwipe: _onSwipe,
                size: widget.boardSize,
              ),
              if (_step == _SandboxStep.movement && !_stepDone)
                _swipeHint(),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedOpacity(
            opacity: _stepDone ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: OutlinedText(
              text: _successMessage,
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: _stepDone ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            child: OutlinedText(
              text: _hint,
              style: GoogleFonts.fredoka(fontSize: 14),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 1.0, end: 1.03, duration: 1500.ms),
          ),
        ],
      ),
    );
  }
}
