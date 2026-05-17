import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/daily_rewards_state.dart';
import '../../../domain/daily_rewards/daily_rewards_engine.dart';
import '../../../domain/daily_rewards/daily_rewards_notifier.dart';
import '../../../domain/lives/lives_notifier.dart';
import '../../controllers/performance_settings_notifier.dart';
import '../../widgets/capivara_mascot.dart';
import '../../widgets/daily_reward_day_tile.dart';
import '../../widgets/daily_reward_overlay.dart';

class DailyRewardsScreen extends ConsumerStatefulWidget {
  const DailyRewardsScreen({super.key});

  @override
  ConsumerState<DailyRewardsScreen> createState() => _DailyRewardsScreenState();
}

class _DailyRewardsScreenState extends ConsumerState<DailyRewardsScreen> {
  Timer? _timer;
  Duration _untilMidnight = Duration.zero;
  bool _showOverlay = false;
  DailyReward? _lastReward;
  int? _animatingDay;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _updateCountdown();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    if (mounted) setState(() => _untilMidnight = midnight.difference(now));
  }

  String _formatCountdown(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _onClaim(DailyRewardStatus status, int effectiveDay) async {
    final livesState = ref.read(livesProvider);
    final reward = rewardForDay(effectiveDay);

    if (reward.lives > 0 && livesState.lives >= livesState.earnedCap) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Cap de vidas atingido',
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Você já tem o máximo de vidas (${livesState.earnedCap}). '
            'As vidas desta recompensa serão descartadas. Coletar mesmo assim?',
            style: GoogleFonts.nunito(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar', style: GoogleFonts.nunito()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Coletar', style: GoogleFonts.nunito()),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _animatingDay = effectiveDay);
    await ref.read(dailyRewardsProvider.notifier).claim(DateTime.now());

    if (mounted) {
      setState(() {
        _animatingDay = null;
        _lastReward = reward;
        _showOverlay = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyState = ref.watch(dailyRewardsProvider);
    final status = computeDailyRewardStatus(DateTime.now(), dailyState);

    final int effectiveDay =
        (status == DailyRewardStatus.streakBroken ||
            status == DailyRewardStatus.cycleCompleted)
        ? 1
        : dailyState.currentDay;

    final claimable =
        status == DailyRewardStatus.available ||
        status == DailyRewardStatus.streakBroken ||
        status == DailyRewardStatus.cycleCompleted;

    return Scaffold(
      backgroundColor: const Color(0xFF071812),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Recompensa Diária',
          style: GoogleFonts.fredoka(color: Colors.white, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF071812),
              Color(0xFF0D2B1C),
              Color(0xFF0A2218),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                child: Column(
                  children: [
                    if (status == DailyRewardStatus.streakBroken)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _StreakBrokenBanner(),
                      ),
                    _StreakHeader(currentDay: effectiveDay),
                    const SizedBox(height: 20),
                    _SerpentinePath(
                      dailyState: dailyState,
                      status: status,
                      effectiveDay: effectiveDay,
                      animatingDay: _animatingDay,
                      onTapDay: claimable
                          ? (d) {
                              if (d == effectiveDay) {
                                _onClaim(status, effectiveDay);
                              }
                            }
                          : null,
                    ),
                    const SizedBox(height: 20),
                    if (claimable)
                      _ClaimButton(
                        status: status,
                        onPressed: () => _onClaim(status, effectiveDay),
                      )
                    else
                      _CountdownCard(
                        countdown: _untilMidnight,
                        formatter: _formatCountdown,
                      ),
                  ],
                ),
              ),
              if (_showOverlay && _lastReward != null)
                DailyRewardOverlay(
                  reward: _lastReward!,
                  onDismiss: () => setState(() => _showOverlay = false),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER (streak info)
// ─────────────────────────────────────────────────────────────────────────────

class _StreakHeader extends StatelessWidget {
  final int currentDay;
  const _StreakHeader({required this.currentDay});

  @override
  Widget build(BuildContext context) {
    return _DailyPanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Color(0xFFFFAB40),
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dia $currentDay de 7',
                  style: GoogleFonts.fredoka(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: currentDay / 7.0,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFFD54F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakBrokenBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _DailyPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFFAB40),
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Você perdeu a streak! Recomeçando do Dia 1.',
              style: GoogleFonts.fredoka(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SERPENTINE PATH (zigzag with 6 tiles + chest)
// ─────────────────────────────────────────────────────────────────────────────

class _SerpentinePath extends StatelessWidget {
  final DailyRewardsState dailyState;
  final DailyRewardStatus status;
  final int effectiveDay;
  final int? animatingDay;
  final ValueChanged<int>? onTapDay;

  const _SerpentinePath({
    required this.dailyState,
    required this.status,
    required this.effectiveDay,
    required this.animatingDay,
    required this.onTapDay,
  });

  bool _isClaimed(int day) {
    return day < effectiveDay ||
        (status == DailyRewardStatus.alreadyClaimed &&
            day == dailyState.currentDay &&
            dailyState.claimedThisCycle) ||
        (status == DailyRewardStatus.cycleCompleted);
  }

  bool _isCurrent(int day) {
    return day == effectiveDay &&
        (status == DailyRewardStatus.available ||
            status == DailyRewardStatus.streakBroken ||
            status == DailyRewardStatus.cycleCompleted);
  }

  DayTileState _stateFor(int day) {
    if (_isClaimed(day)) return DayTileState.claimed;
    if (_isCurrent(day)) return DayTileState.currentAvailable;
    return DayTileState.future;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        // Tile dimensions for days 1–6 (compactos para caber sem scroll)
        final tileW = (w * 0.32).clamp(90.0, 120.0);
        final tileH = tileW * 1.05;
        final rowGap = 28.0;
        final sideMargin = w * 0.06;

        // Compute serpentine positions: 1=TL, 2=TR, 3=MR, 4=ML, 5=BL, 6=BR
        final leftX = sideMargin;
        final rightX = w - sideMargin - tileW;
        final positions = <Offset>[
          Offset(leftX, 0),
          Offset(rightX, 0),
          Offset(rightX, tileH + rowGap),
          Offset(leftX, tileH + rowGap),
          Offset(leftX, (tileH + rowGap) * 2),
          Offset(rightX, (tileH + rowGap) * 2),
        ];

        // Day 7 chest — mais alto para acomodar texto legível
        final chestY = (tileH + rowGap) * 3;
        final chestH = tileH * 1.20;
        final chestW = w - sideMargin * 2;

        final totalH = chestY + chestH + 16;

        // Capivara position: above the current day's tile (slightly to the side)
        final mascotSize = (tileW * 0.55).clamp(48.0, 70.0);
        Offset mascotOffset;
        const mascotYAdjust = -28.0;
        if (effectiveDay >= 1 && effectiveDay <= 6) {
          final tilePos = positions[effectiveDay - 1];
          // Offset mascot above and slightly toward outer edge
          final isLeftSide = tilePos.dx < w / 2;
          mascotOffset = Offset(
            tilePos.dx +
                (isLeftSide ? -mascotSize * 0.45 : tileW - mascotSize * 0.55),
            tilePos.dy + mascotYAdjust - 18,
          );
        } else {
          // Day 7 — chest center top
          mascotOffset = Offset(
            (w - mascotSize) / 2,
            chestY + mascotYAdjust - 24,
          );
        }

        // Tile centers (for path painting)
        final tileCenters = [
          for (final p in positions) Offset(p.dx + tileW / 2, p.dy + tileH / 2),
        ];
        final chestCenter = Offset(w / 2, chestY + chestH / 2);

        return SizedBox(
          width: w,
          height: totalH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Connecting trail
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrailPainter(
                    points: [...tileCenters, chestCenter],
                    progressDay: effectiveDay,
                  ),
                ),
              ),

              // Tiles 1–6
              for (int i = 0; i < 6; i++)
                Positioned(
                  left: positions[i].dx,
                  top: positions[i].dy,
                  child: _AnimatedClaimTile(
                    isAnimating: animatingDay == (i + 1),
                    child: DailyRewardDayTile(
                      day: i + 1,
                      reward: rewardForDay(i + 1),
                      tileState: _stateFor(i + 1),
                      isDay7: false,
                      width: tileW,
                      height: tileH,
                      onTap: onTapDay == null ? null : () => onTapDay!(i + 1),
                    ),
                  ),
                ),

              // Day 7 chest
              Positioned(
                left: sideMargin,
                top: chestY,
                child: _AnimatedClaimTile(
                  isAnimating: animatingDay == 7,
                  child: DailyRewardDayTile(
                    day: 7,
                    reward: rewardForDay(7),
                    tileState: _stateFor(7),
                    isDay7: true,
                    width: chestW,
                    height: chestH,
                    onTap: onTapDay == null ? null : () => onTapDay!(7),
                  ),
                ),
              ),

              // Capivara mascot — animated to current day
              AnimatedPositioned(
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOutCubic,
                left: mascotOffset.dx,
                top: mascotOffset.dy,
                child: CapivaraMascot(size: mascotSize),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Wraps a tile with the "claim animation" (scale up + fade out) when claimed.
class _AnimatedClaimTile extends ConsumerWidget {
  final bool isAnimating;
  final Widget child;

  const _AnimatedClaimTile({required this.isAnimating, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animationsEnabled = ref.watch(
      performanceSettingsProvider.select((s) => s.animationsEnabled),
    );

    if (!isAnimating || !animationsEnabled) return child;
    return child
        .animate()
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.3, 1.3),
          duration: 200.ms,
        )
        .then()
        .scale(
          begin: const Offset(1.3, 1.3),
          end: const Offset(1, 1),
          duration: 200.ms,
        )
        .fadeOut(delay: 300.ms, duration: 200.ms);
  }
}

/// Paints a dotted serpentine trail connecting tile centers.
/// Segments before the current day are golden (active), segments after are
/// faded white (locked).
class _TrailPainter extends CustomPainter {
  final List<Offset> points;
  final int progressDay;

  _TrailPainter({required this.points, required this.progressDay});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    for (int i = 0; i < points.length - 1; i++) {
      final segmentDay = i + 1; // segment from day(i+1) to day(i+2)
      final isActive = segmentDay < progressDay;
      final color = isActive
          ? const Color(0xFFFFD54F)
          : Colors.white.withValues(alpha: 0.35);

      _drawDottedLine(canvas, points[i], points[i + 1], color);
    }
  }

  void _drawDottedLine(Canvas canvas, Offset a, Offset b, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const dashLength = 6.0;
    const gapLength = 8.0;

    final delta = b - a;
    final distance = delta.distance;
    if (distance == 0) return;
    final direction = delta / distance;

    double covered = 0;
    while (covered < distance) {
      final start = a + direction * covered;
      final end = a + direction * (covered + dashLength).clamp(0, distance);
      canvas.drawLine(start, end, paint);
      covered += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPainter old) =>
      old.progressDay != progressDay || old.points != points;
}

// ─────────────────────────────────────────────────────────────────────────────
// CLAIM BUTTON & COUNTDOWN CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ClaimButton extends ConsumerWidget {
  final DailyRewardStatus status;
  final VoidCallback onPressed;

  const _ClaimButton({required this.status, required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animationsEnabled = ref.watch(
      performanceSettingsProvider.select((s) => s.animationsEnabled),
    );

    final label = status == DailyRewardStatus.cycleCompleted
        ? 'Iniciar novo ciclo'
        : 'Coletar recompensa';
    final button = SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD54F),
          foregroundColor: const Color(0xFF3E2723),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 6,
          shadowColor: Colors.black54,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.card_giftcard, size: 24),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    if (!animationsEnabled) return button;
    return button
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          duration: 1200.ms,
          begin: const Offset(1, 1),
          end: const Offset(1.03, 1.03),
          curve: Curves.easeInOut,
        );
  }
}

// Painel sólido otimizado para o fundo escuro desta tela (sem BackdropFilter)
class _DailyPanel extends StatelessWidget {
  const _DailyPanel({required this.child, this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF173D24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3FA968).withValues(alpha: 0.40),
          width: 1.0,
        ),
      ),
      child: child,
    );
  }
}

class _CountdownCard extends StatelessWidget {
  final Duration countdown;
  final String Function(Duration) formatter;

  const _CountdownCard({required this.countdown, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return _DailyPanel(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: Color(0xFFFFD54F),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Próxima recompensa em',
                style: GoogleFonts.fredoka(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD54F).withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: Text(
              formatter(countdown),
              style: GoogleFonts.fredoka(
                color: const Color(0xFFFFD54F),
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
