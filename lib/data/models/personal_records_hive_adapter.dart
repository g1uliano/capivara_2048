import 'package:hive/hive.dart';
import 'personal_records.dart';

class PersonalRecordsHiveAdapter extends TypeAdapter<PersonalRecords> {
  @override
  final int typeId = PersonalRecords.hiveTypeId;

  @override
  PersonalRecords read(BinaryReader reader) {
    final numFields = reader.availableBytes;
    final timesReached2048 = reader.readInt();
    final timesReached4096 = reader.readInt();
    final timesReached8192 = reader.readInt();
    final has2048At = reader.readBool();
    final firstReached2048At = has2048At
        ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
        : null;
    final has4096At = reader.readBool();
    final firstReached4096At = has4096At
        ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
        : null;
    final has8192At = reader.readBool();
    final firstReached8192At = has8192At
        ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
        : null;
    final rewardCollected4096 = reader.readBool();
    final rewardCollected8192 = reader.readBool();
    final highestLevelEver = numFields > 0 ? reader.readInt() : 0;
    // Campo novo — verificar bytes restantes APÓS ler highestLevelEver
    final bestTimeMs2048 = reader.availableBytes > 0 ? reader.readInt() : 0;
    return PersonalRecords(
      timesReached2048: timesReached2048,
      timesReached4096: timesReached4096,
      timesReached8192: timesReached8192,
      firstReached2048At: firstReached2048At,
      firstReached4096At: firstReached4096At,
      firstReached8192At: firstReached8192At,
      rewardCollected4096: rewardCollected4096,
      rewardCollected8192: rewardCollected8192,
      highestLevelEver: highestLevelEver,
      bestTimeMs2048: bestTimeMs2048,
    );
  }

  @override
  void write(BinaryWriter writer, PersonalRecords obj) {
    writer.writeInt(obj.timesReached2048);
    writer.writeInt(obj.timesReached4096);
    writer.writeInt(obj.timesReached8192);
    writer.writeBool(obj.firstReached2048At != null);
    if (obj.firstReached2048At != null) {
      writer.writeInt(obj.firstReached2048At!.millisecondsSinceEpoch);
    }
    writer.writeBool(obj.firstReached4096At != null);
    if (obj.firstReached4096At != null) {
      writer.writeInt(obj.firstReached4096At!.millisecondsSinceEpoch);
    }
    writer.writeBool(obj.firstReached8192At != null);
    if (obj.firstReached8192At != null) {
      writer.writeInt(obj.firstReached8192At!.millisecondsSinceEpoch);
    }
    writer.writeBool(obj.rewardCollected4096);
    writer.writeBool(obj.rewardCollected8192);
    writer.writeInt(obj.highestLevelEver);
    writer.writeInt(obj.bestTimeMs2048); // NOVO
  }
}
