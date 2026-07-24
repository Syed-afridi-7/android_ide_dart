/// Represents the lifecycle state of a terminal session.
enum TerminalSessionStatus {
  idle,
  starting,
  running,
  exited,
  error,
}

/// Configuration for the terminal environment.
class TerminalEnvironmentConfig {
  final String shell;
  final String workingDirectory;
  final Map<String, String> environment;
  final int columns;
  final int rows;

  const TerminalEnvironmentConfig({
    this.shell = '/system/bin/sh',
    this.workingDirectory = '',
    this.environment = const {},
    this.columns = 80,
    this.rows = 24,
  });
}
