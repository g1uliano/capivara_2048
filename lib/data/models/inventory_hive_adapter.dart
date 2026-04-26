import 'package:hive/hive.dart';
import 'inventory.dart';

class InventoryHiveAdapter extends TypeAdapter<Inventory> {
  @override
  final int typeId = 2;

  @override
  Inventory read(BinaryReader reader) {
    return Inventory(
      bomb2: reader.readInt(),
      bomb3: reader.readInt(),
      undo1: reader.readInt(),
      undo3: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Inventory obj) {
    writer.writeInt(obj.bomb2);
    writer.writeInt(obj.bomb3);
    writer.writeInt(obj.undo1);
    writer.writeInt(obj.undo3);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
