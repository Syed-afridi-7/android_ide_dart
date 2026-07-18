import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/editor_tab.dart';

class WorkspaceState {
  final List<EditorTab> tabs;
  final int activeIndex;

  WorkspaceState({required this.tabs, required this.activeIndex});

  EditorTab? get activeTab =>
      tabs.isNotEmpty && activeIndex >= 0 && activeIndex < tabs.length
          ? tabs[activeIndex]
          : null;

  WorkspaceState copyWith({List<EditorTab>? tabs, int? activeIndex}) {
    return WorkspaceState(
      tabs: tabs ?? this.tabs,
      activeIndex: activeIndex ?? this.activeIndex,
    );
  }
}

class WorkspaceCubit extends Cubit<WorkspaceState> {
  WorkspaceCubit() : super(WorkspaceState(tabs: [], activeIndex: -1));

  void openFile(String path, String name, String content) {
    final existingIndex = state.tabs.indexWhere((tab) => tab.filePath == path);
    if (existingIndex != -1) {
      emit(state.copyWith(activeIndex: existingIndex));
      return;
    }

    final newTab = EditorTab(filePath: path, fileName: name, content: content);
    final updatedTabs = List<EditorTab>.from(state.tabs)..add(newTab);
    emit(state.copyWith(tabs: updatedTabs, activeIndex: updatedTabs.length - 1));
  }

  void updateActiveContent(String newContent) {
    if (state.activeTab == null) return;
    
    final updatedTab = state.activeTab!.copyWith(content: newContent, isDirty: true);
    final updatedTabs = List<EditorTab>.from(state.tabs);
    updatedTabs[state.activeIndex] = updatedTab;
    
    emit(state.copyWith(tabs: updatedTabs));
  }

  void saveActiveTab(String content) {
    if (state.activeTab == null) return;

    final updatedTab = state.activeTab!.copyWith(content: content, isDirty: false);
    final updatedTabs = List<EditorTab>.from(state.tabs);
    updatedTabs[state.activeIndex] = updatedTab;

    emit(state.copyWith(tabs: updatedTabs));
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
}
