import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/file_system_service.dart';
import '../services/tab_session_service.dart';
import '../services/local_web_server_service.dart';
import '../services/cloud_workspace_sync_service.dart';
import 'package:android_ide/features/terminal/infrastructure/cloud_terminal_adapter.dart';
import 'package:android_ide/features/terminal/infrastructure/local_terminal_adapter.dart';
import 'package:android_ide/features/terminal/infrastructure/ssh_terminal_adapter.dart';
import 'package:android_ide/features/terminal/domain/i_terminal_service.dart';

final fileSystemServiceProvider = Provider<FileSystemService>((ref) {
  return FileSystemService();
});

final tabSessionServiceProvider = Provider<TabSessionService>((ref) {
  return TabSessionService();
});

/// Cloud Terminal Service provider (WebSocket to remote node-pty server).
final cloudTerminalProvider = Provider<ITerminalService>((ref) {
  return CloudTerminalAdapter();
});

/// Local Terminal Service provider (offline Android shell).
final localTerminalProvider = Provider<ITerminalService>((ref) {
  return LocalTerminalAdapter();
});

/// SSH Terminal Service provider (SSH proxy through cloud backend).
final sshTerminalProvider = Provider<SshTerminalAdapter>((ref) {
  return SshTerminalAdapter();
});

final activeWorkspacePathProvider = StateProvider<String?>((ref) => null);

final localWebServerProvider = Provider<LocalWebServerService>((ref) {
  return LocalWebServerService();
});

final cloudWorkspaceSyncProvider = Provider<CloudWorkspaceSyncService>((ref) {
  final cloudTerminal = ref.read(cloudTerminalProvider) as CloudTerminalAdapter;
  return CloudWorkspaceSyncService(cloudTerminal);
});
