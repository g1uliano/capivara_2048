import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/game_constants.dart';
import 'host_banner.dart';
import 'lives_indicator.dart';
import 'pause_button_tile.dart';
import 'status_panel.dart';

class GameHeader extends ConsumerWidget {
  final VoidCallback onPauseTap;

  const GameHeader({super.key, required this.onPauseTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const tileSize = GameConstants.tileSize;
    const slotWidth = GameConstants.twoCellWidth;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LivesIndicator(),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              flex: 2,
              child: HostBanner(),
            ),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const StatusPanel(),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: slotWidth,
                    height: tileSize,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: PauseButtonTile(
                        tileSize: tileSize,
                        onTap: onPauseTap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}
