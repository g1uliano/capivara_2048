import 'package:hive/hive.dart';
import 'personal_records.dart';

class PersonalRecordsHiveAdapter extends TypeAdapter<PersonalRecords> {
  @override
  final int typeId = PersonalRecords.hiveTypeId;

  @override
  PersonalRecords read(BinaryReader reader) {
    return PersonalRecords(
      timesReached2048: reader.readInt(),
      timesReached4096: reader.readInt(),
      timesReached8192: reader.readInt(),
      firstReached2048At: reader.readBool() ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) : null,
      firstReached4096At: reader.readBool() ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) : null,
      firstReached8192At: reader.readBool() ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) : null,
      rewardCollected4096: reader.readBool(),
      rewardCollected8192: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, PersonalRecords obj) {
    writer.writeInt(obj.timesReached2048);
    writer.writeInt(obj.timesReached4096);
    writer.writeInt(obj.timesReached8192);
    writer.writeBool(obj.firstReached2048At != null);
    if (obj.firstReached2048At != null) writer.writeInt(obj.firstReached2048At!.millisecondsSinceEpoch);
    writer.writeBool(obj.firstReached4096At != null);
    if (obj.firstReached4096At != null) writer.writeInt(obj.firstReached4096At!.millisecondsSinceEpoch);
    writer.writeBool(obj.firstReached8192At != null);
    if (obj.firstReached8192At != null) writer.writeInt(obj.firstReached8192At!.millisecondsSinceEpoch);
    writer.writeBool(obj.rewardCollected4096);
    writer.writeBool(obj.rewardCollected8192);
  }
}
