import 'package:flutter/material.dart';
import 'host_banner.dart';
import 'lives_indicator.dart';
import 'pause_button_tile.dart';
import 'status_panel.dart';

class GameHeader extends StatelessWidget {
  final VoidCallback onPauseTap;
  final double hostSize;
  final double livesIconSize;
  final double pauseSize;

  const GameHeader({
    super.key,
    required this.onPauseTap,
    required this.hostSize,
    required this.livesIconSize,
    required this.pauseSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: LivesIndicator(iconSize: livesIconSize)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            HostBanner(hostSize: hostSize),
            const Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const StatusPanel(),
                const SizedBox(height: 6),
                PauseButtonTile(
                  tileSize: pauseSize,
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
