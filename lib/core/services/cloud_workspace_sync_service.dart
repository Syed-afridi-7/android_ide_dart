import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:android_ide/features/terminal/infrastructure/cloud_terminal_adapter.dart';

/// Background daemon service that syncs local workspace files to the Cloud Container.
class CloudWorkspaceSyncService {
  final CloudTerminalAdapter _cloudAdapter;

  CloudWorkspaceSyncService(this._cloudAdapter);

  /// Perform a full initial sync of all workspace files under [workspacePath].
  Future<void> syncFullWorkspace(String workspacePath) async {
    final dir = Directory(workspacePath);
    if (!dir.existsSync()) return;

    final List<Map<String, String>> fileList = [];

    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: workspacePath);
        // Skip hidden git or lock files if huge
        if (relativePath.contains('.git/') || relativePath.contains('node_modules/')) {
          continue;
        }
        try {
          final content = await entity.readAsString();
          fileList.add({
            'relativePath': relativePath.replaceAll('\\', '/'),
            'content': content,
          });
        } catch (_) {
          // Binary or unreadable file, skip for string sync
        }
      }
    }

    if (fileList.isNotEmpty) {
      _cloudAdapter.syncWorkspace(fileList);
    }
  }

  /// Sync a single file to the cloud when saved.
  Future<void> syncSingleFile(String workspacePath, String filePath, String content) async {
    final relativePath = p.relative(filePath, from: workspacePath).replaceAll('\\', '/');
    _cloudAdapter.syncFile(relativePath, content);
  }
}
