import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/file_node.dart';
import '../../domain/entities/project.dart';

class ProjectExplorerState {
  final Project? activeProject;
  final List<FileNode> fileTree;
  final bool isLoading;
  final String? errorMessage;

  ProjectExplorerState({
    this.activeProject,
    this.fileTree = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ProjectExplorerState copyWith({
    Project? activeProject,
    List<FileNode>? fileTree,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProjectExplorerState(
      activeProject: activeProject ?? this.activeProject,
      fileTree: fileTree ?? this.fileTree,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ProjectExplorerCubit extends Cubit<ProjectExplorerState> {
  ProjectExplorerCubit() : super(ProjectExplorerState());

  void openProject(String name, String path) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final project = Project(
        name: name,
        rootPath: path,
        primaryLanguage: 'unknown',
        lastOpened: DateTime.now(),
      );

      final nodes = await _loadDirectory(path);
      emit(state.copyWith(
        activeProject: project,
        fileTree: nodes,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to open project: ${e.toString()}',
      ));
    }
  }

  void toggleDirectoryExpansion(String path) async {
    if (state.activeProject == null) return;
    
    final updatedTree = await _toggleNodeInList(state.fileTree, path);
    emit(state.copyWith(fileTree: updatedTree));
  }

  Future<List<FileNode>> _toggleNodeInList(List<FileNode> list, String targetPath) async {
    final List<FileNode> result = [];
    for (final node in list) {
      if (node.path == targetPath) {
        if (node.isDirectory) {
          final nextExpanded = !node.isExpanded;
          List<FileNode> children = node.children;
          if (nextExpanded && children.isEmpty) {
            children = await _loadDirectory(node.path);
          }
          result.add(node.copyWith(
            isExpanded: nextExpanded,
            children: children,
          ));
        } else {
          result.add(node);
        }
      } else if (node.isDirectory && node.isExpanded) {
        final updatedChildren = await _toggleNodeInList(node.children, targetPath);
        result.add(node.copyWith(children: updatedChildren));
      } else {
        result.add(node);
      }
    }
    return result;
  }

  Future<List<FileNode>> _loadDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return [];

    final List<FileNode> nodes = [];
    try {
      final List<FileSystemEntity> entities = await dir.list().toList();

      for (final entity in entities) {
        final name = entity.path.split('/').last;
        final isDirectory = entity is Directory;
        int size = 0;
        if (entity is File) {
          try {
            size = await entity.length();
          } catch (_) {}
        }

        nodes.add(FileNode(
          path: entity.path,
          name: name,
          isDirectory: isDirectory,
          sizeBytes: size,
        ));
      }

      // Sort directories first, then alphabetical
      nodes.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    } catch (_) {}
    return nodes;
  }
}
