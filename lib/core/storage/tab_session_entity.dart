class TabSessionEntity {
  final String filePath;
  final String fileName;
  final int cursorOffset;
  final double scrollOffset;
  final bool isActive;
  final DateTime lastOpenedTimestamp;

  TabSessionEntity({
    required this.filePath,
    required this.fileName,
    this.cursorOffset = 0,
    this.scrollOffset = 0.0,
    this.isActive = false,
    DateTime? lastOpenedTimestamp,
  }) : lastOpenedTimestamp = lastOpenedTimestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'fileName': fileName,
        'cursorOffset': cursorOffset,
        'scrollOffset': scrollOffset,
        'isActive': isActive,
        'lastOpenedTimestamp': lastOpenedTimestamp.toIso8601String(),
      };

  factory TabSessionEntity.fromJson(Map<String, dynamic> json) => TabSessionEntity(
        filePath: json['filePath'] as String,
        fileName: json['fileName'] as String,
        cursorOffset: json['cursorOffset'] as int? ?? 0,
        scrollOffset: (json['scrollOffset'] as num? ?? 0.0).toDouble(),
        isActive: json['isActive'] as bool? ?? false,
        lastOpenedTimestamp: DateTime.parse(json['lastOpenedTimestamp'] as String),
      );
}
