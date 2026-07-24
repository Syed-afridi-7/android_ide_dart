import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/file_system_service.dart';
import '../../../../core/services/tab_session_service.dart';
import '../../domain/entities/editor_tab.dart';

class WorkspaceState {
  final List<EditorTab> tabs;
  final int activeIndex;
  final bool isRestoringSession;

  WorkspaceState({
    required this.tabs,
    required this.activeIndex,
    this.isRestoringSession = false,
  });

  EditorTab? get activeTab =>
      tabs.isNotEmpty && activeIndex >= 0 && activeIndex < tabs.length
          ? tabs[activeIndex]
          : null;

  WorkspaceState copyWith({
    List<EditorTab>? tabs,
    int? activeIndex,
    bool? isRestoringSession,
  }) {
    return WorkspaceState(
      tabs: tabs ?? this.tabs,
      activeIndex: activeIndex ?? this.activeIndex,
      isRestoringSession: isRestoringSession ?? this.isRestoringSession,
    );
  }
}

class WorkspaceCubit extends Cubit<WorkspaceState> {
  final FileSystemService _fileSystemService;
  final TabSessionService _sessionService;

  WorkspaceCubit(this._fileSystemService, this._sessionService)
      : super(WorkspaceState(tabs: [], activeIndex: -1));

  /// Open a file in the tab strip. Uses FileSystemService to read disk if content is null.
  Future<void> openFile(
    String path,
    String name, {
    String? content,
    int cursorOffset = 0,
    double scrollOffset = 0.0,
  }) async {
    final existingIndex = state.tabs.indexWhere((tab) => tab.filePath == path);
    if (existingIndex != -1) {
      emit(state.copyWith(activeIndex: existingIndex));
      return;
    }

    String fileContent = content ?? '';
    if (content == null) {
      try {
        fileContent = await _fileSystemService.readFileAsString(path);
      } catch (_) {
        fileContent = '';
      }
    }

    final newTab = EditorTab(
      filePath: path,
      fileName: name,
      content: fileContent,
      savedContent: fileContent,
      cursorOffset: cursorOffset,
      scrollOffset: scrollOffset,
    );

    final updatedTabs = List<EditorTab>.from(state.tabs)..add(newTab);
    emit(state.copyWith(tabs: updatedTabs, activeIndex: updatedTabs.length - 1));
  }

  /// Update active tab content. Computes diffing against savedContent baseline.
  void updateActiveContent(String newContent) {
    if (state.activeTab == null) return;

    final targetTab = state.activeTab!;
    if (targetTab.content == newContent) return; // Ignore no-op re-renders

    final updatedTab = targetTab.copyWith(content: newContent);
    final updatedTabs = List<EditorTab>.from(state.tabs);
    updatedTabs[state.activeIndex] = updatedTab;

    emit(state.copyWith(tabs: updatedTabs));
  }

  /// Update cursor / scroll position metrics for current tab
  void updateTabPositions(int cursorOffset, double scrollOffset) {
    if (state.activeTab == null) return;

    final targetTab = state.activeTab!;
    final updatedTab = targetTab.copyWith(
      cursorOffset: cursorOffset,
      scrollOffset: scrollOffset,
    );
    final updatedTabs = List<EditorTab>.from(state.tabs);
    updatedTabs[state.activeIndex] = updatedTab;

    emit(state.copyWith(tabs: updatedTabs));
  }

  /// Save active tab through FileSystemService
  Future<bool> saveActiveTab([String? content]) async {
    if (state.activeTab == null) return false;

    final targetTab = state.activeTab!;
    final textToWrite = content ?? targetTab.content;

    try {
      await _fileSystemService.writeFileAsString(targetTab.filePath, textToWrite);

      final updatedTab = targetTab.copyWith(
        content: textToWrite,
        savedContent: textToWrite,
      );
      final updatedTabs = List<EditorTab>.from(state.tabs);
      updatedTabs[state.activeIndex] = updatedTab;

      emit(state.copyWith(tabs: updatedTabs));
      return true;
    } catch (_) {
      return false;
    }
  }

  void closeTab(int index) {
    if (index < 0 || index >= state.tabs.length) return;
    final updatedTabs = List<EditorTab>.from(state.tabs)..removeAt(index);
    int newActive = state.activeIndex;
    if (newActive >= updatedTabs.length) {
      newActive = updatedTabs.length - 1;
    }
    emit(state.copyWith(tabs: updatedTabs, activeIndex: newActive));
  }

  void selectTab(int index) {
    if (index < 0 || index >= state.tabs.length) return;
    emit(state.copyWith(activeIndex: index));
  }

  /// Serialize session to disk when Android pauses app lifecycle
  Future<void> persistSessionOnPause() async {
    if (state.tabs.isEmpty) return;

    final sessionTabs = state.tabs
        .map((t) => TabSessionData(
              filePath: t.filePath,
              fileName: t.fileName,
              cursorOffset: t.cursorOffset,
              scrollOffset: t.scrollOffset,
            ))
        .toList();

    await _sessionService.saveSession(
      tabs: sessionTabs,
      activeIndex: state.activeIndex,
    );
  }

  /// Restore tab session on app startup
  Future<void> restoreSessionOnLaunch() async {
    emit(state.copyWith(isRestoringSession: true));
    final session = await _sessionService.restoreSession();
    if (session != null && session.tabs.isNotEmpty) {
      for (final tabData in session.tabs) {
        await openFile(
          tabData.filePath,
          tabData.fileName,
          cursorOffset: tabData.cursorOffset,
          scrollOffset: tabData.scrollOffset,
        );
      }
      selectTab(session.activeIndex);
    }
    emit(state.copyWith(isRestoringSession: false));
  }
}
