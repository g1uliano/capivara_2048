// lib/domain/sync/sync_conflict_resolver.dart

import '../../data/models/personal_records.dart';
import '../../data/models/inventory.dart';

/// Lógica de merge campo a campo entre estado local (Hive) e remoto (Firestore).
/// Dart puro — sem dependência de Flutter ou Firebase.
class SyncConflictResolver {
  SyncConflictResolver._();

  static PersonalRecords mergePersonalRecords(
    PersonalRecords local,
    PersonalRecords remote,
  ) {
    return PersonalRecords(
      timesReached2048: _max(local.timesReached2048, remote.timesReached2048),
      timesReached4096: _max(local.timesReached4096, remote.timesReached4096),
      timesReached8192: _max(local.timesReached8192, remote.timesReached8192),
      firstReached2048At: _oldest(
        local.firstReached2048At,
        remote.firstReached2048At,
      ),
      firstReached4096At: _oldest(
        local.firstReached4096At,
        remote.firstReached4096At,
      ),
      firstReached8192At: _oldest(
        local.firstReached8192At,
        remote.firstReached8192At,
      ),
      rewardCollected4096:
          local.rewardCollected4096 || remote.rewardCollected4096,
      rewardCollected8192:
          local.rewardCollected8192 || remote.rewardCollected8192,
      highestLevelEver: _max(local.highestLevelEver, remote.highestLevelEver),
      bestTimeMs2048: _minNonZero(local.bestTimeMs2048, remote.bestTimeMs2048),
    );
  }

  static Inventory mergeInventory(Inventory local, Inventory remote) {
    return Inventory(
      bomb2: _max(local.bomb2, remote.bomb2),
      bomb3: _max(local.bomb3, remote.bomb3),
      undo1: _max(local.undo1, remote.undo1),
      undo3: _max(local.undo3, remote.undo3),
    );
  }

  static int _max(int a, int b) => a > b ? a : b;

  /// Para tempos, menor é melhor. 0 significa "sem registro".
  static int _minNonZero(int a, int b) {
    if (a == 0) return b;
    if (b == 0) return a;
    return a < b ? a : b;
  }

  static DateTime? _oldest(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }
}
