import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';
import '../../features/project_explorer/domain/entities/file_node.dart';

/// Centralized service owning all filesystem I/O operations and directory watching.
/// No widget or state class should touch `dart:io` directly.
class FileSystemService {
  DirectoryWatcher? _watcher;
  StreamSubscription<WatchEvent>? _watcherSubscription;

  /// Lazily lists contents of a directory without recursively walking sub-directories.
  Future<List<FileNode>> listDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return [];

    final List<FileNode> nodes = [];
    try {
      final List<FileSystemEntity> entities = await dir.list().toList();

      for (final entity in entities) {
        final name = p.basename(entity.path);
        final isDir = entity is Directory;
        int size = 0;

        if (entity is File) {
          try {
            size = await entity.length();
          } catch (_) {}
        }

        nodes.add(FileNode(
          path: entity.path,
          name: name,
          isDirectory: isDir,
          children: const [],
          sizeBytes: size,
          isExpanded: false,
          isLoaded: !isDir, // Files are loaded, directories load lazily on expansion
        ));
      }

      // Sort directories first, then alphabetical
      nodes.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    } catch (e) {
      // System permissions or access error
    }
    return nodes;
  }

  /// Create a new empty file at [parentDirPath]/[fileName].
  Future<FileNode> createFile(String parentDirPath, String fileName, {String content = ''}) async {
    final filePath = p.join(parentDirPath, fileName);
    final file = File(filePath);

    if (await file.exists()) {
      throw FileSystemException('File already exists', filePath);
    }

    await file.create(recursive: true);
    if (content.isNotEmpty) {
      await file.writeAsString(content);
    }

    return FileNode(
      path: filePath,
      name: fileName,
      isDirectory: false,
      isLoaded: true,
      sizeBytes: content.length,
    );
  }

  /// Create a new folder at [parentDirPath]/[folderName].
  Future<FileNode> createDirectory(String parentDirPath, String folderName) async {
    final dirPath = p.join(parentDirPath, folderName);
    final dir = Directory(dirPath);

    if (await dir.exists()) {
      throw FileSystemException('Directory already exists', dirPath);
    }

    await dir.create(recursive: true);

    return FileNode(
      path: dirPath,
      name: folderName,
      isDirectory: true,
      children: const [],
      isLoaded: true,
    );
  }

  /// Read file content as String.
  Future<String> readFileAsString(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File does not exist', filePath);
    }
    return await file.readAsString();
  }

  /// Write String content to file.
  Future<void> writeFileAsString(String filePath, String content) async {
    final file = File(filePath);
    await file.writeAsString(content);
  }

  /// Rename a file or directory.
  Future<String> renameEntity(String currentPath, String newName) async {
    final parent = p.dirname(currentPath);
    final targetPath = p.join(parent, newName);

    final type = await FileSystemEntity.type(currentPath);
    if (type == FileSystemEntityType.directory) {
      await Directory(currentPath).rename(targetPath);
    } else {
      await File(currentPath).rename(targetPath);
    }

    return targetPath;
  }

  /// Delete a file or directory recursively.
  Future<void> deleteEntity(String path) async {
    final type = await FileSystemEntity.type(path);
    if (type == FileSystemEntityType.directory) {
      await Directory(path).delete(recursive: true);
    } else if (type == FileSystemEntityType.file) {
      await File(path).delete();
    }
  }

  /// Watch workspace root directory for real-time filesystem events using `watcher`.
  Stream<WatchEvent>? watchWorkspace(String rootPath) {
    _watcherSubscription?.cancel();
    try {
      _watcher = DirectoryWatcher(rootPath);
      return _watcher!.events;
    } catch (_) {
      return null;
    }
  }

  void disposeWatcher() {
    _watcherSubscription?.cancel();
    _watcherSubscription = null;
  }
}
