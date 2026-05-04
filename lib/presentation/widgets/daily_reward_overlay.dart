import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/daily_rewards/ad_service.dart';
import '../../domain/daily_rewards/daily_rewards_engine.dart';
import '../../domain/daily_rewards/daily_rewards_notifier.dart';

class DailyRewardOverlay extends ConsumerStatefulWidget {
  final DailyReward reward;
  final VoidCallback onDismiss;

  const DailyRewardOverlay({
    super.key,
    required this.reward,
    required this.onDismiss,
  });

  @override
  ConsumerState<DailyRewardOverlay> createState() => _DailyRewardOverlayState();
}

class _DailyRewardOverlayState extends ConsumerState<DailyRewardOverlay> {
  bool _loading = false;
  bool _doubled = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A5F),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _doubled ? 'Recompensa dobrada!' : 'Recompensa coletada!',
                style: GoogleFonts.fredoka(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _RewardSummary(reward: widget.reward, doubled: _doubled),
              const SizedBox(height: 24),
              if (!_doubled) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _onDouble,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Assistir 30s e dobrar',
                            style: GoogleFonts.fredoka(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              TextButton(
                onPressed: widget.onDismiss,
                child: Text(
                  'Não, obrigado',
                  style: GoogleFonts.nunito(color: Colors.white70, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onDouble() async {
    setState(() => _loading = true);
    final adService = ref.read(adServiceProvider);
    final success = await adService.showRewardedAd();
    if (!mounted) return;
    if (success) {
      await ref.read(dailyRewardsProvider.notifier).claimDouble(widget.reward);
      setState(() {
        _loading = false;
        _doubled = true;
      });
    } else {
      setState(() => _loading = false);
    }
  }
}

class _RewardSummary extends StatelessWidget {
  final DailyReward reward;
  final bool doubled;
  const _RewardSummary({required this.reward, required this.doubled});

  @override
  Widget build(BuildContext context) {
    final multiplier = doubled ? 2 : 1;
    final items = <Widget>[];
    if (reward.undo1 > 0) {
      items.add(_row('assets/images/inventory/undo_1.png', '${reward.undo1 * multiplier}× Desfazer 1'));
    }
    if (reward.bomb2 > 0) {
      items.add(_row('assets/images/inventory/bomb_2.png', '${reward.bomb2 * multiplier}× Bomba 2'));
    }
    if (reward.lives > 0) {
      items.add(_rowIcon(Icons.favorite, Colors.redAccent, '${reward.lives * multiplier}× Vida'));
    }
    return Column(children: items);
  }

  Widget _row(String asset, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Image.asset(asset, width: 24, height: 24),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
          ],
        ),
      );

  Widget _rowIcon(IconData icon, Color color, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
          ],
        ),
      );
}
