// lib/data/models/daily_rewards_state_adapter.dart
import 'package:hive/hive.dart';
import 'daily_rewards_state.dart';

class DailyRewardsStateAdapter extends TypeAdapter<DailyRewardsState> {
  @override
  final int typeId = 3;

  @override
  DailyRewardsState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyRewardsState(
      currentDay: (fields[0] as int?) ?? 1,
      lastClaimedDate: (fields[1] as DateTime?) ?? DateTime(1970),
      claimedThisCycle: (fields[2] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, DailyRewardsState obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.currentDay)
      ..writeByte(1)
      ..write(obj.lastClaimedDate)
      ..writeByte(2)
      ..write(obj.claimedThisCycle);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyRewardsStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
