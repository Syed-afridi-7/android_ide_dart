import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xterm/xterm.dart' hide TerminalState;
import 'package:android_ide/features/terminal/application/terminal_cubit.dart';

/// Displays the interactive xterm terminal inside a floating modal bottom sheet (~60% height).
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

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TerminalCubit>();
    final sheetHeight = MediaQuery.of(context).size.height * 0.60;

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
          // Drag Handle & Header Controls
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
                    const Icon(Icons.terminal, color: Colors.greenAccent, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'TERMINAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    BlocBuilder<TerminalCubit, TerminalDockState>(
                      builder: (context, state) {
                        if (state.sessionStatus == TerminalSessionStatus.starting) {
                          return const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.amberAccent,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const Spacer(),
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

          // xterm Output Viewport — directly bound to PTY stdout
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: TerminalView(
                cubit.terminal,
              ),
            ),
          ),

          // CLI Quick Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: const Color(0xFF181818),
            child: Row(
              children: [
                const Text('\$', style: TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
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
                  icon: const Icon(Icons.send_rounded, color: Colors.greenAccent, size: 16),
                  onPressed: () => _submitCommand(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
