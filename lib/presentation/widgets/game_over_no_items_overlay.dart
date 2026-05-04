import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/item_type.dart';
import '../../data/shop_data.dart';
import '../../domain/daily_rewards/ad_service.dart';
import '../../domain/inventory/inventory_notifier.dart';
import '../../domain/lives/lives_notifier.dart';
import '../../presentation/controllers/game_notifier.dart';
import 'outlined_text.dart';

String _pngFor(ItemType t) => switch (t) {
      ItemType.bomb2 => 'assets/images/inventory/bomb_2.png',
      ItemType.bomb3 => 'assets/images/inventory/bomb_3.png',
      ItemType.undo1 => 'assets/images/inventory/undo_1.png',
      ItemType.undo3 => 'assets/images/inventory/undo_3.png',
    };

String _nameFor(ItemType t) => switch (t) {
      ItemType.bomb2 => 'Bomba 2',
      ItemType.bomb3 => 'Bomba 3',
      ItemType.undo1 => 'Desfazer 1',
      ItemType.undo3 => 'Desfazer 3',
    };

String _descFor(ItemType t) => switch (t) {
      ItemType.bomb2 => 'Remove 2 casas adjacentes',
      ItemType.bomb3 => 'Remove 3 casas à sua escolha',
      ItemType.undo1 => 'Desfaz a última jogada',
      ItemType.undo3 => 'Desfaz as últimas 3 jogadas',
    };

class GameOverNoItemsOverlay extends ConsumerStatefulWidget {
  const GameOverNoItemsOverlay({super.key});

  @override
  ConsumerState<GameOverNoItemsOverlay> createState() =>
      _GameOverNoItemsOverlayState();
}

class _GameOverNoItemsOverlayState extends ConsumerState<GameOverNoItemsOverlay> {
  late final ItemType _drawnItem;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    const items = [ItemType.bomb2, ItemType.bomb3, ItemType.undo1, ItemType.undo3];
    _drawnItem = items[Random().nextInt(items.length)];
  }

  void _dismiss() {
    setState(() => _dismissed = true);
    // startContinueWithItem sinaliza que a partida continua (não vai para Game Over)
    ref.read(gameProvider.notifier).startContinueWithItem();
  }

  String get _price {
    final p = kItemUnitPrices[_drawnItem] ?? 0.0;
    return 'R\$ ${p.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Future<void> _watchAd() async {
    final adService = ref.read(adServiceProvider);
    final rewarded = await adService.showRewardedAd();
    if (!mounted) return;
    if (rewarded) {
      // fire-and-forget Hive persistence; state updates are synchronous
      unawaited(ref.read(livesProvider.notifier).recordAdWatched());
      unawaited(ref.read(inventoryProvider.notifier).add(_drawnItem, 1));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_nameFor(_drawnItem)} adicionado! Boa sorte! 🎉')),
      );
      _dismiss();
    }
  }

  Future<void> _confirmBuy() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar compra'),
        content: Text('Você receberá 1× ${_nameFor(_drawnItem)} por $_price'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar compra'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // fire-and-forget Hive persistence; state update is synchronous
    unawaited(ref.read(inventoryProvider.notifier).add(_drawnItem, 1));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_nameFor(_drawnItem)} adicionado! Boa sorte! 🎉')),
    );
    _dismiss();
  }

  Future<void> _confirmQuit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: const Text(
          'Tem certeza? Você perderá 1 vida e a partida será encerrada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    unawaited(ref.read(livesProvider.notifier).consume());
    setState(() => _dismissed = true);
    ref.read(gameProvider.notifier).confirmGameOver();
  }

  @override
  Widget build(BuildContext context) {
    final canWatchAd = ref.watch(livesProvider.select((s) => s.adWatchedToday < 40));

    if (_dismissed) return const SizedBox.shrink();

    return PopScope(
      canPop: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AbsorbPointer(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.6),
              child: const SizedBox.expand(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                OutlinedText(
                  text: 'Você não possui mais itens!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Fredoka',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                OutlinedText(
                  text: 'Mas você pode conseguir um agora:',
                  style: const TextStyle(fontSize: 16, fontFamily: 'Nunito'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Image.asset(_pngFor(_drawnItem), width: 100, height: 100)
                          .animate()
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.05, 1.05),
                            duration: 250.ms,
                            curve: Curves.easeOut,
                          )
                          .then()
                          .scale(
                            begin: const Offset(1.05, 1.05),
                            end: const Offset(1.0, 1.0),
                            duration: 150.ms,
                          ),
                      const SizedBox(height: 8),
                      Text(
                        _nameFor(_drawnItem),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3E2723),
                          fontFamily: 'Fredoka',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _descFor(_drawnItem),
                        style: const TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Nunito'),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          canWatchAd ? const Color(0xFFFF8C42) : Colors.grey,
                    ),
                    onPressed: canWatchAd ? _watchAd : null,
                    child: Text(
                      canWatchAd
                          ? '📺 Ver anúncio e receber ${_nameFor(_drawnItem)}'
                          : 'Limite diário atingido',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF3E2723),
                    ),
                    onPressed: _confirmBuy,
                    child: Text('🛒 Comprar ${_nameFor(_drawnItem)}  •  $_price'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _confirmQuit,
                  child: const Text(
                    'Encerrar partida',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }
}
