// lib/data/models/shop_package.dart

class RewardBundle {
  final int lives;
  final int bomb2;
  final int bomb3;
  final int undo1;
  final int undo3;

  const RewardBundle({
    required this.lives,
    required this.bomb2,
    required this.bomb3,
    required this.undo1,
    required this.undo3,
  });

  static const empty = RewardBundle(
    lives: 0, bomb2: 0, bomb3: 0, undo1: 0, undo3: 0,
  );
}

class ShopPackage {
  final String id;
  final String name;
  final String description;
  final double originalPrice;
  final double currentPrice;
  final int discountPercent;
  final RewardBundle contents;
  final RewardBundle giftContents;

  const ShopPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.originalPrice,
    required this.currentPrice,
    required this.discountPercent,
    required this.contents,
    required this.giftContents,
  });
}
