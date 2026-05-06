// lib/data/models/pending_event_hive_adapter.dart

import 'package:hive/hive.dart';
import 'dart:convert';
import 'pending_event.dart';

class PendingEventHiveAdapter extends TypeAdapter<PendingEvent> {
  @override
  final int typeId = PendingEvent.hiveTypeId;

  @override
  PendingEvent read(BinaryReader reader) {
    final json = jsonDecode(reader.readString()) as Map<String, dynamic>;
    return PendingEvent.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, PendingEvent obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}
