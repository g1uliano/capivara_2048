import 'item_type.dart';

class Inventory {
  final int bomb2;
  final int bomb3;
  final int undo1;
  final int undo3;

  const Inventory({
    required this.bomb2,
    required this.bomb3,
    required this.undo1,
    required this.undo3,
  });

  factory Inventory.empty() =>
      const Inventory(bomb2: 0, bomb3: 0, undo1: 0, undo3: 0);

  int count(ItemType type) {
    switch (type) {
      case ItemType.bomb2:
        return bomb2;
      case ItemType.bomb3:
        return bomb3;
      case ItemType.undo1:
        return undo1;
      case ItemType.undo3:
        return undo3;
    }
  }

  Inventory copyWith({int? bomb2, int? bomb3, int? undo1, int? undo3}) {
    return Inventory(
      bomb2: bomb2 ?? this.bomb2,
      bomb3: bomb3 ?? this.bomb3,
      undo1: undo1 ?? this.undo1,
      undo3: undo3 ?? this.undo3,
    );
  }

  Inventory add(ItemType type, int amount) {
    switch (type) {
      case ItemType.bomb2:
        return copyWith(bomb2: bomb2 + amount);
      case ItemType.bomb3:
        return copyWith(bomb3: bomb3 + amount);
      case ItemType.undo1:
        return copyWith(undo1: undo1 + amount);
      case ItemType.undo3:
        return copyWith(undo3: undo3 + amount);
    }
  }

  Inventory consume(ItemType type) {
    final current = count(type);
    if (current <= 0) return this;
    return add(type, -1);
  }

  @override
  bool operator ==(Object other) =>
      other is Inventory &&
      other.bomb2 == bomb2 &&
      other.bomb3 == bomb3 &&
      other.undo1 == undo1 &&
      other.undo3 == undo3;

  @override
  int get hashCode => Object.hash(bomb2, bomb3, undo1, undo3);
}
