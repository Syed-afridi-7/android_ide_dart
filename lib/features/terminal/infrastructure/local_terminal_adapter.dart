import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:android_ide/features/terminal/domain/i_terminal_service.dart';
import 'package:path_provider/path_provider.dart';

/// Offline local terminal adapter that executes commands directly on the
/// Android system shell via dart:io Process. Works 100% offline.
///
/// Uses `/system/bin/sh` in the app's sandboxed internal directory.
/// Suitable for DSA practice, local script execution, and file management.
class LocalTerminalAdapter implements ITerminalService {
  Process? _process;
  StreamSubscription<List<int>>? _stdoutSubscription;
  StreamSubscription<List<int>>? _stderrSubscription;
  final StreamController<List<int>> _outputController =
      StreamController<List<int>>.broadcast();
  bool _isRunning = false;

  @override
  TerminalMode get mode => TerminalMode.local;

  @override
  Stream<List<int>> get outputStream => _outputController.stream;

  @override
  bool get isRunning => _isRunning;

  @override
  Future<void> startShell({
    String shell = '/system/bin/sh',
    String? workingDirectory,
    Map<String, String>? environment,
    int columns = 80,
    int rows = 24,
  }) async {
    await kill();

    // Resolve working directory to app's internal sandboxed directory
    final resolvedCwd = workingDirectory ?? await _resolveWorkingDirectory();

    // Build environment with sensible defaults for Android
    final defaultEnv = await _buildDefaultEnvironment(resolvedCwd);
    final mergedEnv = {...defaultEnv, ...?environment};

    // Resolve shell path — prefer sh on Android
    final resolvedShell = shell.isEmpty ? _resolveShellPath() : shell;

    try {
      _process = await Process.start(
        resolvedShell,
        ['-l'], // login shell for proper PATH initialization
        workingDirectory: resolvedCwd,
        environment: mergedEnv,
        runInShell: false,
      );

      _isRunning = true;

      // Pipe stdout to output stream
      _stdoutSubscription = _process!.stdout.listen(
        (data) {
          if (!_outputController.isClosed) {
            _outputController.add(data);
          }
        },
        onDone: () => _isRunning = false,
        onError: (e) => _isRunning = false,
      );

      // Pipe stderr to the same output stream (interleaved like a real terminal)
      _stderrSubscription = _process!.stderr.listen(
        (data) {
          if (!_outputController.isClosed) {
            _outputController.add(data);
          }
        },
      );

      // Monitor process exit
      _process!.exitCode.then((code) {
        _isRunning = false;
        if (!_outputController.isClosed) {
          _outputController.add(
            utf8.encode('\r\n\x1b[33m[Local shell exited: code $code]\x1b[0m\r\n'),
          );
        }
      });

      // Send COLUMNS and LINES to the shell for proper formatting
      writeString('export COLUMNS=$columns LINES=$rows\n');
      writeString("export PS1='local:\\w\\\$ '\n");
      writeString('clear\n');
    } catch (e) {
      _isRunning = false;
      rethrow;
    }
  }

  @override
  void write(List<int> data) {
    if (_isRunning && _process != null) {
      _process!.stdin.add(data);
    }
  }

  @override
  void writeString(String data) {
    write(utf8.encode(data));
  }

  @override
  void resize(int columns, int rows) {
    // dart:io Process doesn't support PTY resize natively.
    // Send stty equivalent to inform running programs.
    if (_isRunning && _process != null) {
      writeString('export COLUMNS=$columns LINES=$rows\n');
    }
  }

  @override
  Future<void> kill() async {
    await _stdoutSubscription?.cancel();
    _stdoutSubscription = null;
    await _stderrSubscription?.cancel();
    _stderrSubscription = null;
    _process?.kill(ProcessSignal.sigterm);
    _process = null;
    _isRunning = false;
  }

  @override
  Future<void> dispose() async {
    await kill();
    if (!_outputController.isClosed) {
      await _outputController.close();
    }
  }

  // ── Private Helpers ──

  String _resolveShellPath() {
    // On Android, /system/bin/sh is always available
    const candidates = ['/system/bin/sh', '/bin/sh'];
    for (final path in candidates) {
      if (File(path).existsSync()) return path;
    }
    return '/system/bin/sh';
  }

  Future<String> _resolveWorkingDirectory() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final workspace = Directory('${appDir.path}/workspace');
      if (!workspace.existsSync()) {
        workspace.createSync(recursive: true);
      }
      return workspace.path;
    } catch (_) {
      return '/data/local/tmp';
    }
  }

  Future<Map<String, String>> _buildDefaultEnvironment(String cwd) async {
    String homePath;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      homePath = appDir.path;
    } catch (_) {
      homePath = '/data/local/tmp';
    }

    return {
      'TERM': 'dumb',
      'HOME': homePath,
      'TMPDIR': '$homePath/tmp',
      'PATH': '/system/bin:/system/xbin:/sbin:/vendor/bin',
      'SHELL': '/system/bin/sh',
      'USER': 'developer',
      'PWD': cwd,
      'LANG': 'en_US.UTF-8',
    };
  }
}
