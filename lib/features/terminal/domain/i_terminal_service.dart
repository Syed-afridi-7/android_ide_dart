import 'dart:async';

/// Identifies which terminal engine is active.
enum TerminalMode {
  /// Cloud WebSocket terminal (online, full Linux environment).
  cloud,
  /// Local Android shell terminal (offline, sandboxed).
  local,
  /// SSH connection to user's remote VPS/server.
  ssh,
}

/// Configuration for SSH connections to remote servers.
class SshConnectionConfig {
  final String host;
  final int port;
  final String username;
  final String? password;
  final String? privateKey;
  final String? passphrase;

  const SshConnectionConfig({
    required this.host,
    this.port = 22,
    required this.username,
    this.password,
    this.privateKey,
    this.passphrase,
  });

  /// Validate that either password or private key is provided.
  bool get isValid =>
      host.isNotEmpty &&
      username.isNotEmpty &&
      (password != null && password!.isNotEmpty ||
       privateKey != null && privateKey!.isNotEmpty);

  Map<String, dynamic> toJson() => {
    'type': 'ssh_connect',
    'host': host,
    'port': port,
    'username': username,
    if (password != null) 'password': password,
    if (privateKey != null) 'privateKey': privateKey,
    if (passphrase != null) 'passphrase': passphrase,
  };
}

/// Abstract contract for terminal service implementations.
abstract class ITerminalService {
  /// Stream of raw output bytes from the shell process stdout/stderr.
  Stream<List<int>> get outputStream;

  /// Whether a shell process is currently running.
  bool get isRunning;

  /// The terminal mode this adapter represents.
  TerminalMode get mode;

  /// Spawn a new shell process.
  Future<void> startShell({
    String shell,
    String? workingDirectory,
    Map<String, String>? environment,
    int columns,
    int rows,
  });

  /// Write raw bytes to shell stdin.
  void write(List<int> data);

  /// Write a string to shell stdin (convenience).
  void writeString(String data);

  /// Resize the terminal window.
  void resize(int columns, int rows);

  /// Kill the shell process and clean up resources.
  Future<void> kill();

  /// Dispose all resources permanently.
  Future<void> dispose();
}
