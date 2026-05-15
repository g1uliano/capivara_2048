// lib/core/utils/iap_delivery.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/item_type.dart';
import '../../data/models/shop_package.dart';
import '../../domain/inventory/inventory_notifier.dart';
import '../../domain/lives/lives_notifier.dart';

/// Delivers IAP package items to local Riverpod state after a successful purchase.
///
/// Used by ShopScreen, ShopUnitItemCard, and ShopOverlay to avoid code duplication.
/// Does NOT handle share codes — each caller manages that separately.
void deliverIAPItems(WidgetRef ref, ShopPackage package) {
  final c = package.contents;
  if (c.lives > 0) {
    unawaited(ref.read(livesProvider.notifier).addPurchased(c.lives));
  }
  if (c.bomb2 > 0) {
    unawaited(
      ref.read(inventoryProvider.notifier).add(ItemType.bomb2, c.bomb2),
    );
  }
  if (c.bomb3 > 0) {
    unawaited(
      ref.read(inventoryProvider.notifier).add(ItemType.bomb3, c.bomb3),
    );
  }
  if (c.undo1 > 0) {
    unawaited(
      ref.read(inventoryProvider.notifier).add(ItemType.undo1, c.undo1),
    );
  }
  if (c.undo3 > 0) {
    unawaited(
      ref.read(inventoryProvider.notifier).add(ItemType.undo3, c.undo3),
    );
  }
}

/// Delivers a RewardBundle directly to local Riverpod state.
///
/// Used by RedeemCodeScreen to deliver gift code rewards after successful redemption.
/// Parallel to deliverIAPItems but accepts a RewardBundle instead of ShopPackage.
void deliverRewardBundle(WidgetRef ref, RewardBundle bundle) {
  if (bundle.lives > 0) {
    unawaited(ref.read(livesProvider.notifier).addPurchased(bundle.lives));
  }
  if (bundle.bomb2 > 0) {
    unawaited(
      ref.read(inventoryProvider.notifier).add(ItemType.bomb2, bundle.bomb2),
    );
  }
  if (bundle.bomb3 > 0) {
    unawaited(
      ref.read(inventoryProvider.notifier).add(ItemType.bomb3, bundle.bomb3),
    );
  }
  if (bundle.undo1 > 0) {
    unawaited(
      ref.read(inventoryProvider.notifier).add(ItemType.undo1, bundle.undo1),
    );
  }
  if (bundle.undo3 > 0) {
    unawaited(
      ref.read(inventoryProvider.notifier).add(ItemType.undo3, bundle.undo3),
    );
  }
}
