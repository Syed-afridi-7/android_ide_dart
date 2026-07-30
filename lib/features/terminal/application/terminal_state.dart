import 'package:android_ide/features/terminal/domain/terminal_models.dart';
import 'package:android_ide/features/terminal/domain/i_terminal_service.dart';
export 'package:android_ide/features/terminal/domain/terminal_models.dart';
export 'package:android_ide/features/terminal/domain/i_terminal_service.dart'
    show TerminalMode, SshConnectionConfig;

enum TerminalDockMode { hidden, minimized, maximized }

class TerminalDockState {
  final TerminalDockMode mode;
  final TerminalSessionStatus sessionStatus;
  final String currentCommand;
  final bool isRunningProcess;
  final TerminalMode activeMode;
  final SshConnectionConfig? sshConfig;

  const TerminalDockState({
    this.mode = TerminalDockMode.hidden,
    this.sessionStatus = TerminalSessionStatus.idle,
    this.currentCommand = '',
    this.isRunningProcess = false,
    this.activeMode = TerminalMode.cloud,
    this.sshConfig,
  });

  bool get isOpen => mode != TerminalDockMode.hidden;
  bool get isMaximized => mode == TerminalDockMode.maximized;
  bool get isShellRunning => sessionStatus == TerminalSessionStatus.running;
  bool get isCloud => activeMode == TerminalMode.cloud;
  bool get isLocal => activeMode == TerminalMode.local;
  bool get isSSH => activeMode == TerminalMode.ssh;

  TerminalDockState copyWith({
    TerminalDockMode? mode,
    TerminalSessionStatus? sessionStatus,
    String? currentCommand,
    bool? isRunningProcess,
    TerminalMode? activeMode,
    SshConnectionConfig? sshConfig,
  }) {
    return TerminalDockState(
      mode: mode ?? this.mode,
      sessionStatus: sessionStatus ?? this.sessionStatus,
      currentCommand: currentCommand ?? this.currentCommand,
      isRunningProcess: isRunningProcess ?? this.isRunningProcess,
      activeMode: activeMode ?? this.activeMode,
      sshConfig: sshConfig ?? this.sshConfig,
    );
  }
}
