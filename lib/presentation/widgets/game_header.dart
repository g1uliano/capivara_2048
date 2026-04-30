import 'package:flutter/material.dart';
import '../../core/constants/game_constants.dart';
import 'host_banner.dart';
import 'lives_indicator.dart';
import 'pause_button_tile.dart';
import 'status_panel.dart';

class GameHeader extends StatelessWidget {
  final VoidCallback onPauseTap;

  const GameHeader({super.key, required this.onPauseTap});

  @override
  Widget build(BuildContext context) {
    const tileSize = GameConstants.tileSize;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: LivesIndicator()),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const HostBanner(),
            const Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const StatusPanel(),
                const SizedBox(height: 6),
                PauseButtonTile(
                  tileSize: tileSize,
                  onTap: onPauseTap,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}
