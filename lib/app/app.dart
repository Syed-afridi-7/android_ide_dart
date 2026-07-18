import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:android_ide/features/project_explorer/presentation/state/project_explorer_cubit.dart';
import 'package:android_ide/features/code_editor/presentation/state/workspace_cubit.dart';
import 'routes.dart';
import 'theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ProjectExplorerCubit>(
            create: (context) => ProjectExplorerCubit(),
          ),
          BlocProvider<WorkspaceCubit>(
            create: (context) => WorkspaceCubit(),
          ),
        ],
        child: MaterialApp.router(
          title: 'Android IDE',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system, // Dynamically match system preferences
          routerConfig: goRouter,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
