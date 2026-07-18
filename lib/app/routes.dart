import 'package:go_router/go_router.dart';
import 'package:android_ide/features/project_explorer/presentation/pages/project_explorer_page.dart';
import 'package:android_ide/features/code_editor/presentation/pages/editor_workspace_page.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ProjectExplorerPage(),
    ),
    GoRoute(
      path: '/editor',
      builder: (context, state) => const EditorWorkspacePage(),
    ),
  ],
);
