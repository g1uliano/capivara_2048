import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/game_engine/direction.dart';

import '../../../data/models/item_type.dart';
import '../../controllers/game_notifier.dart';
import '../../widgets/board_widget.dart';
import '../../widgets/bomb_selection_overlay.dart';
import '../../widgets/bomb_grid_overlay.dart';
import '../../widgets/game_background.dart';
import '../../widgets/game_header.dart';
import '../../widgets/game_over_modal.dart';
import '../../widgets/inventory_bar.dart';
import '../../widgets/shop_overlay.dart';
import '../../widgets/victory_choice_dialog.dart';
import '../../../core/constants/game_constants.dart';
import '../../../domain/inventory/inventory_notifier.dart';
import '../../widgets/pause_overlay.dart';
import 'game_over_item_overlay.dart';
import '../../widgets/game_over_no_items_overlay.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  ItemType? _shopItem;
  Set<ItemType> _pulsingItems = {};

  void _openShop(ItemType type) {
    if (ref.read(gameProvider).pendingMilestone != null) return;
    ref.read(gameProvider.notifier).pause();
    setState(() => _shopItem = type);
  }

  void _closeShop() {
    setState(() => _shopItem = null);
    ref.read(gameProvider.notifier).resume();
  }

  void _onItemPurchased(ItemType type) {
    setState(() => _pulsingItems.add(type));
    Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _pulsingItems.remove(type));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final isGameOver = state.isGameOver;
    final hasWon = state.hasWon;
    final notifier = ref.read(gameProvider.notifier);
    final inventory = ref.watch(inventoryProvider);
    final hasAnyItem = inventory.bomb2 > 0 || inventory.bomb3 > 0 ||
        inventory.undo1 > 0 || inventory.undo3 > 0;

    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const headerH = 72.0;
              const inventoryH = 80.0; // inventoryIconSize (72) + SizedBox bottom (8)
              const verticalPad = 8.0;
              final boardSide = min(
                constraints.maxWidth - 24,
                constraints.maxHeight - headerH - inventoryH - verticalPad - GameConstants.boardToInventorySpacing,
              );
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        GameHeader(
                          onPauseTap: state.isPaused
                              ? notifier.resume
                              : notifier.pause,
                        ),
                        Expanded(
                          child: Center(
                            child: SizedBox(
                              width: boardSide,
                              height: boardSide,
                              child: Stack(
                                children: [
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onPanEnd: (details) {
                                      if (state.isPaused ||
                                          isGameOver ||
                                          hasWon ||
                                          state.bombMode != null) { return; }
                                      final v = details.velocity.pixelsPerSecond;
                                      const threshold = 100.0;
                                      if (v.dx.abs() > v.dy.abs()) {
                                        if (v.dx > threshold) {
                                          notifier.onSwipe(Direction.right);
                                        } else if (v.dx < -threshold) {
                                          notifier.onSwipe(Direction.left);
                                        }
                                      } else {
                                        if (v.dy > threshold) {
                                          notifier.onSwipe(Direction.down);
                                        } else if (v.dy < -threshold) {
                                          notifier.onSwipe(Direction.up);
                                        }
                                      }
                                    },
                                    child: RepaintBoundary(child: BoardWidget(size: boardSide)),
                                  ),
                                  if (state.bombMode != null)
                                    const Positioned.fill(child: BombGridOverlay()),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: GameConstants.boardToInventorySpacing),
                        AbsorbPointer(
                          absorbing: state.isAwaitingGameOverResolution,
                          child: InventoryBar(
                            onTapWhenEmpty: _openShop,
                            pulsingItems: _pulsingItems,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
              if (state.isPaused) const Positioned.fill(child: PauseOverlay()),
              if (state.bombMode != null)
                const Positioned.fill(child: BombDimOverlay()),
              if (state.isAwaitingGameOverResolution && hasAnyItem)
                const Positioned.fill(child: GameOverItemOverlay()),
              if (state.isAwaitingGameOverResolution && !hasAnyItem)
                const Positioned.fill(child: GameOverNoItemsOverlay()),
              if (isGameOver && !state.isAwaitingGameOverResolution && !state.isContinuingWithItem)
                const Positioned.fill(
                    child: GameOverModal(message: 'Game Over!')),
              if (hasWon && !isGameOver)
                const Positioned.fill(
                    child: GameOverModal(message: 'Capivara Lendária! 🎉')),
              if (state.pendingMilestone != null && !state.hasWon)
                Positioned.fill(
                  child: VictoryChoiceDialog(milestone: state.pendingMilestone!),
                ),
              if (_shopItem != null)
                Positioned.fill(child: ShopOverlay(
                  itemType: _shopItem!,
                  onClose: _closeShop,
                  onItemPurchased: _onItemPurchased,
                )),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
