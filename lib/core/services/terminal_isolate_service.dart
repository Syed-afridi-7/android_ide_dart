import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter_pty/flutter_pty.dart';

/// Message types for Main <-> Isolate IPC
enum TerminalMessageType {
  init,
  input,
  resize,
  output,
  exit,
  kill,
}

class TerminalIsolateMessage {
  final TerminalMessageType type;
  final String? payload;
  final int? columns;
  final int? rows;
  final int? exitCode;

  TerminalIsolateMessage({
    required this.type,
    this.payload,
    this.columns,
    this.rows,
    this.exitCode,
  });
}

/// Service managing off-main-thread PTY execution and 16ms frame-coalesced output streaming.
class TerminalIsolateService {
  Isolate? _isolate;
  SendPort? _isolateSendPort;
  ReceivePort? _mainReceivePort;
  StreamController<String>? _outputStreamController;
  Timer? _coalesceTimer;
  final List<String> _pendingChunks = [];

  Stream<String>? get outputStream => _outputStreamController?.stream;

  /// Spawn dedicated PTY Isolate session
  Future<void> startSession({
    required String shell,
    List<String> arguments = const [],
    String? workingDirectory,
    Map<String, String>? environment,
    int columns = 80,
    int rows = 24,
  }) async {
    await stopSession();

    _mainReceivePort = ReceivePort();
    _outputStreamController = StreamController<String>.broadcast();

    // Spawn background isolate
    _isolate = await Isolate.spawn(
      _ptyIsolateEntryPoint,
      _mainReceivePort!.sendPort,
    );

    // Listen for SendPort from isolate and output events
    _mainReceivePort!.listen((dynamic message) {
      if (message is SendPort) {
        _isolateSendPort = message;
        // Initialize PTY inside isolate
        _isolateSendPort!.send(TerminalIsolateMessage(
          type: TerminalMessageType.init,
          payload: shell,
          columns: columns,
          rows: rows,
        ));
      } else if (message is TerminalIsolateMessage) {
        if (message.type == TerminalMessageType.output && message.payload != null) {
          _queueOutputChunk(message.payload!);
        } else if (message.type == TerminalMessageType.exit) {
          _queueOutputChunk('\r\n\x1b[33m[Process exited with code ${message.exitCode}]\x1b[0m\r\n');
        }
      }
    });

    // Setup 16ms frame boundary coalescing timer (~60fps UI sync)
    _coalesceTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_pendingChunks.isNotEmpty && _outputStreamController != null && !_outputStreamController!.isClosed) {
        final coalescedText = _pendingChunks.join();
        _pendingChunks.clear();
        _outputStreamController!.add(coalescedText);
      }
    });
  }

  void _queueOutputChunk(String chunk) {
    _pendingChunks.add(chunk);
  }

  /// Write CLI input into isolate PTY stream
  void writeInput(String data) {
    _isolateSendPort?.send(TerminalIsolateMessage(
      type: TerminalMessageType.input,
      payload: data,
    ));
  }

  /// Resize PTY dimensions
  void resize(int cols, int rows) {
    _isolateSendPort?.send(TerminalIsolateMessage(
      type: TerminalMessageType.resize,
      columns: cols,
      rows: rows,
    ));
  }

  /// Kill and clean up isolate and PTY handles safely
  Future<void> stopSession() async {
    _coalesceTimer?.cancel();
    _coalesceTimer = null;

    if (_isolateSendPort != null) {
      _isolateSendPort!.send(TerminalIsolateMessage(type: TerminalMessageType.kill));
    }

    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _isolateSendPort = null;

    _mainReceivePort?.close();
    _mainReceivePort = null;

    if (_outputStreamController != null && !_outputStreamController!.isClosed) {
      await _outputStreamController!.close();
    }
    _outputStreamController = null;
    _pendingChunks.clear();
  }

  /// Isolate Entry Point: Runs off-main-thread PTY read loop
  static void _ptyIsolateEntryPoint(SendPort mainSendPort) {
    final isolateReceivePort = ReceivePort();
    mainSendPort.send(isolateReceivePort.sendPort);

    Pty? pty;
    StreamSubscription<List<int>>? ptySubscription;

    isolateReceivePort.listen((dynamic message) async {
      if (message is! TerminalIsolateMessage) return;

      switch (message.type) {
        case TerminalMessageType.init:
          try {
            final shell = message.payload ?? 'sh';
            pty = Pty.start(
              shell,
              columns: message.columns ?? 80,
              rows: message.rows ?? 24,
            );

            // Read PTY output stream on background isolate thread
            ptySubscription = pty!.output.listen(
              (data) {
                final text = utf8.decode(data, allowMalformed: true);
                mainSendPort.send(TerminalIsolateMessage(
                  type: TerminalMessageType.output,
                  payload: text,
                ));
              },
              onDone: () async {
                final exitCode = await pty?.exitCode;
                mainSendPort.send(TerminalIsolateMessage(
                  type: TerminalMessageType.exit,
                  exitCode: exitCode,
                ));
              },
            );
          } catch (e) {
            mainSendPort.send(TerminalIsolateMessage(
              type: TerminalMessageType.output,
              payload: '\r\n\x1b[31mFailed to launch shell: $e\x1b[0m\r\n',
            ));
          }
          break;

        case TerminalMessageType.input:
          if (pty != null && message.payload != null) {
            pty!.write(utf8.encode(message.payload!));
          }
          break;

        case TerminalMessageType.resize:
          if (pty != null && message.columns != null && message.rows != null) {
            pty!.resize(message.rows!, message.columns!);
          }
          break;

        case TerminalMessageType.kill:
          ptySubscription?.cancel();
          pty?.kill();
          isolateReceivePort.close();
          break;

        default:
          break;
      }
    });
  }
}
