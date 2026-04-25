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
}
