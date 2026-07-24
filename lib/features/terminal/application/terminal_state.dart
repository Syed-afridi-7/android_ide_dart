import 'package:android_ide/features/terminal/domain/terminal_models.dart';
export 'package:android_ide/features/terminal/domain/terminal_models.dart';

enum TerminalDockMode { hidden, minimized, maximized }

class TerminalDockState {
  final TerminalDockMode mode;
  final TerminalSessionStatus sessionStatus;
  final String currentCommand;
  final bool isRunningProcess;

  const TerminalDockState({
    this.mode = TerminalDockMode.hidden,
    this.sessionStatus = TerminalSessionStatus.idle,
    this.currentCommand = '',
    this.isRunningProcess = false,
  });

  bool get isOpen => mode != TerminalDockMode.hidden;
  bool get isMaximized => mode == TerminalDockMode.maximized;
  bool get isShellRunning => sessionStatus == TerminalSessionStatus.running;

  TerminalDockState copyWith({
    TerminalDockMode? mode,
    TerminalSessionStatus? sessionStatus,
    String? currentCommand,
    bool? isRunningProcess,
  }) {
    return TerminalDockState(
      mode: mode ?? this.mode,
      sessionStatus: sessionStatus ?? this.sessionStatus,
      currentCommand: currentCommand ?? this.currentCommand,
      isRunningProcess: isRunningProcess ?? this.isRunningProcess,
    );
  }
}
