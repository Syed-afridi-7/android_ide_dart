import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/file_system_service.dart';
import '../services/tab_session_service.dart';
import 'package:android_ide/features/terminal/infrastructure/pty_adapter.dart';
import 'package:android_ide/features/terminal/domain/i_terminal_service.dart';

/// Central Singleton FileSystemService provider.
final fileSystemServiceProvider = Provider<FileSystemService>((ref) {
  return FileSystemService();
});

/// Central Singleton TabSessionService provider.
final tabSessionServiceProvider = Provider<TabSessionService>((ref) {
  return TabSessionService();
});

/// Central PTY Terminal Service provider.
final ptyAdapterProvider = Provider<ITerminalService>((ref) {
  return PtyAdapter();
});

/// Global Active Workspace Path provider.
final activeWorkspacePathProvider = StateProvider<String?>((ref) => null);
