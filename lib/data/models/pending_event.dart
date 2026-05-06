// lib/data/models/pending_event.dart

enum PendingEventType { legendReached, inventoryConsume }

class PendingEvent {
  static const int hiveTypeId = 11;

  final String id;
  final PendingEventType type;
  final Map<String, dynamic> payload;
  final DateTime occurredAt;

  const PendingEvent({
    required this.id,
    required this.type,
    required this.payload,
    required this.occurredAt,
  });

  factory PendingEvent.legendReached({
    required String id,
    required int level,
    required DateTime occurredAt,
  }) =>
      PendingEvent(
        id: id,
        type: PendingEventType.legendReached,
        payload: {'level': level},
        occurredAt: occurredAt,
      );

  PendingEvent copyWith({
    String? id,
    PendingEventType? type,
    Map<String, dynamic>? payload,
    DateTime? occurredAt,
  }) =>
      PendingEvent(
        id: id ?? this.id,
        type: type ?? this.type,
        payload: payload ?? this.payload,
        occurredAt: occurredAt ?? this.occurredAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'payload': payload,
        'occurredAt': occurredAt.toIso8601String(),
      };

  factory PendingEvent.fromJson(Map<String, dynamic> json) => PendingEvent(
        id: json['id'] as String,
        type: PendingEventType.values.byName(json['type'] as String),
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        occurredAt: DateTime.parse(json['occurredAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PendingEvent && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
