import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xterm/xterm.dart' hide TerminalState;
import 'package:android_ide/features/terminal/application/terminal_cubit.dart';
import 'package:android_ide/features/terminal/presentation/widgets/ssh_connection_dialog.dart';

/// Displays the triple-mode terminal inside a floating modal bottom sheet.
Future<void> showTerminalModalBottomSheet(BuildContext context) {
  final terminalCubit = context.read<TerminalCubit>();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) {
      return BlocProvider.value(
        value: terminalCubit,
        child: const TerminalDockModal(),
      );
    },
  ).whenComplete(() {
    if (context.mounted) {
      context.read<TerminalCubit>().closeTerminal();
    }
  });
}

class TerminalDockModal extends StatefulWidget {
  const TerminalDockModal({super.key});

  @override
  State<TerminalDockModal> createState() => _TerminalDockModalState();
}

class _TerminalDockModalState extends State<TerminalDockModal> {
  final TextEditingController _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _submitCommand(BuildContext context) {
    final cmd = _inputController.text.trim();
    if (cmd.isNotEmpty) {
      _inputController.clear();
      context.read<TerminalCubit>().executeCommand(cmd);
    }
  }

  void _sendQuickKey(BuildContext context, String key) {
    context.read<TerminalCubit>().sendInput(key);
  }

  Future<void> _handleSSHTap(BuildContext context) async {
    final cubit = context.read<TerminalCubit>();
    final currentState = cubit.state;

    // If already in SSH mode and connected, just switch
    if (currentState.isSSH && currentState.isShellRunning) {
      return;
    }

    // Show SSH connection dialog
    final config = await SshConnectionDialog.show(context);
    if (config != null && context.mounted) {
      cubit.connectSSH(config);
    }
  }

  Color _accentColor(TerminalDockState state) {
    switch (state.activeMode) {
      case TerminalMode.cloud:
        return Colors.cyanAccent;
      case TerminalMode.local:
        return Colors.greenAccent;
      case TerminalMode.ssh:
        return Colors.orangeAccent;
    }
  }

  String _modeLabel(TerminalDockState state) {
    switch (state.activeMode) {
      case TerminalMode.cloud:
        return 'CLOUD TERMINAL';
      case TerminalMode.local:
        return 'LOCAL TERMINAL';
      case TerminalMode.ssh:
        final host = state.sshConfig?.host;
        return host != null ? 'SSH: $host' : 'SSH TERMINAL';
    }
  }

  IconData _modeIcon(TerminalDockState state) {
    switch (state.activeMode) {
      case TerminalMode.cloud:
        return Icons.cloud_outlined;
      case TerminalMode.local:
        return Icons.phone_android;
      case TerminalMode.ssh:
        return Icons.vpn_key_rounded;
    }
  }

  String _overlayText(TerminalDockState state) {
    switch (state.activeMode) {
      case TerminalMode.cloud:
        return 'Connecting to cloud environment...';
      case TerminalMode.local:
        return 'Starting local shell...';
      case TerminalMode.ssh:
        return 'Connecting to SSH server...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TerminalCubit>();
    final sheetHeight = MediaQuery.of(context).size.height * 0.65;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: Color(0xFF333333), width: 1),
        ),
      ),
      child: Column(
        children: [
          // ── Header Bar ──
          Container(
            padding: const EdgeInsets.only(top: 8, bottom: 4, left: 12, right: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF252526),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    BlocBuilder<TerminalCubit, TerminalDockState>(
                      buildWhen: (p, c) => p.activeMode != c.activeMode || p.sshConfig != c.sshConfig,
                      builder: (context, state) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_modeIcon(state), color: _accentColor(state), size: 16),
                            const SizedBox(width: 8),
                            Text(
                              _modeLabel(state),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    BlocBuilder<TerminalCubit, TerminalDockState>(
                      builder: (context, state) {
                        if (state.sessionStatus == TerminalSessionStatus.starting) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _accentColor(state),
                              ),
                            ),
                          );
                        }
                        if (state.sessionStatus == TerminalSessionStatus.running) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                            ),
                          );
                        }
                        if (state.sessionStatus == TerminalSessionStatus.error ||
                            state.sessionStatus == TerminalSessionStatus.exited) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const Spacer(),
                    // SSH disconnect button (only in SSH mode)
                    BlocBuilder<TerminalCubit, TerminalDockState>(
                      buildWhen: (p, c) => p.activeMode != c.activeMode || p.sessionStatus != c.sessionStatus,
                      builder: (context, state) {
                        if (state.isSSH && state.isShellRunning) {
                          return IconButton(
                            icon: const Icon(Icons.link_off, color: Colors.orangeAccent, size: 18),
                            tooltip: 'Disconnect SSH',
                            onPressed: () => context.read<TerminalCubit>().disconnectSSH(),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.grey, size: 18),
                      tooltip: 'Restart Session',
                      onPressed: () => context.read<TerminalCubit>().startSession(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cleaning_services_outlined, color: Colors.grey, size: 18),
                      tooltip: 'Clear Terminal',
                      onPressed: () => context.read<TerminalCubit>().clearTerminal(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                      tooltip: 'Close Terminal',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Mode Toggle Tab Bar (3 tabs) ──
          BlocBuilder<TerminalCubit, TerminalDockState>(
            buildWhen: (p, c) => p.activeMode != c.activeMode,
            builder: (context, state) {
              return Container(
                height: 36,
                color: const Color(0xFF1A1A1A),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeTab(
                        icon: Icons.cloud_outlined,
                        label: 'Online',
                        isActive: state.isCloud,
                        activeColor: Colors.cyanAccent,
                        onTap: () => context.read<TerminalCubit>().switchMode(TerminalMode.cloud),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: _ModeTab(
                        icon: Icons.phone_android,
                        label: 'Offline',
                        isActive: state.isLocal,
                        activeColor: Colors.greenAccent,
                        onTap: () => context.read<TerminalCubit>().switchMode(TerminalMode.local),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: _ModeTab(
                        icon: Icons.vpn_key_rounded,
                        label: 'SSH',
                        isActive: state.isSSH,
                        activeColor: Colors.orangeAccent,
                        onTap: () => _handleSSHTap(context),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── xterm Output Viewport ──
          Expanded(
            child: BlocBuilder<TerminalCubit, TerminalDockState>(
              buildWhen: (p, c) => p.activeMode != c.activeMode || p.sessionStatus != c.sessionStatus,
              builder: (context, state) {
                return Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: TerminalView(
                        cubit.activeTerminal,
                        autofocus: true,
                      ),
                    ),
                    if (state.sessionStatus == TerminalSessionStatus.starting)
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: _accentColor(state)),
                              const SizedBox(height: 12),
                              Text(
                                _overlayText(state),
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // SSH idle state - show connect prompt
                    if (state.isSSH && state.sessionStatus == TerminalSessionStatus.idle)
                      Container(
                        color: Colors.black87,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.vpn_key_rounded, color: Colors.orangeAccent, size: 48),
                              const SizedBox(height: 16),
                              const Text(
                                'Connect to your VPS',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'SSH into any remote server directly\nfrom your mobile IDE',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                onPressed: () => _handleSSHTap(context),
                                icon: const Icon(Icons.login, size: 18),
                                label: const Text('Connect SSH', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // ── Mobile Quick-Key Symbol Bar ──
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            color: const Color(0xFF2D2D2D),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _QuickKey(label: 'Tab', onTap: () => _sendQuickKey(context, '\t')),
                _QuickKey(label: 'Esc', onTap: () => _sendQuickKey(context, '\x1b')),
                _QuickKey(label: 'Ctrl+C', onTap: () => _sendQuickKey(context, '\x03')),
                _QuickKey(label: 'Ctrl+D', onTap: () => _sendQuickKey(context, '\x04')),
                _QuickKey(label: 'Ctrl+Z', onTap: () => _sendQuickKey(context, '\x1a')),
                _QuickKey(label: '\u2191', onTap: () => _sendQuickKey(context, '\x1b[A')),
                _QuickKey(label: '\u2193', onTap: () => _sendQuickKey(context, '\x1b[B')),
                _QuickKey(label: '{', onTap: () => _sendQuickKey(context, '{')),
                _QuickKey(label: '}', onTap: () => _sendQuickKey(context, '}')),
                _QuickKey(label: '[', onTap: () => _sendQuickKey(context, '[')),
                _QuickKey(label: ']', onTap: () => _sendQuickKey(context, ']')),
                _QuickKey(label: '|', onTap: () => _sendQuickKey(context, '|')),
                _QuickKey(label: ';', onTap: () => _sendQuickKey(context, ';')),
                _QuickKey(label: '/', onTap: () => _sendQuickKey(context, '/')),
                _QuickKey(label: '~', onTap: () => _sendQuickKey(context, '~')),
                _QuickKey(label: '-', onTap: () => _sendQuickKey(context, '-')),
                _QuickKey(label: '=>', onTap: () => _sendQuickKey(context, '=>')),
              ],
            ),
          ),

          // ── CLI Quick Input Bar ──
          BlocBuilder<TerminalCubit, TerminalDockState>(
            buildWhen: (p, c) => p.activeMode != c.activeMode,
            builder: (context, state) {
              final accentColor = _accentColor(state);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: const Color(0xFF181818),
                child: Row(
                  children: [
                    Text('\$', style: TextStyle(color: accentColor, fontFamily: 'monospace')),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                        decoration: const InputDecoration(
                          hintText: 'Type command and press Enter...',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 6),
                        ),
                        onSubmitted: (_) => _submitCommand(context),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send_rounded, color: accentColor, size: 16),
                      onPressed: () => _submitCommand(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ModeTab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? activeColor : Colors.grey.shade700,
            width: isActive ? 1.5 : 0.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: isActive ? activeColor : Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : Colors.grey,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Material(
        color: const Color(0xFF3C3C3C),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
