import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../data/models/inventory.dart';
import '../../data/models/item_type.dart';
import '../../data/repositories/inventory_repository.dart';

class InventoryNotifier extends Notifier<Inventory> {
  StreamSubscription<BoxEvent>? _boxSub;

  @override
  Inventory build() {
    ref.onDispose(() {
      _boxSub?.cancel();
    });
    return Inventory.empty();
  }

  Future<void> load() async {
    state = await ref.read(inventoryRepositoryProvider).load();
    // React to external Hive writes (IAP, ranking rewards, invite rewards).
    // Wrapped in runZonedGuarded: Hive.openBox() creates an orphaned rejected
    // completer.future internally when Hive is not initialized, which escapes
    // our try-catch as an unhandled zone error. runZonedGuarded absorbs it.
    Box<Inventory>? box;
    await runZonedGuarded<Future<void>>(
      () async { box = await Hive.openBox<Inventory>('inventory'); },
      (_, _) {}, // absorb orphaned Hive-internal Future rejections
    );
    if (box != null) {
      await _boxSub?.cancel();
      _boxSub = box!.watch(key: 'data').listen(
        (event) {
          final updated = event.value as Inventory?;
          if (updated != null) state = updated;
        },
        onError: (_) {},
        cancelOnError: false,
      );
    }
  }

  Future<void> consume(ItemType type) async {
    state = state.consume(type);
    await ref.read(inventoryRepositoryProvider).save(state);
  }

  Future<void> add(ItemType type, int amount) async {
    assert(amount > 0, 'amount must be positive; use consume() to decrease');
    state = state.add(type, amount);
    await ref.read(inventoryRepositoryProvider).save(state);
  }

  int count(ItemType type) => state.count(type);

  void addDebugItems() {
    if (!kDebugMode) return;
    state = const Inventory(bomb2: 5, bomb3: 5, undo1: 5, undo3: 5);
  }

  @visibleForTesting
  void setStateForTest(Inventory inventory) => state = inventory;

  @visibleForTesting
  void debugSetState(Inventory s) => state = s;
}

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepository(),
);

final inventoryProvider = NotifierProvider<InventoryNotifier, Inventory>(
  InventoryNotifier.new,
);
