import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/daily_rewards/daily_rewards_screen.dart';
import '../../domain/daily_rewards/daily_rewards_engine.dart';
import '../../domain/daily_rewards/daily_rewards_notifier.dart';

class DailyRewardEntryTile extends ConsumerWidget {
  const DailyRewardEntryTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyState = ref.watch(dailyRewardsProvider);
    final status = computeDailyRewardStatus(DateTime.now(), dailyState);
    final hasReward = status == DailyRewardStatus.available ||
        status == DailyRewardStatus.cycleCompleted;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DailyRewardsScreen()),
      ),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          children: [
            const Center(
              child: Icon(Icons.card_giftcard, color: Colors.white, size: 32),
            ),
            if (hasReward)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
