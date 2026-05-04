import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/personal_records.dart';
import '../../data/models/personal_records_hive_adapter.dart';

class PersonalRecordsNotifier extends StateNotifier<PersonalRecords> {
  static const _boxName = 'personal_records';
  static const _key = 'records';

  PersonalRecordsNotifier() : super(const PersonalRecords());

  Future<void> load() async {
    if (!Hive.isAdapterRegistered(PersonalRecords.hiveTypeId)) {
      Hive.registerAdapter(PersonalRecordsHiveAdapter());
    }
    final box = await Hive.openBox<PersonalRecords>(_boxName);
    state = box.get(_key) ?? const PersonalRecords();
  }

  Future<void> _save() async {
    final box = await Hive.openBox<PersonalRecords>(_boxName);
    await box.put(_key, state);
  }

  Future<void> recordMilestone(int level, DateTime reachedAt) async {
    switch (level) {
      case 11:
        state = state.firstReached2048At == null
            ? state.copyWith(
                timesReached2048: state.timesReached2048 + 1,
                firstReached2048At: reachedAt,
              )
            : state.copyWith(timesReached2048: state.timesReached2048 + 1);
      case 12:
        state = state.firstReached4096At == null
            ? state.copyWith(
                timesReached4096: state.timesReached4096 + 1,
                firstReached4096At: reachedAt,
              )
            : state.copyWith(timesReached4096: state.timesReached4096 + 1);
      case 13:
        state = state.firstReached8192At == null
            ? state.copyWith(
                timesReached8192: state.timesReached8192 + 1,
                firstReached8192At: reachedAt,
              )
            : state.copyWith(timesReached8192: state.timesReached8192 + 1);
    }
    await _save();
  }

  bool isFirstTime(int level) {
    switch (level) {
      case 11: return state.timesReached2048 == 0;
      case 12: return state.timesReached4096 == 0;
      case 13: return state.timesReached8192 == 0;
      default: return false;
    }
  }

  Future<void> markRewardCollected(int level) async {
    if (level == 12) {
      state = state.copyWith(rewardCollected4096: true);
    } else if (level == 13) {
      state = state.copyWith(rewardCollected8192: true);
    }
    await _save();
  }

  Future<void> updateHighestLevel(int level) async {
    if (level > state.highestLevelEver) {
      state = state.copyWith(highestLevelEver: level);
      await _save();
    }
  }
}

final personalRecordsProvider =
    StateNotifierProvider<PersonalRecordsNotifier, PersonalRecords>(
  (ref) => PersonalRecordsNotifier(),
);
