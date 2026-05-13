import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/text_styles.dart';
import '../../domain/daily_rewards/daily_rewards_engine.dart';

enum DayTileState { future, currentAvailable, claimed }

/// Visual de recompensa diária baseado nas imagens reward_day_0X.webp.
///
/// 3 estados:
/// - future: imagem com opacidade reduzida (mistério)
/// - currentAvailable: imagem com glow dourado e pulse
/// - claimed: imagem escurecida + checkmark verde
///
/// Quando isDay7=true usa reward_day_07.webp (panorâmica) para o grande prêmio.
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
      box = _ClaimedImage(day: day, width: width, height: height, isDay7: isDay7);
    } else {
      box = _RewardDayImage(
        day: day,
        width: width,
        height: height,
        isCurrent: isCurrent,
        isDay7: isDay7,
      );
    }

    // Label fora dos Stacks internos — garantidamente centrado pelo SizedBox
    Widget content = SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          box,
          if (!isClaimed && !isDay7)
            Positioned(
              left: 0,
              right: 0,
              bottom: 6,
              child: Text(
                'Dia $day',
                textAlign: TextAlign.center,
                style: outlinedWhiteTextStyle(
                  GoogleFonts.fredoka(
                    fontSize: (width * 0.16).clamp(12, 18),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

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

String _rewardImagePath(int day) =>
    'assets/images/reward/reward_day_${day.toString().padLeft(2, '0')}.webp';

// ─────────────────────────────────────────────────────────────────────────────
// REWARD DAY IMAGE (future + current — dias 1-6 e dia 7)
// ─────────────────────────────────────────────────────────────────────────────

class _RewardDayImage extends StatelessWidget {
  final int day;
  final double width;
  final double height;
  final bool isCurrent;
  final bool isDay7;

  const _RewardDayImage({
    required this.day,
    required this.width,
    required this.height,
    required this.isCurrent,
    required this.isDay7,
  });

  @override
  Widget build(BuildContext context) {
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
                  color: const Color(0xFFFFD54F).withValues(
                    alpha: isDay7 ? 0.85 : 0.7,
                  ),
                  blurRadius: isDay7 ? 30 : 20,
                  spreadRadius: isDay7 ? 6 : 4,
                ),
              ],
            ),
          ),

        // Imagem principal
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset(
            _rewardImagePath(day),
            width: width,
            height: height,
            fit: BoxFit.cover,
          ),
        ),

        // Borda dourada quando current
        if (isCurrent)
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFFD54F),
                width: 2.5,
              ),
            ),
          ),

        // Label do Dia 7 fica aqui pois está sobre a imagem (dias 1-6 estão no Stack externo)
        if (isDay7)
          Positioned(
            left: 0,
            right: 0,
            bottom: height * 0.08,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'DIA 7',
                  textAlign: TextAlign.center,
                  style: outlinedWhiteTextStyle(
                    GoogleFonts.fredoka(
                      color: const Color(0xFFFFD700),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Text(
                  'GRANDE PRÊMIO',
                  textAlign: TextAlign.center,
                  style: outlinedWhiteTextStyle(
                    GoogleFonts.fredoka(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Sparkle quando current
        if (isCurrent && isDay7) ...[
          Positioned(
            top: -8,
            left: 12,
            child: const Icon(Icons.auto_awesome, color: Color(0xFFFFE082), size: 22)
                .animate(onPlay: (c) => c.repeat())
                .fade(duration: 700.ms, begin: 1.0, end: 0.3)
                .then()
                .fade(duration: 700.ms, begin: 0.3, end: 1.0),
          ),
          Positioned(
            top: -4,
            right: 18,
            child: const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 18)
                .animate(onPlay: (c) => c.repeat())
                .fade(duration: 900.ms, begin: 0.4, end: 1.0)
                .then()
                .fade(duration: 900.ms, begin: 1.0, end: 0.4),
          ),
        ] else if (isCurrent)
          Positioned(
            top: 6,
            right: 6,
            child: const Icon(Icons.auto_awesome, color: Color(0xFFFFE082), size: 16)
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
}

// ─────────────────────────────────────────────────────────────────────────────
// CLAIMED IMAGE (recompensa já coletada)
// ─────────────────────────────────────────────────────────────────────────────

class _ClaimedImage extends StatelessWidget {
  final int day;
  final double width;
  final double height;
  final bool isDay7;

  const _ClaimedImage({
    required this.day,
    required this.width,
    required this.height,
    required this.isDay7,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Imagem escurecida (claimed)
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.50),
              BlendMode.darken,
            ),
            child: Image.asset(
              _rewardImagePath(day),
              width: width,
              height: height,
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Checkmark verde
        Container(
          width: width * 0.42,
          height: width * 0.42,
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
          child: const Icon(Icons.check, color: Colors.white, size: 28),
        ),

        // Label
        Positioned(
          left: 0,
          right: 0,
          bottom: 6,
          child: Text(
            isDay7 ? 'Dia 7 ✓' : 'Dia $day',
            textAlign: TextAlign.center,
            style: outlinedWhiteTextStyle(
              GoogleFonts.fredoka(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
