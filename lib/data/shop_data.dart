// lib/data/shop_data.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/item_type.dart';
import 'models/shop_package.dart';

final shopPackagesProvider = Provider<List<ShopPackage>>((_) => kShopPackages);

const List<ShopPackage> kShopPackages = [
  ShopPackage(
    id: 'p1',
    name: '4× Bomba 3',
    description: '4 bombas que explodem 3 casas',
    originalPrice: 7.99,
    currentPrice: 3.99,
    discountPercent: 50,
    contents: RewardBundle(lives: 0, bomb2: 0, bomb3: 4, undo1: 0, undo3: 0),
    giftContents: RewardBundle(
      lives: 0,
      bomb2: 0,
      bomb3: 2,
      undo1: 0,
      undo3: 0,
    ),
  ),
  ShopPackage(
    id: 'p2',
    name: '4× Desfazer 3',
    description: '4 desfazeres de 3 jogadas',
    originalPrice: 3.99,
    currentPrice: 1.99,
    discountPercent: 50,
    contents: RewardBundle(lives: 0, bomb2: 0, bomb3: 0, undo1: 0, undo3: 4),
    giftContents: RewardBundle(
      lives: 0,
      bomb2: 0,
      bomb3: 0,
      undo1: 0,
      undo3: 2,
    ),
  ),
  ShopPackage(
    id: 'p3',
    name: '6 Vidas',
    description: 'Direto no inventário',
    originalPrice: 9.99,
    currentPrice: 2.49,
    discountPercent: 75,
    contents: RewardBundle(lives: 6, bomb2: 0, bomb3: 0, undo1: 0, undo3: 0),
    giftContents: RewardBundle(
      lives: 3,
      bomb2: 0,
      bomb3: 0,
      undo1: 0,
      undo3: 0,
    ),
  ),
  ShopPackage(
    id: 'p4',
    name: '10 Vidas',
    description: 'Direto no inventário',
    originalPrice: 19.99,
    currentPrice: 4.99,
    discountPercent: 75,
    contents: RewardBundle(lives: 10, bomb2: 0, bomb3: 0, undo1: 0, undo3: 0),
    giftContents: RewardBundle(
      lives: 5,
      bomb2: 0,
      bomb3: 0,
      undo1: 0,
      undo3: 0,
    ),
  ),
  ShopPackage(
    id: 'p5',
    name: 'Combo Mata Atlântica',
    description: '6 vidas + 2 Bomba 2 + 2 Desfazer 3',
    originalPrice: 10.99,
    currentPrice: 4.99,
    discountPercent: 50,
    contents: RewardBundle(lives: 6, bomb2: 2, bomb3: 0, undo1: 0, undo3: 2),
    giftContents: RewardBundle(
      lives: 3,
      bomb2: 1,
      bomb3: 0,
      undo1: 0,
      undo3: 1,
    ),
  ),
  ShopPackage(
    id: 'p6',
    name: 'Combo Floresta Amazônica',
    description: '10 vidas + 4 Bomba 3 + 4 Desfazer 3',
    originalPrice: 31.99,
    currentPrice: 9.99,
    discountPercent: 50,
    contents: RewardBundle(lives: 10, bomb2: 0, bomb3: 4, undo1: 0, undo3: 4),
    giftContents: RewardBundle(
      lives: 5,
      bomb2: 0,
      bomb3: 2,
      undo1: 0,
      undo3: 2,
    ),
  ),
];

const Map<ItemType, double> kItemUnitPrices = {
  ItemType.bomb3: 1.99,
  ItemType.undo3: 0.99,
  ItemType.bomb2: 1.19,
  ItemType.undo1: 0.49,
};

const List<ShopPackage> kShopUnitPackages = [
  ShopPackage(
    id: 'u_bomb3',
    name: '1× Bomba 3',
    description: '1 bomba que remove 3 peças à sua escolha',
    originalPrice: 1.99,
    currentPrice: 1.99,
    discountPercent: 0,
    contents: RewardBundle(lives: 0, bomb2: 0, bomb3: 1, undo1: 0, undo3: 0),
    giftContents: RewardBundle(
      lives: 0,
      bomb2: 0,
      bomb3: 0,
      undo1: 0,
      undo3: 0,
    ),
  ),
  ShopPackage(
    id: 'u_undo3',
    name: '1× Desfazer 3',
    description: '1 desfazer de 3 jogadas',
    originalPrice: 0.99,
    currentPrice: 0.99,
    discountPercent: 0,
    contents: RewardBundle(lives: 0, bomb2: 0, bomb3: 0, undo1: 0, undo3: 1),
    giftContents: RewardBundle(
      lives: 0,
      bomb2: 0,
      bomb3: 0,
      undo1: 0,
      undo3: 0,
    ),
  ),
  ShopPackage(
    id: 'u_bomb2',
    name: '1× Bomba 2',
    description: '1 bomba que remove 2 peças adjacentes',
    originalPrice: 1.19,
    currentPrice: 1.19,
    discountPercent: 0,
    contents: RewardBundle(lives: 0, bomb2: 1, bomb3: 0, undo1: 0, undo3: 0),
    giftContents: RewardBundle(
      lives: 0,
      bomb2: 0,
      bomb3: 0,
      undo1: 0,
      undo3: 0,
    ),
  ),
  ShopPackage(
    id: 'u_undo1',
    name: '1× Desfazer 1',
    description: '1 desfazer de 1 jogada',
    originalPrice: 0.49,
    currentPrice: 0.49,
    discountPercent: 0,
    contents: RewardBundle(lives: 0, bomb2: 0, bomb3: 0, undo1: 1, undo3: 0),
    giftContents: RewardBundle(
      lives: 0,
      bomb2: 0,
      bomb3: 0,
      undo1: 0,
      undo3: 0,
    ),
  ),
];

/// Convenience map: ItemType → unit ShopPackage.
/// Use for single-item purchases in ShopUnitItemCard and ShopOverlay.
final Map<ItemType, ShopPackage> kUnitPackageByType = {
  ItemType.bomb3: kShopUnitPackages[0],
  ItemType.undo3: kShopUnitPackages[1],
  ItemType.bomb2: kShopUnitPackages[2],
  ItemType.undo1: kShopUnitPackages[3],
};

/// Retorna os IDs dos pacotes que contêm ao menos 1 unidade de [item].
List<String> packageIdsContaining(ItemType item) {
  return kShopPackages
      .where((pkg) {
        final c = pkg.contents;
        return switch (item) {
          ItemType.bomb2 => c.bomb2 > 0,
          ItemType.bomb3 => c.bomb3 > 0,
          ItemType.undo1 => c.undo1 > 0,
          ItemType.undo3 => c.undo3 > 0,
        };
      })
      .map((pkg) => pkg.id)
      .toList();
}
