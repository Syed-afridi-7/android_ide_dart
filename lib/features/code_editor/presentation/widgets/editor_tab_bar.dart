import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:android_ide/features/code_editor/presentation/state/workspace_cubit.dart';
import 'package:android_ide/core/utils/language_detector.dart';

class EditorTabBar extends StatelessWidget {
  const EditorTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<WorkspaceCubit, WorkspaceState>(
      builder: (context, state) {
        if (state.tabs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 38,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            border: Border(
              bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
            ),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: state.tabs.length,
            itemBuilder: (context, idx) {
              final tab = state.tabs[idx];
              final isActive = idx == state.activeIndex;
              final langInfo = LanguageDetector.detect(tab.filePath);

              return GestureDetector(
                onTap: () => context.read<WorkspaceCubit>().selectTab(idx),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.colorScheme.surface
                        : Colors.transparent,
                    border: Border(
                      top: BorderSide(
                        color: isActive ? langInfo.color : Colors.transparent,
                        width: 2,
                      ),
                      right: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        langInfo.icon,
                        size: 14,
                        color: langInfo.color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tab.fileName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (tab.isDirty)
                        Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => context.read<WorkspaceCubit>().closeTab(idx),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
