import 'package:hive/hive.dart';
import '../models/inventory.dart';

class InventoryRepository {
  static const _boxName = 'inventory';

  Future<Inventory> load() async {
    final box = await Hive.openBox<Inventory>(_boxName);
    return box.get('data') ?? Inventory.empty();
  }

  Future<void> save(Inventory inventory) async {
    final box = await Hive.openBox<Inventory>(_boxName);
    await box.put('data', inventory);
  }
}
