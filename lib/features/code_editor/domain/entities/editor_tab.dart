class EditorTab {
  final String filePath;
  final String fileName;
  final String content;
  final bool isDirty;
  final int cursorOffset;
  final double scrollOffset;

  EditorTab({
    required this.filePath,
    required this.fileName,
    required this.content,
    this.isDirty = false,
    this.cursorOffset = 0,
    this.scrollOffset = 0.0,
  });

  EditorTab copyWith({
    String? content,
    bool? isDirty,
    int? cursorOffset,
    double? scrollOffset,
  }) {
    return EditorTab(
      filePath: filePath,
      fileName: fileName,
      content: content ?? this.content,
      isDirty: isDirty ?? this.isDirty,
      cursorOffset: cursorOffset ?? this.cursorOffset,
      scrollOffset: scrollOffset ?? this.scrollOffset,
    );
  }
}
