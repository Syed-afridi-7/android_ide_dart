import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:android_ide/features/project_explorer/presentation/state/project_explorer_cubit.dart';
import 'package:android_ide/features/code_editor/presentation/state/workspace_cubit.dart';
import 'package:android_ide/features/terminal/application/terminal_cubit.dart';
import 'package:android_ide/features/runner_engine/widgets/live_preview_modal.dart';
import 'package:android_ide/core/utils/language_detector.dart';

class CommandPaletteItem {
  final String title;
  final String category;
  final IconData icon;
  final String? shortcut;
  final VoidCallback onSelect;

  CommandPaletteItem({
    required this.title,
    required this.category,
    required this.icon,
    this.shortcut,
    required this.onSelect,
  });
}

class CommandPaletteModal extends StatefulWidget {
  const CommandPaletteModal({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const CommandPaletteModal(),
    );
  }

  @override
  State<CommandPaletteModal> createState() => _CommandPaletteModalState();
}

class _CommandPaletteModalState extends State<CommandPaletteModal> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CommandPaletteItem> _getCommands(BuildContext context) {
    final workspaceCubit = context.read<WorkspaceCubit>();
    final activeTab = workspaceCubit.state.activeTab;
    final rootPath = context.read<ProjectExplorerCubit>().state.activeProject?.rootPath ?? '';

    return [
      CommandPaletteItem(
        title: 'Run Active File',
        category: 'Execution',
        icon: Icons.play_arrow_rounded,
        shortcut: 'F5',
        onSelect: () async {
          Navigator.pop(context);
          if (activeTab != null) {
            if (activeTab.isDirty) {
              await workspaceCubit.saveActiveTab();
            }
            final langInfo = LanguageDetector.detect(activeTab.filePath);
            if (langInfo.isWebPreview && context.mounted) {
              LivePreviewModal.show(context, activeTab.filePath, activeTab.content);
            } else if (context.mounted) {
              final terminalCubit = context.read<TerminalCubit>();
              terminalCubit.openTerminal();
              terminalCubit.executeCommand(langInfo.buildExecutionCommand(activeTab.filePath));
            }
          }
        },
      ),
      CommandPaletteItem(
        title: 'Save Active File',
        category: 'File',
        icon: Icons.save_outlined,
        shortcut: 'Ctrl+S',
        onSelect: () async {
          Navigator.pop(context);
          final success = await workspaceCubit.saveActiveTab();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(success ? 'Saved active file' : 'No active file to save')),
            );
          }
        },
      ),
      CommandPaletteItem(
        title: 'Create New File in Root',
        category: 'File',
        icon: Icons.note_add_outlined,
        onSelect: () {
          Navigator.pop(context);
          if (rootPath.isNotEmpty) {
            _showCreateFileDialog(context, rootPath);
          }
        },
      ),
      CommandPaletteItem(
        title: 'Create New Folder in Root',
        category: 'File',
        icon: Icons.create_new_folder_outlined,
        onSelect: () {
          Navigator.pop(context);
          if (rootPath.isNotEmpty) {
            _showCreateFolderDialog(context, rootPath);
          }
        },
      ),
      CommandPaletteItem(
        title: 'Toggle Terminal Panel',
        category: 'Terminal',
        icon: Icons.terminal,
        shortcut: 'Ctrl+~',
        onSelect: () {
          Navigator.pop(context);
          context.read<TerminalCubit>().toggleTerminal();
        },
      ),
      CommandPaletteItem(
        title: 'Clear Terminal Output',
        category: 'Terminal',
        icon: Icons.cleaning_services_outlined,
        onSelect: () {
          Navigator.pop(context);
          context.read<TerminalCubit>().clearTerminal();
        },
      ),
      CommandPaletteItem(
        title: 'Refresh Workspace File Tree',
        category: 'Explorer',
        icon: Icons.refresh,
        onSelect: () {
          Navigator.pop(context);
          context.read<ProjectExplorerCubit>().refreshActiveNode();
        },
      ),
    ];
  }

  void _showCreateFileDialog(BuildContext context, String rootPath) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Create New File', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'filename.ext', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(dialogCtx);
                await context.read<ProjectExplorerCubit>().createFile(rootPath, name);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context, String rootPath) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Create New Folder', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder name', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(dialogCtx);
                await context.read<ProjectExplorerCubit>().createDirectory(rootPath, name);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commands = _getCommands(context);
    final filteredCommands = commands
        .where((cmd) =>
            cmd.title.toLowerCase().contains(_query.toLowerCase()) ||
            cmd.category.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 48, left: 16, right: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 450),
        child: Column(
          children: [
            // Search Input Field
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Type a command or search actions...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (val) => setState(() => _query = val),
              ),
            ),

            // Command Items List
            Expanded(
              child: filteredCommands.isEmpty
                  ? const Center(child: Text('No matching commands found.'))
                  : ListView.builder(
                      itemCount: filteredCommands.length,
                      itemBuilder: (context, index) {
                        final cmd = filteredCommands[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(cmd.icon, color: theme.colorScheme.primary, size: 20),
                          title: Text(cmd.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(cmd.category, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
                          trailing: cmd.shortcut != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    cmd.shortcut!,
                                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                                  ),
                                )
                              : null,
                          onTap: cmd.onSelect,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
