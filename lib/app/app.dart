import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:android_ide/core/di/providers.dart';
import 'package:android_ide/features/project_explorer/presentation/state/project_explorer_cubit.dart';
import 'package:android_ide/features/code_editor/presentation/state/workspace_cubit.dart';
import 'package:android_ide/features/runner_engine/presentation/state/runner_cubit.dart';
import 'package:android_ide/features/terminal/application/terminal_cubit.dart';
import 'routes.dart';
import 'theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: AppView(),
    );
  }
}

class AppView extends ConsumerWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileSystemService = ref.read(fileSystemServiceProvider);
    final tabSessionService = ref.read(tabSessionServiceProvider);
    final cloudTerminal = ref.read(cloudTerminalProvider);
    final localTerminal = ref.read(localTerminalProvider);
    final sshTerminal = ref.read(sshTerminalProvider);
    final localWebServer = ref.read(localWebServerProvider);
    final cloudSync = ref.read(cloudWorkspaceSyncProvider);

    return MultiBlocProvider(
      providers: [
        BlocProvider<ProjectExplorerCubit>(
          create: (context) => ProjectExplorerCubit(fileSystemService),
        ),
        BlocProvider<WorkspaceCubit>(
          create: (context) => WorkspaceCubit(fileSystemService, tabSessionService)..restoreSessionOnLaunch(),
        ),
        BlocProvider<RunnerCubit>(
          create: (context) => RunnerCubit(
            localWebServer: localWebServer,
            cloudSyncService: cloudSync,
          ),
        ),
        BlocProvider<TerminalCubit>(
          create: (context) => TerminalCubit(
            cloudService: cloudTerminal,
            localService: localTerminal,
            sshService: sshTerminal,
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'Android IDE',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: goRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
