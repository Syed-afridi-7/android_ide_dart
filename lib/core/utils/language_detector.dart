import 'dart:io';
import 'package:flutter/material.dart';

enum LanguageType {
  python,
  javascript,
  c,
  cpp,
  java,
  html,
  dart,
  shell,
  unknown,
}

class LanguageInfo {
  final LanguageType type;
  final String displayName;
  final String binaryName;
  final String runnerCommandTemplate;
  final IconData icon;
  final Color color;
  final bool isWebPreview;

  const LanguageInfo({
    required this.type,
    required this.displayName,
    required this.binaryName,
    required this.runnerCommandTemplate,
    required this.icon,
    required this.color,
    this.isWebPreview = false,
  });

  /// Check if the required binary/toolchain exists on device PATH
  Future<bool> checkToolchainAvailable() async {
    if (isWebPreview || binaryName.isEmpty) return true;
    try {
      final result = await Process.run(
        Platform.isWindows ? 'where' : 'which',
        [binaryName],
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Construct execution command string for a target file path
  String buildExecutionCommand(String filePath) {
    if (isWebPreview) return 'live-preview';
    return runnerCommandTemplate.replaceAll('{file}', '"$filePath"');
  }
}

class LanguageDetector {
  static LanguageInfo detect(String filePath) {
    final ext = filePath.contains('.')
        ? filePath.split('.').last.toLowerCase()
        : '';

    switch (ext) {
      case 'py':
        return const LanguageInfo(
          type: LanguageType.python,
          displayName: 'Python 3',
          binaryName: 'python3',
          runnerCommandTemplate: 'python3 {file}',
          icon: Icons.code,
          color: Color(0xFF3572A5),
        );
      case 'js':
        return const LanguageInfo(
          type: LanguageType.javascript,
          displayName: 'Node.js',
          binaryName: 'node',
          runnerCommandTemplate: 'node {file}',
          icon: Icons.javascript,
          color: Color(0xFFF1E05A),
        );
      case 'c':
        return const LanguageInfo(
          type: LanguageType.c,
          displayName: 'C (GCC)',
          binaryName: 'gcc',
          runnerCommandTemplate: 'gcc {file} -o /tmp/c_out && /tmp/c_out',
          icon: Icons.integration_instructions,
          color: Color(0xFF555555),
        );
      case 'cpp':
      case 'cc':
      case 'cxx':
        return const LanguageInfo(
          type: LanguageType.cpp,
          displayName: 'C++ (G++)',
          binaryName: 'g++',
          runnerCommandTemplate: 'g++ {file} -o /tmp/cpp_out && /tmp/cpp_out',
          icon: Icons.data_object,
          color: Color(0xFFF34B7D),
        );
      case 'java':
        return const LanguageInfo(
          type: LanguageType.java,
          displayName: 'Java (OpenJDK)',
          binaryName: 'javac',
          runnerCommandTemplate: 'javac {file} && java {file}',
          icon: Icons.coffee,
          color: Color(0xFFB07219),
        );
      case 'html':
      case 'htm':
        return const LanguageInfo(
          type: LanguageType.html,
          displayName: 'HTML5 Webview',
          binaryName: '',
          runnerCommandTemplate: 'live-preview',
          icon: Icons.html,
          color: Color(0xFFE34C26),
          isWebPreview: true,
        );
      case 'dart':
        return const LanguageInfo(
          type: LanguageType.dart,
          displayName: 'Dart VM',
          binaryName: 'dart',
          runnerCommandTemplate: 'dart run {file}',
          icon: Icons.flutter_dash,
          color: Color(0xFF00B4AB),
        );
      case 'sh':
      case 'bash':
        return const LanguageInfo(
          type: LanguageType.shell,
          displayName: 'Bash Shell',
          binaryName: 'bash',
          runnerCommandTemplate: 'bash {file}',
          icon: Icons.terminal,
          color: Color(0xFF89E051),
        );
      default:
        return const LanguageInfo(
          type: LanguageType.unknown,
          displayName: 'Text / Binary',
          binaryName: '',
          runnerCommandTemplate: '',
          icon: Icons.text_snippet_outlined,
          color: Colors.grey,
        );
    }
  }
}
