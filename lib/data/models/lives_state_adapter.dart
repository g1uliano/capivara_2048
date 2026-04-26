import 'package:hive/hive.dart';
import 'lives_state.dart';

class LivesStateAdapter extends TypeAdapter<LivesState> {
  @override
  final int typeId = 1;

  @override
  LivesState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LivesState(
      lives: fields[0] as int,
      maxLives: fields[1] as int,
      lastRegenAt: fields[2] as DateTime,
      adWatchedToday: fields[3] as int,
      adCounterResetAt: fields[4] as DateTime,
      userId: fields[5] as String?,
      lastSyncedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LivesState obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.lives)
      ..writeByte(1)
      ..write(obj.maxLives)
      ..writeByte(2)
      ..write(obj.lastRegenAt)
      ..writeByte(3)
      ..write(obj.adWatchedToday)
      ..writeByte(4)
      ..write(obj.adCounterResetAt)
      ..writeByte(5)
      ..write(obj.userId)
      ..writeByte(6)
      ..write(obj.lastSyncedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LivesStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
