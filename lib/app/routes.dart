import 'package:go_router/go_router.dart';
import 'package:android_ide/features/project_explorer/presentation/pages/project_explorer_page.dart';
import 'package:android_ide/features/code_editor/presentation/pages/editor_workspace_page.dart';
import 'package:android_ide/features/splash/presentation/splash_page.dart';

final goRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => SplashPage(
        onComplete: () => context.go('/'),
      ),
    ),
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
