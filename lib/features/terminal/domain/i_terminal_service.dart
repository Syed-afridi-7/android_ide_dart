import 'dart:async';

/// Abstract contract for the PTY terminal service.
abstract class ITerminalService {
  /// Stream of raw output bytes from the shell process stdout/stderr.
  Stream<List<int>> get outputStream;

  /// Whether a shell process is currently running.
  bool get isRunning;

  /// Spawn a new shell process.
  /// [shell] defaults to '/system/bin/sh' for Android.
  /// [workingDirectory] defaults to app documents directory.
  /// [environment] merged with defaults (PATH, TERM, HOME, TMPDIR).
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

  /// Resize the PTY window.
  void resize(int columns, int rows);

  /// Kill the shell process and clean up resources.
  Future<void> kill();

  /// Dispose all resources permanently.
  Future<void> dispose();
}
