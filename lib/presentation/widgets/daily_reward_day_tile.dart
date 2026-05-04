import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/daily_rewards/daily_rewards_engine.dart';

enum DayTileState { future, currentAvailable, claimed }

class DailyRewardDayTile extends StatelessWidget {
  final int day;
  final DailyReward reward;
  final DayTileState tileState;
  final bool isDay7;
  final double width;
  final double height;

  const DailyRewardDayTile({
    super.key,
    required this.day,
    required this.reward,
    required this.tileState,
    required this.isDay7,
    this.width = 64,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = tileState == DayTileState.currentAvailable;
    final isClaimed = tileState == DayTileState.claimed;

    return Container(
      width: width,
      height: height,
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (width * 0.17).clamp(11, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _RewardIcons(reward: reward, iconSize: (width * 0.28).clamp(18, 28)),
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
  final double iconSize;
  const _RewardIcons({required this.reward, this.iconSize = 18});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (reward.undo1 > 0) {
      items.add(_icon('assets/images/inventory/undo_1.png', reward.undo1, iconSize));
    }
    if (reward.bomb2 > 0) {
      items.add(_icon('assets/images/inventory/bomb_2.png', reward.bomb2, iconSize));
    }
    if (reward.lives > 0) {
      items.add(_liveIcon(reward.lives, iconSize));
    }
    return Wrap(
      spacing: 2,
      children: items,
    );
  }

  Widget _icon(String asset, int count, double size) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(asset, width: size, height: size),
          if (count > 1)
            Text('×$count', style: TextStyle(color: Colors.white, fontSize: size * 0.55)),
        ],
      );

  Widget _liveIcon(int count, double size) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, color: Colors.redAccent, size: size),
          if (count > 1)
            Text('×$count', style: TextStyle(color: Colors.white, fontSize: size * 0.55)),
        ],
      );
}
