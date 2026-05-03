import 'package:hive/hive.dart';
import 'game_record.dart';

class GameRecordHiveAdapter extends TypeAdapter<GameRecord> {
  @override
  final int typeId = GameRecord.hiveTypeId;

  @override
  GameRecord read(BinaryReader reader) {
    return GameRecord(
      playedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      elapsedMs: reader.readInt(),
      score: reader.readInt(),
      maxLevel: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, GameRecord obj) {
    writer.writeInt(obj.playedAt.millisecondsSinceEpoch);
    writer.writeInt(obj.elapsedMs);
    writer.writeInt(obj.score);
    writer.writeInt(obj.maxLevel);
  }
}
