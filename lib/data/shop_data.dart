// lib/data/shop_data.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    giftContents: RewardBundle(lives: 0, bomb2: 0, bomb3: 2, undo1: 0, undo3: 0),
  ),
  ShopPackage(
    id: 'p2',
    name: '4× Desfazer 3',
    description: '4 desfazeres de 3 jogadas',
    originalPrice: 3.99,
    currentPrice: 1.99,
    discountPercent: 50,
    contents: RewardBundle(lives: 0, bomb2: 0, bomb3: 0, undo1: 0, undo3: 4),
    giftContents: RewardBundle(lives: 0, bomb2: 0, bomb3: 0, undo1: 0, undo3: 2),
  ),
  ShopPackage(
    id: 'p3',
    name: '6 Vidas',
    description: 'Direto no inventário',
    originalPrice: 9.99,
    currentPrice: 2.49,
    discountPercent: 75,
    contents: RewardBundle(lives: 6, bomb2: 0, bomb3: 0, undo1: 0, undo3: 0),
    giftContents: RewardBundle(lives: 3, bomb2: 0, bomb3: 0, undo1: 0, undo3: 0),
  ),
  ShopPackage(
    id: 'p4',
    name: '10 Vidas',
    description: 'Direto no inventário',
    originalPrice: 19.99,
    currentPrice: 4.99,
    discountPercent: 75,
    contents: RewardBundle(lives: 10, bomb2: 0, bomb3: 0, undo1: 0, undo3: 0),
    giftContents: RewardBundle(lives: 5, bomb2: 0, bomb3: 0, undo1: 0, undo3: 0),
  ),
  ShopPackage(
    id: 'p5',
    name: 'Combo Mata Atlântica',
    description: '6 vidas + 2 Bomba 2 + 2 Desfazer 3',
    originalPrice: 10.99,
    currentPrice: 4.99,
    discountPercent: 50,
    contents: RewardBundle(lives: 6, bomb2: 2, bomb3: 0, undo1: 0, undo3: 2),
    giftContents: RewardBundle(lives: 3, bomb2: 1, bomb3: 0, undo1: 0, undo3: 1),
  ),
  ShopPackage(
    id: 'p6',
    name: 'Combo Floresta Amazônica',
    description: '10 vidas + 4 Bomba 3 + 4 Desfazer 3',
    originalPrice: 31.99,
    currentPrice: 9.99,
    discountPercent: 50,
    contents: RewardBundle(lives: 10, bomb2: 0, bomb3: 4, undo1: 0, undo3: 4),
    giftContents: RewardBundle(lives: 5, bomb2: 0, bomb3: 2, undo1: 0, undo3: 2),
  ),
];
