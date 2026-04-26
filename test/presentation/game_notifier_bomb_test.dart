import 'package:capivara_2048/data/models/inventory.dart';
import 'package:capivara_2048/data/models/item_type.dart';
import 'package:capivara_2048/data/models/tile.dart';
import 'package:capivara_2048/data/repositories/inventory_repository.dart';
import 'package:capivara_2048/domain/game_engine/bomb_mode.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Stub that does nothing — avoids Hive initialisation in unit tests.
class _FakeInventoryRepository implements InventoryRepository {
  @override
  Future<Inventory> load() async => Inventory.empty();
  @override
  Future<void> save(Inventory inventory) async {}
}

ProviderContainer _makeContainer() => ProviderContainer(
      overrides: [
        inventoryRepositoryProvider
            .overrideWithValue(_FakeInventoryRepository()),
      ],
    );

void main() {
  group('GameNotifier bomb mode', () {
    late ProviderContainer container;

    setUp(() {
      container = _makeContainer();
    });

    tearDown(() => container.dispose());

    test('enterBombMode sets bombMode in state', () {
      final notifier = container.read(gameProvider.notifier);
      notifier.enterBombMode(BombMode.bomb2, ItemType.bomb2);
      expect(container.read(gameProvider).bombMode, BombMode.bomb2);
    });

    test('cancelBomb clears bombMode', () {
      final notifier = container.read(gameProvider.notifier);
      notifier.enterBombMode(BombMode.bomb3, ItemType.bomb3);
      notifier.cancelBomb();
      expect(container.read(gameProvider).bombMode, isNull);
    });

    test('selectBombTile auto-confirms when enough tiles selected', () {
      final notifier = container.read(gameProvider.notifier);

      // Set up board with 2 tiles for bomb2
      final board = List.generate(4, (r) => List<Tile?>.filled(4, null));
      board[0][0] = const Tile(id: 'a', level: 1, row: 0, col: 0);
      board[1][1] = const Tile(id: 'b', level: 2, row: 1, col: 1);
      notifier.state = container.read(gameProvider).copyWith(board: board);

      notifier.enterBombMode(BombMode.bomb2, ItemType.bomb2);
      notifier.selectBombTile(0, 0);
      // After 1 selection, still in bomb mode
      expect(container.read(gameProvider).bombMode, BombMode.bomb2);

      notifier.selectBombTile(1, 1);
      // After 2 selections, bomb2 auto-confirms
      expect(container.read(gameProvider).bombMode, isNull);
      expect(container.read(gameProvider).board[0][0], isNull);
      expect(container.read(gameProvider).board[1][1], isNull);
    });

    test('selectBombTile toggles deselection', () {
      final notifier = container.read(gameProvider.notifier);

      final board = List.generate(4, (r) => List<Tile?>.filled(4, null));
      board[0][0] = const Tile(id: 'a', level: 1, row: 0, col: 0);
      board[0][1] = const Tile(id: 'b', level: 2, row: 0, col: 1);
      board[0][2] = const Tile(id: 'c', level: 3, row: 0, col: 2);
      notifier.state = container.read(gameProvider).copyWith(board: board);

      notifier.enterBombMode(BombMode.bomb3, ItemType.bomb3);
      notifier.selectBombTile(0, 0);
      expect(notifier.bombSelection, contains((0, 0)));

      // Deselect same tile
      notifier.selectBombTile(0, 0);
      expect(notifier.bombSelection, isNot(contains((0, 0))));
    });

    test('bomb3 requires 3 tiles before confirming', () {
      final notifier = container.read(gameProvider.notifier);

      final board = List.generate(4, (r) => List<Tile?>.filled(4, null));
      board[0][0] = const Tile(id: 'a', level: 1, row: 0, col: 0);
      board[0][1] = const Tile(id: 'b', level: 2, row: 0, col: 1);
      board[0][2] = const Tile(id: 'c', level: 3, row: 0, col: 2);
      notifier.state = container.read(gameProvider).copyWith(board: board);

      notifier.enterBombMode(BombMode.bomb3, ItemType.bomb3);
      notifier.selectBombTile(0, 0);
      notifier.selectBombTile(0, 1);
      // Still in bomb mode after 2 tiles
      expect(container.read(gameProvider).bombMode, BombMode.bomb3);

      notifier.selectBombTile(0, 2);
      // Auto-confirms after 3 tiles
      expect(container.read(gameProvider).bombMode, isNull);
      expect(container.read(gameProvider).board[0][0], isNull);
      expect(container.read(gameProvider).board[0][1], isNull);
      expect(container.read(gameProvider).board[0][2], isNull);
    });

    test('confirmBomb with empty selection does not leave bombMode active', () {
      final notifier = container.read(gameProvider.notifier);
      notifier.enterBombMode(BombMode.bomb2, ItemType.bomb2);
      expect(container.read(gameProvider).bombMode, BombMode.bomb2);
      // confirm without selecting any tiles
      notifier.confirmBomb();
      expect(container.read(gameProvider).bombMode, isNull);
    });
  });
}
