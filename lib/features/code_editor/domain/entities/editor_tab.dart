class EditorTab {
  final String filePath;
  final String fileName;
  final String content;
  final String savedContent;
  final int cursorOffset;
  final double scrollOffset;

  EditorTab({
    required this.filePath,
    required this.fileName,
    required this.content,
    String? savedContent,
    this.cursorOffset = 0,
    this.scrollOffset = 0.0,
  }) : savedContent = savedContent ?? content;

  /// Computed dirty state based on debounced content diffing against savedContent baseline.
  bool get isDirty => content != savedContent;

  EditorTab copyWith({
    String? content,
    String? savedContent,
    int? cursorOffset,
    double? scrollOffset,
  }) {
    return EditorTab(
      filePath: filePath,
      fileName: fileName,
      content: content ?? this.content,
      savedContent: savedContent ?? this.savedContent,
      cursorOffset: cursorOffset ?? this.cursorOffset,
      scrollOffset: scrollOffset ?? this.scrollOffset,
    );
  }
}
