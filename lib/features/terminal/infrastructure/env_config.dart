import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Resolves Android-safe environment variables for PTY shell spawning.
class TerminalEnvConfig {
  /// Resolves a safe working directory inside app sandbox.
  static Future<String> resolveWorkingDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final workspaceDir = Directory('${appDir.path}/workspace');
    if (!await workspaceDir.exists()) {
      await workspaceDir.create(recursive: true);
    }
    return workspaceDir.path;
  }

  /// Builds the environment map for the PTY process.
  static Future<Map<String, String>> buildEnvironment() async {
    final appDir = await getApplicationDocumentsDirectory();
    final tmpDir = await getTemporaryDirectory();
    final home = appDir.path;

    return {
      'TERM': 'xterm-256color',
      'HOME': home,
      'TMPDIR': tmpDir.path,
      'LANG': 'en_US.UTF-8',
      'PATH': '/system/bin:/system/xbin:/sbin:/vendor/bin:$home/bin',
    };
  }

  /// Resolves the default shell binary path for Android.
  static String resolveShellPath() {
    // Android provides /system/bin/sh as the default POSIX shell
    const candidates = ['/system/bin/sh', '/system/bin/toybox'];
    for (final path in candidates) {
      if (File(path).existsSync()) return path;
    }
    return '/system/bin/sh';
  }
}
