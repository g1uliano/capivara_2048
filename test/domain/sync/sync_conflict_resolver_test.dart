import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/sync/sync_conflict_resolver.dart';
import 'package:capivara_2048/data/models/personal_records.dart';
import 'package:capivara_2048/data/models/inventory.dart';

void main() {
  group('SyncConflictResolver.mergePersonalRecords', () {
    test('highestLevelEver: max(local, remote) — remote maior', () {
      final local = const PersonalRecords().copyWith(highestLevelEver: 11);
      final remote = const PersonalRecords().copyWith(highestLevelEver: 12);
      final result = SyncConflictResolver.mergePersonalRecords(local, remote);
      expect(result.highestLevelEver, 12);
    });

    test('timesReached4096: maior vence — remote maior', () {
      final local = const PersonalRecords().copyWith(timesReached4096: 3);
      final remote = const PersonalRecords().copyWith(timesReached4096: 5);
      final result = SyncConflictResolver.mergePersonalRecords(local, remote);
      expect(result.timesReached4096, 5);
    });

    test('timesReached4096: maior vence — local maior', () {
      final local = const PersonalRecords().copyWith(timesReached4096: 7);
      final remote = const PersonalRecords().copyWith(timesReached4096: 2);
      final result = SyncConflictResolver.mergePersonalRecords(local, remote);
      expect(result.timesReached4096, 7);
    });

    test('timesReached8192: maior vence', () {
      final local = const PersonalRecords().copyWith(timesReached8192: 1);
      final remote = const PersonalRecords().copyWith(timesReached8192: 4);
      final result = SyncConflictResolver.mergePersonalRecords(local, remote);
      expect(result.timesReached8192, 4);
    });

    test('firstReached4096At: timestamp mais antigo vence', () {
      final older = DateTime(2024, 1, 1);
      final newer = DateTime(2025, 6, 1);
      final local = const PersonalRecords().copyWith(firstReached4096At: newer);
      final remote = const PersonalRecords().copyWith(firstReached4096At: older);
      final result = SyncConflictResolver.mergePersonalRecords(local, remote);
      expect(result.firstReached4096At, older);
    });

    test('firstReached4096At: null local, remote tem valor → remote vence', () {
      final remote = const PersonalRecords().copyWith(
        firstReached4096At: DateTime(2024, 3, 15),
      );
      final result = SyncConflictResolver.mergePersonalRecords(
          const PersonalRecords(), remote);
      expect(result.firstReached4096At, DateTime(2024, 3, 15));
    });

    test('firstReached4096At: local tem valor, remote null → local vence', () {
      final local = const PersonalRecords().copyWith(
        firstReached4096At: DateTime(2024, 3, 15),
      );
      final result = SyncConflictResolver.mergePersonalRecords(
          local, const PersonalRecords());
      expect(result.firstReached4096At, DateTime(2024, 3, 15));
    });

    test('highestLevelEver: max(local, remote) — local maior', () {
      final local = const PersonalRecords().copyWith(highestLevelEver: 11);
      final remote = const PersonalRecords().copyWith(highestLevelEver: 8);
      final result = SyncConflictResolver.mergePersonalRecords(local, remote);
      expect(result.highestLevelEver, 11);
    });

    test('timesReached2048: maior vence', () {
      final local = const PersonalRecords().copyWith(timesReached2048: 10);
      final remote = const PersonalRecords().copyWith(timesReached2048: 8);
      final result = SyncConflictResolver.mergePersonalRecords(local, remote);
      expect(result.timesReached2048, 10);
    });
  });

  group('SyncConflictResolver.mergeInventory', () {
    test('max por campo', () {
      const local = Inventory(bomb2: 1, bomb3: 5, undo1: 2, undo3: 0);
      const remote = Inventory(bomb2: 3, bomb3: 2, undo1: 2, undo3: 1);
      final result = SyncConflictResolver.mergeInventory(local, remote);
      expect(result.bomb2, 3);
      expect(result.bomb3, 5);
      expect(result.undo1, 2);
      expect(result.undo3, 1);
    });
  });
}
