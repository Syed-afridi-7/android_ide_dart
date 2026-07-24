import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:android_ide/features/code_editor/presentation/state/workspace_cubit.dart';
import 'package:android_ide/features/project_explorer/presentation/widgets/workspace_drawer.dart';
import 'package:android_ide/features/runner_engine/presentation/state/runner_cubit.dart';
import 'package:android_ide/features/terminal/application/terminal_cubit.dart';
import 'package:android_ide/features/runner_engine/widgets/live_preview_modal.dart';
import 'package:android_ide/features/command_palette/presentation/widgets/command_palette_modal.dart';
import 'package:android_ide/core/utils/language_detector.dart';

class EditorTopActionBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onToggleSidebar;
  final VoidCallback onSaveFile;

  const EditorTopActionBar({
    super.key,
    this.onToggleSidebar,
    required this.onSaveFile,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<WorkspaceCubit, WorkspaceState>(
      builder: (context, workspaceState) {
        final activeTab = workspaceState.activeTab;
        final langInfo = activeTab != null
            ? LanguageDetector.detect(activeTab.filePath)
            : null;

        return AppBar(
          elevation: 1,
          backgroundColor: theme.colorScheme.surface,
          leading: IconButton(
            icon: const Icon(Icons.folder_copy_outlined),
            tooltip: 'Toggle Workspace Explorer',
            onPressed: () {
              if (onToggleSidebar != null) {
                onToggleSidebar!();
              } else {
                WorkspaceDrawer.showModalBottomSheet(context);
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                activeTab?.fileName ?? 'Android IDE Workspace',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              if (activeTab != null)
                Text(
                  activeTab.filePath,
                  style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          actions: [
            // Command Palette Launcher Icon
            IconButton(
              icon: const Icon(Icons.manage_search_rounded),
              tooltip: 'Open Command Palette (Ctrl+Shift+P)',
              onPressed: () => CommandPaletteModal.show(context),
            ),

            // Floating Terminal Modal Launcher Icon
            IconButton(
              icon: const Icon(Icons.terminal_outlined),
              tooltip: 'Open Terminal Overlay',
              onPressed: () => context.read<TerminalCubit>().toggleTerminal(),
            ),

            // Save Active File Action
            IconButton(
              icon: Icon(
                activeTab?.isDirty == true ? Icons.save : Icons.save_outlined,
                color: activeTab?.isDirty == true ? Colors.amber : null,
              ),
              tooltip: activeTab?.isDirty == true ? 'Save Changes (*)' : 'File Saved',
              onPressed: activeTab == null ? null : onSaveFile,
            ),

            const SizedBox(width: 4),

            // Dynamic Context-Aware "Run" Button
            Padding(
              padding: const EdgeInsets.only(right: 12.0, top: 8.0, bottom: 8.0),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: langInfo?.color ?? theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(
                  langInfo?.isWebPreview == true
                      ? Icons.open_in_browser
                      : Icons.play_arrow_rounded,
                  size: 18,
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'RUN',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    if (langInfo != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          langInfo.displayName,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ],
                ),
                onPressed: activeTab == null
                    ? null
                    : () async {
                        // 1. Save active file if dirty
                        if (activeTab.isDirty) {
                          onSaveFile();
                        }

                        // 2. Trigger RunnerCubit toolchain verification & run preparation
                        final runnerCubit = context.read<RunnerCubit>();
                        await runnerCubit.triggerRun(
                          filePath: activeTab.filePath,
                          content: activeTab.content,
                        );

                        final runnerState = runnerCubit.state;

                        if (runnerState.status == RunnerStatus.webPreview) {
                          if (context.mounted) {
                            LivePreviewModal.show(
                              context,
                              activeTab.filePath,
                              activeTab.content,
                            );
                          }
                        } else if (runnerState.status == RunnerStatus.missingToolchain) {
                          if (context.mounted) {
                            final terminalCubit = context.read<TerminalCubit>();
                            terminalCubit.openTerminal();
                            terminalCubit.appendLog(
                              '\r\n\x1b[31m[RUNNER ERROR] ${runnerState.errorMessage}\x1b[0m\r\n'
                              '\x1b[33mInstall "${langInfo?.binaryName}" in your system PATH to execute ${activeTab.fileName}.\x1b[0m\r\n\$ ',
                            );
                          }
                        } else if (runnerState.executionCommand != null) {
                          if (context.mounted) {
                            final terminalCubit = context.read<TerminalCubit>();
                            terminalCubit.openTerminal();
                            terminalCubit.executeCommand(runnerState.executionCommand!);
                          }
                        }
                      },
              ),
            ),
          ],
        );
      },
    );
  }
}
