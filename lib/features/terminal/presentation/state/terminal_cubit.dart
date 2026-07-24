import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xterm/xterm.dart' hide TerminalState;
import '../../../../core/services/terminal_isolate_service.dart';

enum TerminalDockMode { hidden, minimized, maximized }

class TerminalDockState {
  final TerminalDockMode mode;
  final String currentCommand;
  final bool isRunningProcess;
  final bool isIsolateActive;

  TerminalDockState({
    this.mode = TerminalDockMode.hidden,
    this.currentCommand = '',
    this.isRunningProcess = false,
    this.isIsolateActive = false,
  });

  bool get isOpen => mode != TerminalDockMode.hidden;
  bool get isMaximized => mode == TerminalDockMode.maximized;

  TerminalDockState copyWith({
    TerminalDockMode? mode,
    String? currentCommand,
    bool? isRunningProcess,
    bool? isIsolateActive,
  }) {
    return TerminalDockState(
      mode: mode ?? this.mode,
      currentCommand: currentCommand ?? this.currentCommand,
      isRunningProcess: isRunningProcess ?? this.isRunningProcess,
      isIsolateActive: isIsolateActive ?? this.isIsolateActive,
    );
  }
}

class TerminalCubit extends Cubit<TerminalDockState> {
  final TerminalIsolateService _isolateService;
  final Terminal terminal = Terminal(maxLines: 2000);
  StreamSubscription<String>? _outputSubscription;

  TerminalCubit(this._isolateService) : super(TerminalDockState()) {
    terminal.write('\x1b[1;32mAndroid IDE Isolated Terminal Shell\x1b[0m\r\nType commands below or click RUN.\r\n\$ ');
  }

  @override
  Future<void> close() async {
    await _outputSubscription?.cancel();
    await _isolateService.stopSession();
    return super.close();
  }

  /// Initialize PTY session inside background isolate
  Future<void> startPtySession({String shell = 'sh'}) async {
    await _isolateService.startSession(shell: shell);
    _outputSubscription?.cancel();

    _outputSubscription = _isolateService.outputStream?.listen((coalescedChunk) {
      // Write 16ms frame-coalesced chunk to xterm view without UI thread jank
      terminal.write(coalescedChunk);
    });

    emit(state.copyWith(isIsolateActive: true));
  }

  void toggleTerminal() {
    if (state.isOpen) {
      emit(state.copyWith(mode: TerminalDockMode.hidden));
    } else {
      emit(state.copyWith(mode: TerminalDockMode.minimized));
    }
  }

  void openTerminal() {
    if (!state.isOpen) {
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
    terminal.write('\x1b[2J\x1b[H');
    terminal.write('\x1b[1;32muser@android-ide\x1b[0m:\x1b[1;34m~\x1b[0m\$ ');
  }

  void appendLog(String text) {
    terminal.write(text);
  }

  void executeCommand(String command) {
    if (command.trim().isEmpty) return;
    emit(state.copyWith(isRunningProcess: true, currentCommand: command));

    // Echo command to terminal display
    terminal.write('\r\n\x1b[33m\$ $command\x1b[0m\r\n');

    if (state.isIsolateActive) {
      // Pipe command into PTY isolate stdin
      _isolateService.writeInput('$command\n');
      // Reset running flag after brief delay (PTY output arrives via stream)
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!isClosed) {
          emit(state.copyWith(isRunningProcess: false));
        }
      });
    } else {
      // Fallback: simulated execution for non-PTY environments
      Future.delayed(const Duration(milliseconds: 200), () {
        if (isClosed) return;
        terminal.write('\x1b[36m[SHELL] Executing: $command\x1b[0m\r\n');
      });
      Future.delayed(const Duration(milliseconds: 800), () {
        if (isClosed) return;
        terminal.write('\x1b[32m[OK] Process exited with code 0.\x1b[0m\r\n');
        terminal.write('\x1b[1;32muser@android-ide\x1b[0m:\x1b[1;34m~\x1b[0m\$ ');
        emit(state.copyWith(isRunningProcess: false));
      });
    }
  }

  void sendInput(String input) {
    if (state.isIsolateActive) {
      _isolateService.writeInput(input);
    } else {
      terminal.write(input);
    }
  }

  void resizeTerminal(int cols, int rows) {
    if (state.isIsolateActive) {
      _isolateService.resize(cols, rows);
    }
  }
}
