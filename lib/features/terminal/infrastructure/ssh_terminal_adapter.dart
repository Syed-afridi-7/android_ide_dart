import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:android_ide/features/terminal/domain/i_terminal_service.dart';

/// SSH terminal adapter that connects to a user's remote VPS/server
/// through the cloud backend's SSH proxy. The cloud server receives
/// SSH credentials and establishes the connection on behalf of the client.
class SshTerminalAdapter implements ITerminalService {
  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;
  final StreamController<List<int>> _outputController =
      StreamController<List<int>>.broadcast();
  bool _isRunning = false;
  SshConnectionConfig? _activeConfig;

  @override
  TerminalMode get mode => TerminalMode.ssh;

  @override
  Stream<List<int>> get outputStream => _outputController.stream;

  @override
  bool get isRunning => _isRunning;

  /// The currently active SSH configuration.
  SshConnectionConfig? get activeConfig => _activeConfig;

  /// Connect to a remote server via SSH through the cloud proxy.
  /// The [environment] map MUST contain 'CLOUD_TERMINAL_URL' or it falls
  /// back to the compile-time default. The SSH config is passed via
  /// [environment] keys: SSH_HOST, SSH_PORT, SSH_USER, SSH_PASSWORD, SSH_KEY.
  @override
  Future<void> startShell({
    String shell = '/bin/bash',
    String? workingDirectory,
    Map<String, String>? environment,
    int columns = 80,
    int rows = 24,
  }) async {
    await kill();

    final serverUrl = environment?['CLOUD_TERMINAL_URL'] ??
        const String.fromEnvironment(
          'CLOUD_TERMINAL_URL',
          defaultValue: 'ws://10.0.2.2:8080',
        );

    try {
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));
      await _channel!.ready;
      _isRunning = true;

      // Listen to incoming data from server
      _socketSubscription = _channel!.stream.listen(
        (data) {
          if (!_outputController.isClosed) {
            final str = data.toString();

            // Check for SSH status control messages
            if (str.startsWith('{')) {
              try {
                final parsed = jsonDecode(str);
                if (parsed is Map && parsed['type'] == 'ssh_status') {
                  // Handle status messages - also display them
                  final status = parsed['status'];
                  if (status == 'error') {
                    _isRunning = false;
                  }
                  // Still pass through to terminal for user visibility
                }
              } catch (_) {
                // Not JSON control, treat as output
              }
            }

            if (data is String) {
              _outputController.add(utf8.encode(data));
            } else if (data is List<int>) {
              _outputController.add(data);
            }
          }
        },
        onDone: () => _isRunning = false,
        onError: (error) => _isRunning = false,
      );

      // If SSH config is provided via environment, connect immediately
      final sshHost = environment?['SSH_HOST'];
      if (sshHost != null && sshHost.isNotEmpty) {
        final config = SshConnectionConfig(
          host: sshHost,
          port: int.tryParse(environment?['SSH_PORT'] ?? '22') ?? 22,
          username: environment?['SSH_USER'] ?? 'root',
          password: environment?['SSH_PASSWORD'],
          privateKey: environment?['SSH_KEY'],
        );
        connectSSH(config, columns: columns, rows: rows);
      }
    } catch (e) {
      _isRunning = false;
      rethrow;
    }
  }

  /// Send SSH connection request to the cloud backend proxy.
  void connectSSH(SshConnectionConfig config, {int columns = 80, int rows = 30}) {
    if (!_isRunning || _channel == null) return;
    _activeConfig = config;

    final payload = {
      ...config.toJson(),
      'cols': columns,
      'rows': rows,
    };
    _channel!.sink.add(jsonEncode(payload));
  }

  /// Disconnect the current SSH session (but keep WebSocket alive).
  void disconnectSSH() {
    if (_isRunning && _channel != null) {
      _channel!.sink.add(jsonEncode({'type': 'ssh_disconnect'}));
    }
    _activeConfig = null;
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
      _channel!.sink.add(jsonEncode({
        'type': 'resize',
        'cols': columns,
        'rows': rows,
      }));
    }
  }

  @override
  Future<void> kill() async {
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await _channel?.sink.close();
    _channel = null;
    _isRunning = false;
    _activeConfig = null;
  }

  @override
  Future<void> dispose() async {
    await kill();
    if (!_outputController.isClosed) {
      await _outputController.close();
    }
  }
}
