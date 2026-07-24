import 'package:flutter/material.dart' hide showModalBottomSheet;
import 'package:flutter/material.dart' as material show showModalBottomSheet;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:android_ide/features/project_explorer/presentation/state/project_explorer_cubit.dart';
import 'package:android_ide/features/project_explorer/domain/entities/file_node.dart';
import 'package:android_ide/features/code_editor/presentation/state/workspace_cubit.dart';
import 'package:android_ide/features/project_explorer/presentation/widgets/git_status_badge.dart';

class WorkspaceDrawer extends StatelessWidget {
  final bool isModal;
  final VoidCallback? onClose;

  const WorkspaceDrawer({
    super.key,
    this.isModal = false,
    this.onClose,
  });

  /// Displays the WorkspaceDrawer as a modal bottom sheet floating popup overlay.
  static Future<void> showModalBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    return material.showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (modalCtx) => SizedBox(
        height: MediaQuery.of(modalCtx).size.height * 0.75,
        child: WorkspaceDrawer(
          isModal: true,
          onClose: () {
            if (Navigator.canPop(modalCtx)) {
              Navigator.pop(modalCtx);
            }
          },
        ),
      ),
    );
  }

  static Future<void> showAsBottomSheet(BuildContext context) => showModalBottomSheet(context);
  static Future<void> showModal(BuildContext context) => showModalBottomSheet(context);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<ProjectExplorerCubit, ProjectExplorerState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else if (state.notificationMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.notificationMessage!),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        final activeProject = state.activeProject;
        final rootPath = activeProject?.rootPath ?? '';

        return Container(
          width: isModal ? double.infinity : 300,
          color: theme.colorScheme.surface,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Workspace Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_special_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          activeProject?.name.toUpperCase() ?? 'EXPLORER',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: theme.colorScheme.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Top level quick action icons
                      IconButton(
                        icon: const Icon(Icons.note_add_outlined, size: 18),
                        tooltip: 'New File in Root',
                        onPressed: rootPath.isEmpty
                            ? null
                            : () => _showCreateFileDialog(context, rootPath),
                      ),
                      IconButton(
                        icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                        tooltip: 'New Folder in Root',
                        onPressed: rootPath.isEmpty
                            ? null
                            : () => _showCreateFolderDialog(context, rootPath),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        tooltip: 'Refresh Workspace',
                        onPressed: () => context.read<ProjectExplorerCubit>().refreshActiveNode(),
                      ),
                      if (isModal)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            if (onClose != null) {
                              onClose!();
                            } else if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                    ],
                  ),
                ),

                // Active Working Directory Indicator
                if (state.activeWorkingDirectory != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                    child: Text(
                      'PWD: ${p.basename(state.activeWorkingDirectory!)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // File Tree List View
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.fileTree.isEmpty
                          ? const Center(
                              child: Text(
                                'No workspace opened.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              children: [
                                FileTreeNodeView(
                                  nodes: state.fileTree,
                                  onFileSelected: (path, name) {
                                    final dirPath = p.dirname(path);
                                    final explorerCubit = context.read<ProjectExplorerCubit>();
                                    final workspaceCubit = context.read<WorkspaceCubit>();
                                    explorerCubit.setActiveWorkingDirectory(dirPath);
                                    explorerCubit.requestOpenFile(path, name);
                                    workspaceCubit.openFile(path, name);

                                    if (isModal) {
                                      if (onClose != null) {
                                        onClose!();
                                      } else if (Navigator.canPop(context)) {
                                        Navigator.pop(context);
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _showCreateFileDialog(BuildContext context, String parentDirPath) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Create New File', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'filename.ext (e.g. main.py, index.html)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(dialogCtx);
                await context.read<ProjectExplorerCubit>().createFile(parentDirPath, name);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  static void _showCreateFolderDialog(BuildContext context, String parentDirPath) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Create New Folder', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Folder name (e.g. src, components)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(dialogCtx);
                await context.read<ProjectExplorerCubit>().createDirectory(parentDirPath, name);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class FileTreeNodeView extends StatelessWidget {
  final List<FileNode> nodes;
  final Function(String path, String name) onFileSelected;
  final int depth;

  const FileTreeNodeView({
    super.key,
    required this.nodes,
    required this.onFileSelected,
    this.depth = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: nodes.map((node) {
        return _FileTreeNodeItem(
          node: node,
          depth: depth,
          onFileSelected: onFileSelected,
        );
      }).toList(),
    );
  }
}

class _FileTreeNodeItem extends StatelessWidget {
  final FileNode node;
  final int depth;
  final Function(String path, String name) onFileSelected;

  const _FileTreeNodeItem({
    required this.node,
    required this.depth,
    required this.onFileSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDirectory = node.isDirectory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            if (isDirectory) {
              context.read<ProjectExplorerCubit>().toggleDirectoryExpansion(node.path);
            } else {
              onFileSelected(node.path, node.name);
            }
          },
          onLongPress: () => _showContextMenu(context, node),
          child: Padding(
            padding: EdgeInsets.only(left: 12.0 * depth + 12.0, top: 6, bottom: 6, right: 12),
            child: Row(
              children: [
                if (isDirectory)
                  Icon(
                    node.isExpanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    size: 16,
                    color: Colors.grey,
                  )
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 4),
                Icon(
                  isDirectory
                      ? (node.isExpanded ? Icons.folder_open : Icons.folder)
                      : _getFileIcon(node.name),
                  size: 16,
                  color: isDirectory ? Colors.amber : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isDirectory ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const GitStatusBadge(status: GitFileStatus.clean),
              ],
            ),
          ),
        ),
        if (isDirectory && node.isExpanded && node.children.isNotEmpty)
          FileTreeNodeView(
            nodes: node.children,
            depth: depth + 1,
            onFileSelected: onFileSelected,
          ),
      ],
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'py':
        return Icons.code;
      case 'js':
        return Icons.javascript;
      case 'html':
        return Icons.html;
      case 'java':
        return Icons.coffee;
      case 'dart':
        return Icons.flutter_dash;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  void _showContextMenu(BuildContext context, FileNode targetNode) {
    material.showModalBottomSheet(
      context: context,
      builder: (bottomSheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text('Delete ${targetNode.name}'),
              onTap: () async {
                Navigator.pop(bottomSheetCtx);
                await context.read<ProjectExplorerCubit>().deleteNode(targetNode.path);
              },
            ),
          ],
        ),
      ),
    );
  }
}
