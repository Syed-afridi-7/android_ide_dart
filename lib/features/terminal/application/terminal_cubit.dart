// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xterm/xterm.dart' hide TerminalState;
import 'package:android_ide/features/terminal/domain/i_terminal_service.dart';
import 'package:android_ide/features/terminal/infrastructure/ssh_terminal_adapter.dart';
import 'package:android_ide/features/terminal/application/terminal_state.dart';

export 'package:android_ide/features/terminal/application/terminal_state.dart';

/// Manages triple terminal sessions: cloud (online), local (offline), and SSH (VPS).
class TerminalCubit extends Cubit<TerminalDockState> {
  final ITerminalService _cloudService;
  final ITerminalService _localService;
  final SshTerminalAdapter _sshService;

  /// Separate xterm buffers for each mode so switching preserves history.
  final Terminal cloudTerminal = Terminal(maxLines: 10000);
  final Terminal localTerminal = Terminal(maxLines: 10000);
  final Terminal sshTerminal = Terminal(maxLines: 10000);

  StreamSubscription<List<int>>? _outputSubscription;
  bool _cloudStarted = false;
  bool _localStarted = false;
  bool _sshStarted = false;

  TerminalCubit({
    required ITerminalService cloudService,
    required ITerminalService localService,
    required SshTerminalAdapter sshService,
  })  : _cloudService = cloudService,
        _localService = localService,
        _sshService = sshService,
        super(const TerminalDockState()) {
    cloudTerminal.onOutput = (data) {
      _cloudService.writeString(data);
    };
    localTerminal.onOutput = (data) {
      _localService.writeString(data);
    };
    sshTerminal.onOutput = (data) {
      _sshService.writeString(data);
    };
  }

  /// The currently active terminal buffer for the UI to render.
  Terminal get activeTerminal {
    switch (state.activeMode) {
      case TerminalMode.cloud:
        return cloudTerminal;
      case TerminalMode.local:
        return localTerminal;
      case TerminalMode.ssh:
        return sshTerminal;
    }
  }

  /// The currently active service.
  ITerminalService get _activeService {
    switch (state.activeMode) {
      case TerminalMode.cloud:
        return _cloudService;
      case TerminalMode.local:
        return _localService;
      case TerminalMode.ssh:
        return _sshService;
    }
  }

  @override
  Future<void> close() async {
    await _outputSubscription?.cancel();
    await _cloudService.dispose();
    await _localService.dispose();
    await _sshService.dispose();
    return super.close();
  }

  /// Switch between cloud, local, and SSH terminal modes.
  void switchMode(TerminalMode mode) {
    if (state.activeMode == mode) return;

    _outputSubscription?.cancel();
    _outputSubscription = null;

    emit(state.copyWith(activeMode: mode, sessionStatus: TerminalSessionStatus.idle));

    // Auto-start cloud and local; SSH requires explicit connectSSH()
    if (mode != TerminalMode.ssh) {
      _ensureShellStarted();
    }
  }

  /// Connect to a remote server via SSH.
  Future<void> connectSSH(SshConnectionConfig config) async {
    // Switch to SSH mode
    _outputSubscription?.cancel();
    _outputSubscription = null;

    emit(state.copyWith(
      activeMode: TerminalMode.ssh,
      sessionStatus: TerminalSessionStatus.starting,
      sshConfig: config,
    ));

    try {
      // Start the WebSocket connection to the cloud proxy first
      if (!_sshStarted || !_sshService.isRunning) {
        await _sshService.startShell();
        _sshStarted = true;
      }

      _outputSubscription = _sshService.outputStream.listen(
        (data) {
          sshTerminal.write(String.fromCharCodes(data));
        },
        onDone: () {
          if (!isClosed) {
            emit(state.copyWith(sessionStatus: TerminalSessionStatus.exited));
          }
        },
        onError: (e) {
          if (!isClosed) {
            emit(state.copyWith(sessionStatus: TerminalSessionStatus.error));
          }
        },
      );

      // Send SSH connect command to backend
      _sshService.connectSSH(config);

      sshTerminal.write(
        '\x1b[36mConnecting to ${config.username}@${config.host}:${config.port}...\x1b[0m\r\n',
      );

      emit(state.copyWith(sessionStatus: TerminalSessionStatus.running));
    } catch (e) {
      sshTerminal.write('\x1b[31mSSH Connection Failed: $e\x1b[0m\r\n');
      emit(state.copyWith(sessionStatus: TerminalSessionStatus.error));
    }
  }

  /// Disconnect the active SSH session.
  void disconnectSSH() {
    _sshService.disconnectSSH();
    _sshStarted = false;
    emit(state.copyWith(sessionStatus: TerminalSessionStatus.exited));
    sshTerminal.write('\r\n\x1b[33m[SSH Disconnected]\x1b[0m\r\n');
  }

  /// Spawn the shell for the currently active mode and bind I/O.
  Future<void> startSession({String shell = ''}) async {
    if (state.activeMode == TerminalMode.ssh) return; // SSH uses connectSSH()

    final isCloud = state.activeMode == TerminalMode.cloud;
    final service = _activeService;
    final terminal = activeTerminal;
    final alreadyStarted = isCloud ? _cloudStarted : _localStarted;

    if (alreadyStarted && service.isRunning) return;

    emit(state.copyWith(sessionStatus: TerminalSessionStatus.starting));

    try {
      await service.startShell(shell: shell);

      if (isCloud) {
        _cloudStarted = true;
      } else {
        _localStarted = true;
      }

      _outputSubscription?.cancel();
      _outputSubscription = service.outputStream.listen(
        (data) {
          terminal.write(String.fromCharCodes(data));
        },
        onDone: () {
          if (!isClosed) {
            emit(state.copyWith(sessionStatus: TerminalSessionStatus.exited));
          }
        },
        onError: (e) {
          if (!isClosed) {
            emit(state.copyWith(sessionStatus: TerminalSessionStatus.error));
          }
        },
      );

      emit(state.copyWith(sessionStatus: TerminalSessionStatus.running));
    } catch (e) {
      terminal.write('\x1b[31mFailed to start shell: $e\x1b[0m\r\n');
      emit(state.copyWith(sessionStatus: TerminalSessionStatus.error));
    }
  }

  void toggleTerminal() {
    if (state.isOpen) {
      emit(state.copyWith(mode: TerminalDockMode.hidden));
    } else {
      _ensureShellStarted();
      emit(state.copyWith(mode: TerminalDockMode.minimized));
    }
  }

  void openTerminal() {
    if (!state.isOpen) {
      _ensureShellStarted();
      emit(state.copyWith(mode: TerminalDockMode.minimized));
    }
  }

  void closeTerminal() {
    emit(state.copyWith(mode: TerminalDockMode.hidden));
  }

  void toggleMaximize() {
    if (state.mode == TerminalDockMode.maximized) {
      emit(state.copyWith(mode: TerminalDockMode.minimized));
    } else {
      emit(state.copyWith(mode: TerminalDockMode.maximized));
    }
  }

  void clearTerminal() {
    activeTerminal.write('\x1b[2J\x1b[H');
  }

  void appendLog(String text) {
    activeTerminal.write(text);
  }

  void executeCommand(String command) {
    if (command.trim().isEmpty) return;
    _ensureShellStarted();
    emit(state.copyWith(currentCommand: command));
    _activeService.writeString('$command\n');
  }

  void sendInput(String input) {
    _activeService.writeString(input);
  }

  void resizeTerminal(int cols, int rows) {
    _activeService.resize(cols, rows);
  }

  void _ensureShellStarted() {
    if (state.activeMode == TerminalMode.ssh) return;
    final isCloud = state.activeMode == TerminalMode.cloud;
    final alreadyStarted = isCloud ? _cloudStarted : _localStarted;
    if (!alreadyStarted || !_activeService.isRunning) {
      startSession();
    }
  }
}
