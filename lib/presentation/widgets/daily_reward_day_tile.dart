import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/daily_rewards/daily_rewards_engine.dart';

enum DayTileState { future, currentAvailable, claimed }

class DailyRewardDayTile extends StatelessWidget {
  final int day;
  final DailyReward reward;
  final DayTileState tileState;
  final bool isDay7;

  const DailyRewardDayTile({
    super.key,
    required this.day,
    required this.reward,
    required this.tileState,
    required this.isDay7,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = tileState == DayTileState.currentAvailable;
    final isClaimed = tileState == DayTileState.claimed;

    return Container(
      width: 64,
      height: 80,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDay7
              ? Colors.amber
              : isCurrent
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
          width: isDay7 || isCurrent ? 2.5 : 0,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Opacity(
        opacity: tileState == DayTileState.future ? 0.4 : 1.0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Dia $day',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _RewardIcons(reward: reward),
              ],
            ),
            if (isClaimed)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
              ),
          ],
        ),
      ),
    ).animate(target: isCurrent ? 1 : 0).shimmer(
          duration: 1500.ms,
          color: Colors.white24,
        );
  }
}

class _RewardIcons extends StatelessWidget {
  final DailyReward reward;
  const _RewardIcons({required this.reward});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (reward.undo1 > 0) {
      items.add(_icon('assets/icons/inventory/undo_1.png', reward.undo1));
    }
    if (reward.bomb2 > 0) {
      items.add(_icon('assets/icons/inventory/bomb_2.png', reward.bomb2));
    }
    if (reward.lives > 0) {
      items.add(_liveIcon(reward.lives));
    }
    return Wrap(
      spacing: 2,
      children: items,
    );
  }

  Widget _icon(String asset, int count) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(asset, width: 18, height: 18),
          if (count > 1)
            Text('×$count', style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      );

  Widget _liveIcon(int count) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite, color: Colors.redAccent, size: 18),
          if (count > 1)
            Text('×$count', style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      );
}
