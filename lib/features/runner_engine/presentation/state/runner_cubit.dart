// ignore_for_file: prefer_initializing_formals
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/language_detector.dart';
import '../../../../core/services/local_web_server_service.dart';
import '../../../../core/services/cloud_workspace_sync_service.dart';

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
  final LocalWebServerService _localWebServer;
  final CloudWorkspaceSyncService _cloudSyncService;

  RunnerCubit({
    required LocalWebServerService localWebServer,
    required CloudWorkspaceSyncService cloudSyncService,
  })  : _localWebServer = localWebServer,
        _cloudSyncService = cloudSyncService,
        super(RunnerState());

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

  Future<void> triggerRun({
    required String workspacePath,
    required String filePath,
    required String content,
  }) async {
    final langInfo = LanguageDetector.detect(filePath);

    if (langInfo.isWebPreview) {
      await _localWebServer.startServer(workspacePath);
      final previewUrl = _localWebServer.getPreviewUrl(workspacePath, filePath);
      emit(RunnerState(
        status: RunnerStatus.webPreview,
        activeFilePath: filePath,
        languageInfo: langInfo,
        webHtmlContent: previewUrl, // We store the url here per prompt requirements
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

    if (langInfo.type == LanguageType.javascript ||
        langInfo.type == LanguageType.python ||
        langInfo.type == LanguageType.shell) {
      await _cloudSyncService.syncSingleFile(workspacePath, filePath, content);
    }

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
