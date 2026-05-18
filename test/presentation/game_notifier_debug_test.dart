import 'dart:math';
import 'package:capivara_2048/data/models/inventory.dart';
import 'package:capivara_2048/data/models/tile.dart';
import 'package:capivara_2048/data/repositories/inventory_repository.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:capivara_2048/presentation/controllers/personal_records_notifier.dart';
import 'package:capivara_2048/presentation/controllers/settings_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePersonalRecordsNotifier extends PersonalRecordsNotifier {
  @override
  Future<void> updateHighestLevel(int level) async {}
  @override
  Future<void> recordMilestone(int level, DateTime reachedAt) async {}
}

class _FakePrefs implements SharedPreferences {
  @override
  bool? getBool(String key) => null;
  @override
  Future<bool> setBool(String key, bool value) async => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeInventoryRepository implements InventoryRepository {
  @override
  Future<Inventory> load() async => Inventory.empty();
  @override
  Future<void> save(Inventory inventory) async {}
}

ProviderContainer _createContainer() {
  SharedPreferences.setMockInitialValues({});
  return ProviderContainer(
    overrides: [
      personalRecordsProvider.overrideWith(
          () => _FakePersonalRecordsNotifier()),
      sharedPreferencesProvider.overrideWithValue(_FakePrefs()),
      inventoryRepositoryProvider
          .overrideWithValue(_FakeInventoryRepository()),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('debugJumpToLevel', () {
    late ProviderContainer container;

    setUp(() => container = _createContainer());
    tearDown(() => container.dispose());

    test('sets maxLevel to target', () {
      container.read(gameProvider.notifier).debugJumpToLevel(7);
      expect(container.read(gameProvider).maxLevel, 7);
    });

    test('board contains tile at targetLevel', () {
      container.read(gameProvider.notifier).debugJumpToLevel(7);
      final board = container.read(gameProvider).board;
      final levels = board
          .expand((row) => row)
          .whereType<Tile>()
          .map((t) => t.level)
          .toList();
      expect(levels, contains(7));
    });

    test('score equals sum of (1 << tile.level) for all tiles', () {
      container.read(gameProvider.notifier).debugJumpToLevel(5);
      final state = container.read(gameProvider);
      final expected = state.board
          .expand((row) => row)
          .whereType<Tile>()
          .fold(0, (sum, t) => sum + (1 << t.level));
      expect(state.score, expected);
    });

    test('isPaused is false after jump', () {
      container.read(gameProvider.notifier).debugJumpToLevel(3);
      expect(container.read(gameProvider).isPaused, false);
    });

    test('isGameOver is false after jump', () {
      container.read(gameProvider.notifier).debugJumpToLevel(11);
      expect(container.read(gameProvider).isGameOver, false);
    });

    test('all tile levels >= 1 for targetLevel 1', () {
      container.read(gameProvider.notifier).debugJumpToLevel(1);
      final board = container.read(gameProvider).board;
      final levels = board
          .expand((row) => row)
          .whereType<Tile>()
          .map((t) => t.level)
          .toList();
      expect(levels.every((l) => l >= 1), true);
    });
  });
}
