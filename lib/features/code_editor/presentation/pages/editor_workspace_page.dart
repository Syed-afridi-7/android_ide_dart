import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/java.dart';
import 'package:re_highlight/languages/cpp.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/languages/bash.dart';
import 'package:re_highlight/styles/atom-one-dark.dart';

import 'package:android_ide/features/project_explorer/presentation/state/project_explorer_cubit.dart';
import 'package:android_ide/features/project_explorer/presentation/widgets/workspace_drawer.dart';
import 'package:android_ide/features/code_editor/presentation/state/workspace_cubit.dart';
import 'package:android_ide/features/code_editor/presentation/widgets/editor_top_action_bar.dart';
import 'package:android_ide/features/code_editor/presentation/widgets/editor_tab_bar.dart';
import 'package:android_ide/features/code_editor/presentation/widgets/keyboard_symbol_bar.dart';
import 'package:android_ide/features/terminal/application/terminal_cubit.dart';
import 'package:android_ide/features/terminal/presentation/widgets/terminal_dock.dart';

class EditorWorkspacePage extends StatefulWidget {
  const EditorWorkspacePage({super.key});

  @override
  State<EditorWorkspacePage> createState() => _EditorWorkspacePageState();
}

class _EditorWorkspacePageState extends State<EditorWorkspacePage> with WidgetsBindingObserver {
  final CodeLineEditingController _editorController = CodeLineEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _currentlyEditingPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _editorController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      context.read<WorkspaceCubit>().persistSessionOnPause();
    }
  }

  void _onSaveFile(BuildContext context) async {
    final workspaceCubit = context.read<WorkspaceCubit>();
    final activeTab = workspaceCubit.state.activeTab;
    if (activeTab != null) {
      final success = await workspaceCubit.saveActiveTab(_editorController.text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Saved: ${activeTab.fileName}' : 'Failed to save file.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _insertSymbol(String symbol) {
    final text = _editorController.text;
    final newText = text + symbol;
    _editorController.text = newText;
    context.read<WorkspaceCubit>().updateActiveContent(newText);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<ProjectExplorerCubit, ProjectExplorerState>(
          listener: (context, explorerState) {
            final openReq = explorerState.pendingOpenRequest;
            if (openReq != null) {
              context.read<WorkspaceCubit>().openFile(openReq.path, openReq.name);
            }
          },
        ),
        BlocListener<WorkspaceCubit, WorkspaceState>(
          listener: (context, state) {
            final activeTab = state.activeTab;
            if (activeTab != null) {
              if (activeTab.filePath != _currentlyEditingPath) {
                setState(() {
                  _currentlyEditingPath = activeTab.filePath;
                  _editorController.text = activeTab.content;
                });
              }
            } else {
              if (_currentlyEditingPath != null) {
                setState(() {
                  _currentlyEditingPath = null;
                  _editorController.text = '';
                });
              }
            }
          },
        ),
        BlocListener<TerminalCubit, TerminalDockState>(
          listenWhen: (previous, current) => !previous.isOpen && current.isOpen,
          listener: (context, terminalState) {
            showTerminalModalBottomSheet(context);
          },
        ),
      ],
      child: Scaffold(
        key: _scaffoldKey,
        appBar: EditorTopActionBar(
          onToggleSidebar: () {
            WorkspaceDrawer.showModalBottomSheet(context);
          },
          onSaveFile: () => _onSaveFile(context),
        ),
        drawer: Drawer(
          child: WorkspaceDrawer(
            isModal: true,
            onClose: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // 1. Horizontal Multi-Tab Strip
            const EditorTabBar(),

            // 2. 100% Full-Screen Code Canvas
            Expanded(
              child: BlocBuilder<WorkspaceCubit, WorkspaceState>(
                builder: (context, state) {
                  final activeTab = state.activeTab;
                  if (activeTab == null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.code,
                            size: 64,
                            color: theme.colorScheme.primary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No File Opened',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Open Explorer'),
                            onPressed: () {
                              WorkspaceDrawer.showModalBottomSheet(context);
                            },
                          ),
                        ],
                      ),
                    );
                  }

                  return CodeEditor(
                    controller: _editorController,
                    onChanged: (value) {
                      context
                          .read<WorkspaceCubit>()
                          .updateActiveContent(_editorController.text);
                    },
                    style: CodeEditorStyle(
                      fontSize: 14.0,
                      codeTheme: CodeHighlightTheme(
                        languages: {
                          'python': CodeHighlightThemeMode(mode: langPython),
                          'js': CodeHighlightThemeMode(mode: langJavascript),
                          'java': CodeHighlightThemeMode(mode: langJava),
                          'cpp': CodeHighlightThemeMode(mode: langCpp),
                          'c': CodeHighlightThemeMode(mode: langCpp),
                          'html': CodeHighlightThemeMode(mode: langXml),
                          'dart': CodeHighlightThemeMode(mode: langDart),
                          'sh': CodeHighlightThemeMode(mode: langBash),
                        },
                        theme: atomOneDarkTheme,
                      ),
                    ),
                  );
                },
              ),
            ),

            // 3. Touch-First Keyboard Symbol Accessory Bar (Below code canvas)
            KeyboardSymbolBar(
              onSymbolTap: _insertSymbol,
              onTabTap: () => _insertSymbol('  '),
            ),
          ],
        ),
      ),
    );
  }
}
