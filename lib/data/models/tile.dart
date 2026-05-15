class Tile {
  final String id;
  final int level;
  final int row;
  final int col;
  final bool isNew;
  final bool justMerged;

  const Tile({
    required this.id,
    required this.level,
    required this.row,
    required this.col,
    this.isNew = false,
    this.justMerged = false,
  });

  Tile copyWith({
    String? id,
    int? level,
    int? row,
    int? col,
    bool? isNew,
    bool? justMerged,
  }) {
    return Tile(
      id: id ?? this.id,
      level: level ?? this.level,
      row: row ?? this.row,
      col: col ?? this.col,
      isNew: isNew ?? this.isNew,
      justMerged: justMerged ?? this.justMerged,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'level': level,
    'row': row,
    'col': col,
  };

  factory Tile.fromJson(Map<String, dynamic> json) => Tile(
    id: json['id'] as String,
    level: json['level'] as int,
    row: json['row'] as int,
    col: json['col'] as int,
    // isNew and justMerged are animation flags — always false on restore
  );
}
