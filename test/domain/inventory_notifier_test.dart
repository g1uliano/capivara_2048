import 'package:capivara_2048/data/models/inventory.dart';
import 'package:capivara_2048/data/models/inventory_hive_adapter.dart';
import 'package:capivara_2048/data/models/item_type.dart';
import 'package:capivara_2048/data/repositories/inventory_repository.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(InventoryHiveAdapter());
    }
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('Inventory model', () {
    test('empty() creates all zeros', () {
      final inv = Inventory.empty();
      expect(inv.bomb2, 0);
      expect(inv.bomb3, 0);
      expect(inv.undo1, 0);
      expect(inv.undo3, 0);
    });

    test('consume floors at 0', () {
      final inv = Inventory.empty();
      final result = inv.consume(ItemType.bomb2);
      expect(result.bomb2, 0);
    });

    test('add increases count', () {
      final inv = Inventory.empty().add(ItemType.undo1, 3);
      expect(inv.undo1, 3);
    });

    test('consume decreases count by 1', () {
      final inv = const Inventory(bomb2: 3, bomb3: 0, undo1: 0, undo3: 0);
      expect(inv.consume(ItemType.bomb2).bomb2, 2);
    });

    test('equality works', () {
      expect(Inventory.empty(), equals(Inventory.empty()));
      expect(
        const Inventory(bomb2: 1, bomb3: 0, undo1: 0, undo3: 0),
        isNot(equals(Inventory.empty())),
      );
    });
  });

  group('InventoryNotifier', () {
    test('consume decreases count and saves', () async {
      final repo = InventoryRepository();
      final notifier = InventoryNotifier(repo);
      notifier.state = const Inventory(bomb2: 2, bomb3: 0, undo1: 0, undo3: 0);
      await notifier.consume(ItemType.bomb2);
      expect(notifier.state.bomb2, 1);
    });

    test('consume at 0 does not go negative', () async {
      final repo = InventoryRepository();
      final notifier = InventoryNotifier(repo);
      await notifier.consume(ItemType.bomb3);
      expect(notifier.state.bomb3, 0);
    });

    test('add increases count and saves', () async {
      final repo = InventoryRepository();
      final notifier = InventoryNotifier(repo);
      await notifier.add(ItemType.undo3, 2);
      expect(notifier.state.undo3, 2);
    });

    test('load restores persisted inventory', () async {
      final repo = InventoryRepository();
      await repo.save(const Inventory(bomb2: 3, bomb3: 1, undo1: 0, undo3: 2));
      final notifier = InventoryNotifier(repo);
      await notifier.load();
      expect(notifier.state.bomb2, 3);
      expect(notifier.state.undo3, 2);
    });
  });
}
