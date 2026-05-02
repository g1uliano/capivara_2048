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

  RewardBundle copyWith({int? lives, int? bomb2, int? bomb3, int? undo1, int? undo3}) {
    return RewardBundle(
      lives: lives ?? this.lives,
      bomb2: bomb2 ?? this.bomb2,
      bomb3: bomb3 ?? this.bomb3,
      undo1: undo1 ?? this.undo1,
      undo3: undo3 ?? this.undo3,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RewardBundle &&
      other.lives == lives &&
      other.bomb2 == bomb2 &&
      other.bomb3 == bomb3 &&
      other.undo1 == undo1 &&
      other.undo3 == undo3;

  @override
  int get hashCode => Object.hash(lives, bomb2, bomb3, undo1, undo3);
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

  ShopPackage copyWith({
    String? id,
    String? name,
    String? description,
    double? originalPrice,
    double? currentPrice,
    int? discountPercent,
    RewardBundle? contents,
    RewardBundle? giftContents,
  }) {
    return ShopPackage(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      originalPrice: originalPrice ?? this.originalPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      contents: contents ?? this.contents,
      giftContents: giftContents ?? this.giftContents,
    );
  }

  @override
  bool operator ==(Object other) => other is ShopPackage && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
