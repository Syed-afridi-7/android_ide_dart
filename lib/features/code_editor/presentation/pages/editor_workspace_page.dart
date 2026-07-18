import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:re_editor/re_editor.dart';
import 'package:xterm/xterm.dart';
import 'package:go_router/go_router.dart';

import 'package:android_ide/features/project_explorer/presentation/state/project_explorer_cubit.dart';
import 'package:android_ide/features/project_explorer/domain/entities/file_node.dart';
import 'package:android_ide/features/code_editor/presentation/state/workspace_cubit.dart';

class EditorWorkspacePage extends StatefulWidget {
  const EditorWorkspacePage({super.key});

  @override
  State<EditorWorkspacePage> createState() => _EditorWorkspacePageState();
}

class _EditorWorkspacePageState extends State<EditorWorkspacePage> {
  final Terminal _terminal = Terminal(maxLines: 1000);
  final CodeLineEditingController _editorController = CodeLineEditingController();
  bool _isSidebarOpen = true;
  bool _isTerminalOpen = false;
  String? _currentlyEditingPath;

  @override
  void initState() {
    super.initState();
    _terminal.write('Welcome to Android IDE shell.\r\n\$ ');
  }

  @override
  void dispose() {
    _editorController.dispose();
    super.dispose();
  }

  // Reads file contents from disk and opens a tab in the workspace
  void _onFileSelected(BuildContext context, String path, String name) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        if (context.mounted) {
          context.read<WorkspaceCubit>().openFile(path, name, content);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read file: $e')),
        );
      }
    }
  }

  void _onNodeTapped(BuildContext context, FileNode node) {
    if (node.isDirectory) {
      context.read<ProjectExplorerCubit>().toggleDirectoryExpansion(node.path);
    } else {
      _onFileSelected(context, node.path, node.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocListener<WorkspaceCubit, WorkspaceState>(
      listener: (context, state) {
        final activeTab = state.activeTab;
        if (activeTab != null && activeTab.filePath != _currentlyEditingPath) {
          setState(() {
            _currentlyEditingPath = activeTab.filePath;
            // Temporarily replace text content in the editor
            _editorController.text = activeTab.content;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<ProjectExplorerCubit, ProjectExplorerState>(
            builder: (context, state) {
              return Text(state.activeProject?.name ?? 'Android IDE Workspace');
            },
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.save_outlined),
              tooltip: 'Save Current File',
              onPressed: () async {
                final workspaceCubit = context.read<WorkspaceCubit>();
                final activeTab = workspaceCubit.state.activeTab;
                if (activeTab != null) {
                  try {
                    final file = File(activeTab.filePath);
                    final newContent = _editorController.text;
                    await file.writeAsString(newContent);
                    workspaceCubit.saveActiveTab(newContent);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Saved: ${activeTab.fileName}')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save file: $e')),
                      );
                    }
                  }
                }
              },
            ),
            IconButton(
              icon: Icon(_isSidebarOpen ? Icons.view_sidebar : Icons.view_sidebar_outlined),
              tooltip: 'Toggle File Tree',
              onPressed: () => setState(() => _isSidebarOpen = !_isSidebarOpen),
            ),
            IconButton(
              icon: Icon(_isTerminalOpen ? Icons.terminal : Icons.terminal_outlined),
              tooltip: 'Toggle Terminal',
              onPressed: () => setState(() => _isTerminalOpen = !_isTerminalOpen),
            ),
          ],
        ),
        body: Column(
          children: [
            // Editor Workspace Split Panel
            Expanded(
              child: Row(
                children: [
                  // Sidebar Project File Tree
                  if (_isSidebarOpen)
                    Container(
                      width: 250,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: theme.dividerColor),
                        ),
                        color: theme.colorScheme.surface,
                      ),
                      child: BlocBuilder<ProjectExplorerCubit, ProjectExplorerState>(
                        builder: (context, state) {
                          if (state.isLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (state.fileTree.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('Workspace empty.'),
                              ),
                            );
                          }
                          return Scrollbar(
                            child: ListView(
                              children: [
                                FileTreeView(
                                  nodes: state.fileTree,
                                  onNodeTap: (node) => _onNodeTapped(context, node),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  
                  // Primary Editor canvas
                  Expanded(
                    child: BlocBuilder<WorkspaceCubit, WorkspaceState>(
                      builder: (context, state) {
                        final activeTab = state.activeTab;
                        if (activeTab == null) {
                          return const Center(
                            child: Text('Select a file to edit code.'),
                          );
                        }

                        return Column(
                          children: [
                            // Tab Bar layout
                            Container(
                              height: 40,
                              color: theme.colorScheme.surface,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: state.tabs.length,
                                itemBuilder: (context, idx) {
                                  final tab = state.tabs[idx];
                                  final isActive = idx == state.activeIndex;
                                  return GestureDetector(
                                    onTap: () => context.read<WorkspaceCubit>().selectTab(idx),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? theme.colorScheme.surface
                                            : Colors.transparent,
                                        border: Border(
                                          right: BorderSide(color: theme.dividerColor),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            tab.fileName,
                                            style: TextStyle(
                                              fontWeight:
                                                  isActive ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                          if (tab.isDirty)
                                            const Padding(
                                              padding: EdgeInsets.only(left: 4.0),
                                              child: Icon(Icons.circle, size: 8, color: Colors.blue),
                                            ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () => context.read<WorkspaceCubit>().closeTab(idx),
                                            child: const Icon(Icons.close, size: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            
                            // Editor Canvas widget
                            Expanded(
                              child: CodeEditor(
                                controller: _editorController,
                                onChanged: (value) {
                                  context.read<WorkspaceCubit>().updateActiveContent(_editorController.text);
                                },
                                style: CodeEditorStyle(
                                  fontSize: 14.0,
                                  codeTheme: CodeHighlightTheme(
                                    languages: const {},
                                    theme: const {},
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom Terminal view
            if (_isTerminalOpen)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: theme.dividerColor),
                  ),
                  color: Colors.black,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: Colors.grey[900],
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Terminal Output', style: TextStyle(color: Colors.white, fontSize: 12)),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 14),
                            onPressed: () => setState(() => _isTerminalOpen = false),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TerminalView(_terminal),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FileTreeView extends StatelessWidget {
  final List<FileNode> nodes;
  final Function(FileNode) onNodeTap;

  const FileTreeView({
    super.key,
    required this.nodes,
    required this.onNodeTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        final node = nodes[index];
        return _buildNodeItem(context, node);
      },
    );
  }

  Widget _buildNodeItem(BuildContext context, FileNode node) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.only(left: node.isDirectory ? 8.0 : 24.0),
          leading: Icon(
            node.isDirectory
                ? (node.isExpanded ? Icons.folder_open_outlined : Icons.folder_outlined)
                : Icons.insert_drive_file_outlined,
            size: 18,
            color: node.isDirectory ? Colors.amber[700] : theme.colorScheme.primary,
          ),
          title: Text(
            node.name,
            style: const TextStyle(fontSize: 13),
          ),
          onTap: () => onNodeTap(node),
        ),
        if (node.isDirectory && node.isExpanded && node.children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: FileTreeView(
              nodes: node.children,
              onNodeTap: onNodeTap,
            ),
          ),
      ],
    );
  }
}
