import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/daily_rewards_state.dart';
import '../../../domain/daily_rewards/daily_rewards_engine.dart';
import '../../../domain/daily_rewards/daily_rewards_notifier.dart';
import '../../../domain/lives/lives_notifier.dart';
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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Cap de vidas atingido',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 18),
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

    final int effectiveDay = (status == DailyRewardStatus.streakBroken ||
            status == DailyRewardStatus.cycleCompleted)
        ? 1
        : dailyState.currentDay;

    final claimable = status == DailyRewardStatus.available ||
        status == DailyRewardStatus.streakBroken ||
        status == DailyRewardStatus.cycleCompleted;

    return Scaffold(
      backgroundColor: const Color(0xFF1E3A5F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                if (status == DailyRewardStatus.streakBroken)
                  _StreakBrokenBanner(),
                const SizedBox(height: 12),
                _DayGrid(
                  dailyState: dailyState,
                  status: status,
                  effectiveDay: effectiveDay,
                  animatingDay: _animatingDay,
                ),
                const Spacer(),
                if (claimable)
                  _ClaimButton(
                    status: status,
                    onPressed: () => _onClaim(status, effectiveDay),
                  )
                else
                  _CountdownWidget(countdown: _untilMidnight, formatter: _formatCountdown),
                const SizedBox(height: 32),
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
    );
  }
}

class _StreakBrokenBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Você perdeu a streak! Recomeçando do Dia 1.',
              style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayGrid extends StatelessWidget {
  final DailyRewardsState dailyState;
  final DailyRewardStatus status;
  final int effectiveDay;
  final int? animatingDay;

  const _DayGrid({
    required this.dailyState,
    required this.status,
    required this.effectiveDay,
    required this.animatingDay,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 4 tiles per row, 2 rows of 3/4, with spacing
        // Each tile has margin: EdgeInsets.all(4), contributing 8px per tile horizontally
        const spacing = 8.0;
        const tileMargin = 4.0;
        final tileW = (constraints.maxWidth - spacing * 3 - tileMargin * 2 * 4) / 4;
        final tileH = tileW * 1.25;

        Widget buildTile(int day) {
          final reward = rewardForDay(day);
          final isCurrent = day == effectiveDay &&
              (status == DailyRewardStatus.available ||
                  status == DailyRewardStatus.streakBroken ||
                  status == DailyRewardStatus.cycleCompleted);
          // claimedThisCycle=true only when Day 7 was just claimed (currentDay stays at 7).
          // For days 1–6, currentDay advances to N+1 after claim, so checking day==currentDay
          // without claimedThisCycle would mark the *next* unclaimed day as claimed.
          final isClaimed = day < effectiveDay ||
              (status == DailyRewardStatus.alreadyClaimed &&
                  day == dailyState.currentDay &&
                  dailyState.claimedThisCycle) ||
              (status == DailyRewardStatus.cycleCompleted);

          DayTileState tileState;
          if (isClaimed) {
            tileState = DayTileState.claimed;
          } else if (isCurrent) {
            tileState = DayTileState.currentAvailable;
          } else {
            tileState = DayTileState.future;
          }

          Widget tile = DailyRewardDayTile(
            day: day,
            reward: reward,
            tileState: tileState,
            isDay7: day == 7,
            width: tileW,
            height: tileH,
          );

          if (animatingDay == day) {
            tile = tile
                .animate()
                .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 200.ms)
                .then()
                .scale(begin: const Offset(1.3, 1.3), end: const Offset(1, 1), duration: 200.ms)
                .fadeOut(delay: 300.ms, duration: 200.ms);
          }

          return tile;
        }

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [1, 2, 3, 4].map(buildTile).toList(),
            ),
            SizedBox(height: spacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [5, 6, 7].map(buildTile).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _ClaimButton extends StatelessWidget {
  final DailyRewardStatus status;
  final VoidCallback onPressed;

  const _ClaimButton({required this.status, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final label = status == DailyRewardStatus.cycleCompleted
        ? 'Iniciar novo ciclo'
        : 'Coletar';
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(label, style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _CountdownWidget extends StatelessWidget {
  final Duration countdown;
  final String Function(Duration) formatter;

  const _CountdownWidget({required this.countdown, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Volte amanhã',
          style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 18),
        ),
        Text(
          formatter(countdown),
          style: GoogleFonts.fredoka(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
