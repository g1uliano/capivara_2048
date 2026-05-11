import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/daily_rewards/daily_rewards_engine.dart';

enum DayTileState { future, currentAvailable, claimed }

/// Visual de "presente embrulhado" para a trilha de recompensa diária.
///
/// 3 estados:
/// - future: caixa fechada com fita, conteúdo escondido (mistério)
/// - currentAvailable: caixa pulsando dourada, "Toque pra abrir!"
/// - claimed: caixa aberta vazia com ✓ verde
///
/// Quando isDay7=true, a caixa vira um baú de tesouro maior e dourado.
class DailyRewardDayTile extends StatelessWidget {
  final int day;
  final DailyReward reward;
  final DayTileState tileState;
  final bool isDay7;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const DailyRewardDayTile({
    super.key,
    required this.day,
    required this.reward,
    required this.tileState,
    required this.isDay7,
    this.width = 110,
    this.height = 120,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = tileState == DayTileState.currentAvailable;
    final isClaimed = tileState == DayTileState.claimed;

    Widget box;
    if (isClaimed) {
      box = _OpenedGiftBox(
        day: day,
        width: width,
        height: height,
        isDay7: isDay7,
      );
    } else if (isDay7) {
      box = _TreasureChest(
        day: day,
        reward: reward,
        width: width,
        height: height,
        isCurrent: isCurrent,
      );
    } else {
      box = _ClosedGiftBox(
        day: day,
        width: width,
        height: height,
        isCurrent: isCurrent,
      );
    }

    Widget content = SizedBox(width: width, height: height, child: box);

    // Dim future tiles slightly to suggest "not yet"
    if (tileState == DayTileState.future) {
      content = Opacity(opacity: 0.75, child: content);
    }

    // Pulse + shimmer animation when current
    if (isCurrent) {
      content = content
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            duration: 900.ms,
            begin: const Offset(1, 1),
            end: const Offset(1.06, 1.06),
            curve: Curves.easeInOut,
          );
    }

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLOSED GIFT BOX (future + current days 1–6)
// ─────────────────────────────────────────────────────────────────────────────

class _ClosedGiftBox extends StatelessWidget {
  final int day;
  final double width;
  final double height;
  final bool isCurrent;

  const _ClosedGiftBox({
    required this.day,
    required this.width,
    required this.height,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    // Cor da caixa varia por dia para dar vida visual
    final colors = _giftColors(day);
    final ribbonColor = isCurrent ? const Color(0xFFFFC107) : Colors.white;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Glow dourado quando é o dia atual
        if (isCurrent)
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.7),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

        // Caixa principal
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCurrent ? const Color(0xFFFFD54F) : Colors.white24,
              width: isCurrent ? 2.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),

        // Tampa da caixa (faixa horizontal escura no topo)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: height * 0.28,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
          ),
        ),

        // Fita vertical
        Positioned(
          top: 0,
          bottom: 0,
          child: Container(width: width * 0.13, color: ribbonColor),
        ),

        // Fita horizontal (na "tampa")
        Positioned(
          top: height * 0.21,
          left: 0,
          right: 0,
          child: Container(height: height * 0.10, color: ribbonColor),
        ),

        // Laço no topo (2 círculos sobrepostos)
        Positioned(
          top: -height * 0.08,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: width * 0.22,
                height: width * 0.22,
                decoration: BoxDecoration(
                  color: ribbonColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12, width: 1),
                ),
              ),
              SizedBox(width: width * 0.02),
              Container(
                width: width * 0.22,
                height: width * 0.22,
                decoration: BoxDecoration(
                  color: ribbonColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12, width: 1),
                ),
              ),
            ],
          ),
        ),

        // Número do dia (embaixo da fita horizontal)
        Positioned(
          bottom: height * 0.12,
          child: Text(
            'Dia $day',
            style: GoogleFonts.fredoka(
              color: Colors.white,
              fontSize: (width * 0.20).clamp(15, 22),
              fontWeight: FontWeight.w900,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: Offset(1.5, 1.5),
                ),
                Shadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: Offset(-1.5, -1.5),
                ),
                Shadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: Offset(1.5, -1.5),
                ),
                Shadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: Offset(-1.5, 1.5),
                ),
              ],
            ),
          ),
        ),

        // Sparkle quando current
        if (isCurrent)
          Positioned(
            top: 8,
            right: 8,
            child:
                const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFFFE082),
                      size: 18,
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .rotate(duration: 2000.ms, begin: 0, end: 1)
                    .then()
                    .fade(duration: 400.ms, begin: 1.0, end: 0.5)
                    .then()
                    .fade(duration: 400.ms, begin: 0.5, end: 1.0),
          ),
      ],
    );
  }

  /// Paleta variando por dia para deixar a trilha colorida.
  List<Color> _giftColors(int day) {
    switch (day) {
      case 1:
        return [const Color(0xFFEF5350), const Color(0xFFC62828)]; // vermelho
      case 2:
        return [const Color(0xFF42A5F5), const Color(0xFF1565C0)]; // azul
      case 3:
        return [const Color(0xFFAB47BC), const Color(0xFF6A1B9A)]; // roxo
      case 4:
        return [const Color(0xFF26A69A), const Color(0xFF00695C)]; // teal
      case 5:
        return [const Color(0xFFFF7043), const Color(0xFFD84315)]; // laranja
      case 6:
        return [const Color(0xFFEC407A), const Color(0xFFAD1457)]; // rosa
      default:
        return [const Color(0xFF66BB6A), const Color(0xFF2E7D32)]; // verde
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OPENED GIFT BOX (claimed)
// ─────────────────────────────────────────────────────────────────────────────

class _OpenedGiftBox extends StatelessWidget {
  final int day;
  final double width;
  final double height;
  final bool isDay7;

  const _OpenedGiftBox({
    required this.day,
    required this.width,
    required this.height,
    required this.isDay7,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Caixa "vazia" — escurecida e dessaturada
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24, width: 1),
          ),
        ),

        // "Tampa" levantada acima da caixa (sugere abertura)
        Positioned(
          top: -height * 0.16,
          left: width * 0.08,
          right: width * 0.08,
          child: Transform.rotate(
            angle: -0.12,
            child: Container(
              height: height * 0.20,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24, width: 1),
              ),
            ),
          ),
        ),

        // Check verde grande no centro
        Container(
          width: width * 0.45,
          height: width * 0.45,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 32),
        ),

        // Label "Dia X" pequeno embaixo
        Positioned(
          bottom: 6,
          child: Text(
            isDay7 ? 'Dia 7 ✓' : 'Dia $day',
            style: GoogleFonts.fredoka(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TREASURE CHEST (Day 7)
// ─────────────────────────────────────────────────────────────────────────────

class _TreasureChest extends StatelessWidget {
  final int day;
  final DailyReward reward;
  final double width;
  final double height;
  final bool isCurrent;

  const _TreasureChest({
    required this.day,
    required this.reward,
    required this.width,
    required this.height,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Glow dourado intenso
        if (isCurrent)
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.85),
                  blurRadius: 30,
                  spreadRadius: 6,
                ),
              ],
            ),
          ),

        // Tampa do baú (parte de cima, arredondada)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: height * 0.42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
              border: Border.all(color: const Color(0xFFFFD700), width: 3),
            ),
          ),
        ),

        // Corpo do baú
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: height * 0.62,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6D4C41), Color(0xFF3E2723)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(color: const Color(0xFFFFD700), width: 3),
            ),
          ),
        ),

        // Faixa horizontal dourada (linha de junção da tampa)
        Positioned(
          top: height * 0.38,
          left: 0,
          right: 0,
          child: Container(height: 6, color: const Color(0xFFFFD700)),
        ),

        // Cadêado/jóia menor (não compete com texto)
        Positioned(
          top: height * 0.30,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.brown.shade900, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.star, color: Colors.brown, size: 16),
          ),
        ),

        // Texto "DIA 7" GRANDE no centro do corpo do baú
        Positioned(
          bottom: height * 0.20,
          child: Text(
            'DIA 7',
            style: GoogleFonts.fredoka(
              color: const Color(0xFFFFD700),
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
                Shadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: Offset(-2, -2),
                ),
                Shadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: Offset(2, -2),
                ),
                Shadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: Offset(-2, 2),
                ),
              ],
            ),
          ),
        ),

        // Subtítulo "GRANDE PRÊMIO"
        Positioned(
          bottom: height * 0.06,
          child: Text(
            'GRANDE PRÊMIO',
            style: GoogleFonts.fredoka(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  blurRadius: 3,
                  offset: Offset(1, 1),
                ),
                Shadow(
                  color: Colors.black,
                  blurRadius: 3,
                  offset: Offset(-1, -1),
                ),
              ],
            ),
          ),
        ),

        // Sparkles nos cantos quando current
        if (isCurrent) ...[
          Positioned(
            top: -8,
            left: 12,
            child:
                const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFFFE082),
                      size: 22,
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .fade(duration: 700.ms, begin: 1.0, end: 0.3)
                    .then()
                    .fade(duration: 700.ms, begin: 0.3, end: 1.0),
          ),
          Positioned(
            top: -4,
            right: 18,
            child:
                const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFFFD700),
                      size: 18,
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .fade(duration: 900.ms, begin: 0.4, end: 1.0)
                    .then()
                    .fade(duration: 900.ms, begin: 1.0, end: 0.4),
          ),
        ],
      ],
    );
  }
}
