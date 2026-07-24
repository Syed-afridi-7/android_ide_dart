import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/language_detector.dart';

enum RunnerStatus { idle, verifyingToolchain, running, webPreview, missingToolchain, failed }

class RunnerState {
  final RunnerStatus status;
  final String? activeFilePath;
  final LanguageInfo? languageInfo;
  final String? executionCommand;
  final String? webHtmlContent;
  final String? errorMessage;

  RunnerState({
    this.status = RunnerStatus.idle,
    this.activeFilePath,
    this.languageInfo,
    this.executionCommand,
    this.webHtmlContent,
    this.errorMessage,
  });

  RunnerState copyWith({
    RunnerStatus? status,
    String? activeFilePath,
    LanguageInfo? languageInfo,
    String? executionCommand,
    String? webHtmlContent,
    String? errorMessage,
  }) {
    return RunnerState(
      status: status ?? this.status,
      activeFilePath: activeFilePath ?? this.activeFilePath,
      languageInfo: languageInfo ?? this.languageInfo,
      executionCommand: executionCommand ?? this.executionCommand,
      webHtmlContent: webHtmlContent ?? this.webHtmlContent,
      errorMessage: errorMessage,
    );
  }
}

class RunnerCubit extends Cubit<RunnerState> {
  RunnerCubit() : super(RunnerState());

  void prepareForFile(String? filePath) {
    if (filePath == null) {
      emit(RunnerState());
      return;
    }
    final langInfo = LanguageDetector.detect(filePath);
    emit(state.copyWith(
      activeFilePath: filePath,
      languageInfo: langInfo,
      executionCommand: langInfo.buildExecutionCommand(filePath),
    ));
  }

  Future<void> triggerRun({required String filePath, required String content}) async {
    final langInfo = LanguageDetector.detect(filePath);

    if (langInfo.isWebPreview) {
      emit(RunnerState(
        status: RunnerStatus.webPreview,
        activeFilePath: filePath,
        languageInfo: langInfo,
        webHtmlContent: content,
      ));
      return;
    }

    emit(state.copyWith(status: RunnerStatus.verifyingToolchain));

    // Check if required binary exists on device
    final isToolchainAvailable = await langInfo.checkToolchainAvailable();

    if (!isToolchainAvailable) {
      emit(RunnerState(
        status: RunnerStatus.missingToolchain,
        activeFilePath: filePath,
        languageInfo: langInfo,
        errorMessage:
            'Toolchain "${langInfo.binaryName}" is not installed on device PATH.',
      ));
      return;
    }

    final command = langInfo.buildExecutionCommand(filePath);

    emit(RunnerState(
      status: RunnerStatus.running,
      activeFilePath: filePath,
      languageInfo: langInfo,
      executionCommand: command,
    ));
  }

  void reset() {
    emit(state.copyWith(status: RunnerStatus.idle));
  }
}
