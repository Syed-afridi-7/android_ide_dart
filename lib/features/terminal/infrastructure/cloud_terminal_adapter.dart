import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:android_ide/features/terminal/domain/i_terminal_service.dart';

/// Cloud terminal adapter that routes I/O over WebSocket to a remote
/// Node.js server running node-pty, instead of using local flutter_pty.
class CloudTerminalAdapter implements ITerminalService {
  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;
  final StreamController<List<int>> _outputController =
      StreamController<List<int>>.broadcast();
  bool _isRunning = false;
  String _serverUrl = '';

  @override
  TerminalMode get mode => TerminalMode.cloud;

  @override
  Stream<List<int>> get outputStream => _outputController.stream;

  @override
  bool get isRunning => _isRunning;

  @override
  Future<void> startShell({
    String shell = '/bin/bash',
    String? workingDirectory,
    Map<String, String>? environment,
    int columns = 80,
    int rows = 24,
  }) async {
    await kill();

    // Default to localhost for development, override via environment param
    _serverUrl = environment?['CLOUD_TERMINAL_URL'] ??
        const String.fromEnvironment(
          'CLOUD_TERMINAL_URL',
          defaultValue: 'ws://10.0.2.2:8080',
        );

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));

      // Wait for the connection to be established
      await _channel!.ready;

      _isRunning = true;

      // Listen to incoming data from server (shell stdout/stderr)
      _socketSubscription = _channel!.stream.listen(
        (data) {
          if (!_outputController.isClosed) {
            if (data is String) {
              _outputController.add(utf8.encode(data));
            } else if (data is List<int>) {
              _outputController.add(data);
            }
          }
        },
        onDone: () {
          _isRunning = false;
        },
        onError: (error) {
          _isRunning = false;
        },
      );

      // Send initial resize to match client dimensions
      resize(columns, rows);

      // Inject GitHub PAT credentials if provided via environment
      final gitPat = environment?['GITHUB_PAT'] ??
          const String.fromEnvironment('GITHUB_PAT', defaultValue: '');
      if (gitPat.isNotEmpty) {
        _injectGitCredentials(gitPat, environment?['GITHUB_USER'] ?? 'developer');
      }
    } catch (e) {
      _isRunning = false;
      rethrow;
    }
  }

  /// Inject GitHub Personal Access Token into the cloud shell's git config.
  void _injectGitCredentials(String pat, String username) {
    if (!_isRunning || _channel == null) return;
    // Configure git credential store in the cloud shell
    writeString('git config --global credential.helper store\n');
    writeString('echo "https://$username:$pat@github.com" > ~/.git-credentials\n');
    writeString('git config --global user.name "$username"\n');
  }

  @override
  void write(List<int> data) {
    if (_isRunning && _channel != null) {
      _channel!.sink.add(utf8.decode(data));
    }
  }

  @override
  void writeString(String data) {
    if (_isRunning && _channel != null) {
      _channel!.sink.add(data);
    }
  }

  @override
  void resize(int columns, int rows) {
    if (_isRunning && _channel != null) {
      final payload = jsonEncode({
        'type': 'resize',
        'cols': columns,
        'rows': rows,
      });
      _channel!.sink.add(payload);
    }
  }

  /// Send a single file sync payload to the cloud container.
  void syncFile(String relativePath, String content) {
    if (_isRunning && _channel != null) {
      final payload = jsonEncode({
        'type': 'sync_file',
        'relativePath': relativePath,
        'content': content,
      });
      _channel!.sink.add(payload);
    }
  }

  /// Send bulk workspace sync payload.
  void syncWorkspace(List<Map<String, String>> files) {
    if (_isRunning && _channel != null) {
      final payload = jsonEncode({
        'type': 'sync_workspace',
        'files': files,
      });
      _channel!.sink.add(payload);
    }
  }

  @override
  Future<void> kill() async {
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await _channel?.sink.close();
    _channel = null;
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
