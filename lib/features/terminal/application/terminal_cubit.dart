import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xterm/xterm.dart' hide TerminalState;
import 'package:android_ide/features/terminal/domain/i_terminal_service.dart';
import 'package:android_ide/features/terminal/application/terminal_state.dart';

export 'package:android_ide/features/terminal/application/terminal_state.dart';

class TerminalCubit extends Cubit<TerminalDockState> {
  final ITerminalService _service;
  final Terminal terminal = Terminal(maxLines: 10000);
  StreamSubscription<List<int>>? _outputSubscription;
  bool _shellStarted = false;

  TerminalCubit(this._service) : super(const TerminalDockState());

  @override
  Future<void> close() async {
    await _outputSubscription?.cancel();
    await _service.dispose();
    return super.close();
  }

  /// Spawn the real PTY shell process and bind output stream.
  Future<void> startPtySession({String shell = ''}) async {
    if (_shellStarted && _service.isRunning) return;

    emit(state.copyWith(sessionStatus: TerminalSessionStatus.starting));

    try {
      await _service.startShell(shell: shell);
      _shellStarted = true;

      // Bind xterm onOutput -> PTY stdin (direct keyboard input from TerminalView)
      terminal.onOutput = (data) {
        _service.writeString(data);
      };

      // Bind PTY stdout -> xterm display
      _outputSubscription?.cancel();
      _outputSubscription = _service.outputStream.listen(
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

  /// Clear the xterm display (UI only, does not affect shell state).
  void clearTerminal() {
    terminal.write('\x1b[2J\x1b[H');
  }

  /// Inject a log message directly into the terminal display.
  void appendLog(String text) {
    terminal.write(text);
  }

  /// Execute a command by piping it through the real PTY stdin.
  /// The shell handles echoing, prompt, and stdout/stderr.
  void executeCommand(String command) {
    if (command.trim().isEmpty) return;
    _ensureShellStarted();
    emit(state.copyWith(currentCommand: command));
    _service.writeString('$command\n');
  }

  /// Write raw string input to PTY stdin.
  void sendInput(String input) {
    _service.writeString(input);
  }

  /// Resize the PTY window dimensions.
  void resizeTerminal(int cols, int rows) {
    _service.resize(cols, rows);
  }

  /// Auto-start shell on first interaction if not already running.
  void _ensureShellStarted() {
    if (!_shellStarted || !_service.isRunning) {
      startPtySession();
    }
  }
}
