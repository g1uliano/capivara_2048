import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/inventory.dart';
import '../../data/models/item_type.dart';
import '../../data/repositories/inventory_repository.dart';

class InventoryNotifier extends StateNotifier<Inventory> {
  InventoryNotifier(this._repo) : super(Inventory.empty());

  final InventoryRepository _repo;

  Future<void> load() async {
    state = await _repo.load();
  }

  Future<void> consume(ItemType type) async {
    state = state.consume(type);
    await _repo.save(state);
  }

  Future<void> add(ItemType type, int amount) async {
    state = state.add(type, amount);
    await _repo.save(state);
  }

  int count(ItemType type) => state.count(type);

  void addDebugItems() {
    state = const Inventory(bomb2: 5, bomb3: 5, undo1: 5, undo3: 5);
  }
}

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepository(),
);

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, Inventory>(
  (ref) => InventoryNotifier(ref.read(inventoryRepositoryProvider)),
);
