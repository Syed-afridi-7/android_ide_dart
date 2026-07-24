import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watcher/watcher.dart';
import 'package:path/path.dart' as p;
import '../../../../core/services/file_system_service.dart';
import '../../domain/entities/file_node.dart';
import '../../domain/entities/project.dart';

class FileOpenRequest {
  final String path;
  final String name;
  final DateTime timestamp;

  FileOpenRequest({required this.path, required this.name, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

class ProjectExplorerState {
  final Project? activeProject;
  final List<FileNode> fileTree;
  final String? activeWorkingDirectory;
  final bool isLoading;
  final String? errorMessage;
  final String? notificationMessage;
  final FileOpenRequest? pendingOpenRequest;

  ProjectExplorerState({
    this.activeProject,
    this.fileTree = const [],
    this.activeWorkingDirectory,
    this.isLoading = false,
    this.errorMessage,
    this.notificationMessage,
    this.pendingOpenRequest,
  });

  ProjectExplorerState copyWith({
    Project? activeProject,
    List<FileNode>? fileTree,
    String? activeWorkingDirectory,
    bool? isLoading,
    String? errorMessage,
    String? notificationMessage,
    FileOpenRequest? pendingOpenRequest,
  }) {
    return ProjectExplorerState(
      activeProject: activeProject ?? this.activeProject,
      fileTree: fileTree ?? this.fileTree,
      activeWorkingDirectory: activeWorkingDirectory ?? this.activeWorkingDirectory,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      notificationMessage: notificationMessage,
      pendingOpenRequest: pendingOpenRequest,
    );
  }
}

class ProjectExplorerCubit extends Cubit<ProjectExplorerState> {
  final FileSystemService _fileSystemService;
  StreamSubscription<WatchEvent>? _watcherSubscription;

  ProjectExplorerCubit(this._fileSystemService) : super(ProjectExplorerState());

  @override
  Future<void> close() {
    _watcherSubscription?.cancel();
    return super.close();
  }

  void openProject(String name, String path) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final project = Project(
        name: name,
        rootPath: path,
        primaryLanguage: 'unknown',
        lastOpened: DateTime.now(),
      );

      // Lazily list root directory (level 1 only)
      final nodes = await _fileSystemService.listDirectory(path);

      // Subscribe to real-time directory watcher events
      _setupWatcher(path);

      emit(state.copyWith(
        activeProject: project,
        fileTree: nodes,
        activeWorkingDirectory: path,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to open project workspace: ${e.toString()}',
      ));
    }
  }

  void _setupWatcher(String rootPath) {
    _watcherSubscription?.cancel();
    final stream = _fileSystemService.watchWorkspace(rootPath);
    if (stream != null) {
      _watcherSubscription = stream.listen((event) {
        // Automatically patch tree when filesystem changes externally
        refreshActiveNode(p.dirname(event.path));
      });
    }
  }

  void setActiveWorkingDirectory(String path) {
    emit(state.copyWith(activeWorkingDirectory: path));
  }

  void requestOpenFile(String path, String name) {
    emit(state.copyWith(
      pendingOpenRequest: FileOpenRequest(path: path, name: name),
    ));
  }

  /// Toggle node expansion. Lazily fetches children from FileSystemService if expanding for the first time.
  Future<void> toggleDirectoryExpansion(String targetPath) async {
    final updatedTree = await _toggleNodeInList(state.fileTree, targetPath);
    emit(state.copyWith(
      fileTree: updatedTree,
      activeWorkingDirectory: targetPath,
    ));
  }

  Future<List<FileNode>> _toggleNodeInList(List<FileNode> list, String targetPath) async {
    final List<FileNode> result = [];
    for (final node in list) {
      if (node.path == targetPath) {
        if (node.isDirectory) {
          final nextExpanded = !node.isExpanded;
          List<FileNode> children = node.children;
          bool isLoaded = node.isLoaded;

          // Lazy load sub-directory children if expanding first time
          if (nextExpanded && (!isLoaded || children.isEmpty)) {
            children = await _fileSystemService.listDirectory(node.path);
            isLoaded = true;
          }

          result.add(node.copyWith(
            isExpanded: nextExpanded,
            isLoaded: isLoaded,
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

  /// Refreshes children of a specific expanded directory or root
  Future<void> refreshActiveNode([String? dirPath]) async {
    if (state.activeProject == null) return;
    final targetPath = dirPath ?? state.activeProject!.rootPath;

    if (targetPath == state.activeProject!.rootPath) {
      final nodes = await _fileSystemService.listDirectory(targetPath);
      emit(state.copyWith(fileTree: nodes));
    } else {
      final updatedTree = await _refreshNodeChildren(state.fileTree, targetPath);
      emit(state.copyWith(fileTree: updatedTree));
    }
  }

  Future<List<FileNode>> _refreshNodeChildren(List<FileNode> list, String targetPath) async {
    final List<FileNode> result = [];
    for (final node in list) {
      if (node.path == targetPath && node.isDirectory) {
        final freshChildren = await _fileSystemService.listDirectory(targetPath);
        result.add(node.copyWith(
          children: freshChildren,
          isLoaded: true,
        ));
      } else if (node.isDirectory && node.isExpanded) {
        final updatedChildren = await _refreshNodeChildren(node.children, targetPath);
        result.add(node.copyWith(children: updatedChildren));
      } else {
        result.add(node);
      }
    }
    return result;
  }

  // CRUD Operations routing exclusively through FileSystemService

  Future<bool> createFile(String parentDirPath, String fileName, {String content = ''}) async {
    try {
      await _fileSystemService.createFile(parentDirPath, fileName, content: content);
      await refreshActiveNode(parentDirPath);
      emit(state.copyWith(notificationMessage: 'Created file: $fileName'));
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to create file: $e'));
      return false;
    }
  }

  Future<bool> createDirectory(String parentDirPath, String folderName) async {
    try {
      await _fileSystemService.createDirectory(parentDirPath, folderName);
      await refreshActiveNode(parentDirPath);
      emit(state.copyWith(notificationMessage: 'Created directory: $folderName'));
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to create directory: $e'));
      return false;
    }
  }

  Future<bool> renameNode(String currentPath, String newName) async {
    try {
      await _fileSystemService.renameEntity(currentPath, newName);
      await refreshActiveNode(p.dirname(currentPath));
      emit(state.copyWith(notificationMessage: 'Renamed to $newName'));
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to rename: $e'));
      return false;
    }
  }

  Future<bool> deleteNode(String targetPath) async {
    try {
      await _fileSystemService.deleteEntity(targetPath);
      await refreshActiveNode(p.dirname(targetPath));
      emit(state.copyWith(notificationMessage: 'Deleted ${p.basename(targetPath)}'));
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to delete: $e'));
      return false;
    }
  }
}
