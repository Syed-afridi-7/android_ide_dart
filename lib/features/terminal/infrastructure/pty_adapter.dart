import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:android_ide/features/terminal/domain/i_terminal_service.dart';
import 'package:android_ide/features/terminal/infrastructure/env_config.dart';

/// Production PTY adapter backed by flutter_pty.
class PtyAdapter implements ITerminalService {
  Pty? _pty;
  StreamSubscription<List<int>>? _outputSubscription;
  final StreamController<List<int>> _outputController = StreamController<List<int>>.broadcast();
  bool _isRunning = false;

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

    final resolvedShell = shell.isEmpty ? TerminalEnvConfig.resolveShellPath() : shell;
    final resolvedCwd = workingDirectory ?? await TerminalEnvConfig.resolveWorkingDirectory();
    final defaultEnv = await TerminalEnvConfig.buildEnvironment();
    final mergedEnv = {...defaultEnv, ...?environment};

    _pty = Pty.start(
      resolvedShell,
      columns: columns,
      rows: rows,
      workingDirectory: resolvedCwd,
      environment: mergedEnv,
    );

    _isRunning = true;

    _outputSubscription = _pty!.output.listen(
      (data) {
        if (!_outputController.isClosed) {
          _outputController.add(data);
        }
      },
      onDone: () {
        _isRunning = false;
      },
      onError: (error) {
        _isRunning = false;
      },
    );
  }

  @override
  void write(List<int> data) {
    _pty?.write(Uint8List.fromList(data));
  }

  @override
  void writeString(String data) {
    write(utf8.encode(data));
  }

  @override
  void resize(int columns, int rows) {
    _pty?.resize(rows, columns);
  }

  @override
  Future<void> kill() async {
    _outputSubscription?.cancel();
    _outputSubscription = null;
    _pty?.kill();
    _pty = null;
    _isRunning = false;
  }

  @override
  Future<void> dispose() async {
    await kill();
    if (!_outputController.isClosed) {
      await _outputController.close();
    }
  }
}
