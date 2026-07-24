class FileNode {
  final String path;
  final String name;
  final bool isDirectory;
  final List<FileNode> children;
  final int sizeBytes;
  final bool isExpanded;
  final bool isLoaded;

  const FileNode({
    required this.path,
    required this.name,
    required this.isDirectory,
    this.children = const [],
    this.sizeBytes = 0,
    this.isExpanded = false,
    this.isLoaded = false,
  });

  FileNode copyWith({
    String? path,
    String? name,
    bool? isDirectory,
    List<FileNode>? children,
    int? sizeBytes,
    bool? isExpanded,
    bool? isLoaded,
  }) {
    return FileNode(
      path: path ?? this.path,
      name: name ?? this.name,
      isDirectory: isDirectory ?? this.isDirectory,
      children: children ?? this.children,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      isExpanded: isExpanded ?? this.isExpanded,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}
