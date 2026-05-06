import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../data/models/inventory.dart';
import '../../data/models/item_type.dart';
import '../../data/repositories/inventory_repository.dart';

class InventoryNotifier extends StateNotifier<Inventory> {
  InventoryNotifier(this._repo) : super(Inventory.empty());

  final InventoryRepository _repo;
  StreamSubscription<BoxEvent>? _boxSub;

  Future<void> load() async {
    state = await _repo.load();
    // React to external Hive writes (IAP, ranking rewards, invite rewards)
    final box = await Hive.openBox<Inventory>('inventory');
    await _boxSub?.cancel();
    _boxSub = box.watch(key: 'data').listen((event) {
      final updated = event.value as Inventory?;
      if (updated != null && mounted) state = updated;
    });
  }

  Future<void> consume(ItemType type) async {
    state = state.consume(type);
    await _repo.save(state);
  }

  Future<void> add(ItemType type, int amount) async {
    assert(amount > 0, 'amount must be positive; use consume() to decrease');
    state = state.add(type, amount);
    await _repo.save(state);
  }

  int count(ItemType type) => state.count(type);

  void addDebugItems() {
    if (!kDebugMode) return;
    state = const Inventory(bomb2: 5, bomb3: 5, undo1: 5, undo3: 5);
  }

  @override
  void dispose() {
    _boxSub?.cancel();
    super.dispose();
  }

  @visibleForTesting
  void setStateForTest(Inventory inventory) => state = inventory;

  @visibleForTesting
  void debugSetState(Inventory s) => state = s;
}

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepository(),
);

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, Inventory>(
  (ref) => InventoryNotifier(ref.read(inventoryRepositoryProvider)),
);
