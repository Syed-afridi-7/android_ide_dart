import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service responsible for persisting and restoring open tab sessions on AppLifecycleState.paused / launch.
class TabSessionService {
  static const String _sessionFileName = 'tab_session_cache.json';

  Future<File> _getSessionFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _sessionFileName));
  }

  /// Save open tab session (paths, file names, cursor offset, scroll offset, active index).
  Future<void> saveSession({
    required List<TabSessionData> tabs,
    required int activeIndex,
  }) async {
    try {
      final file = await _getSessionFile();
      final data = {
        'activeIndex': activeIndex,
        'tabs': tabs.map((t) => t.toJson()).toList(),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  /// Restore tab session on app launch.
  Future<TabRestoreSession?> restoreSession() async {
    try {
      final file = await _getSessionFile();
      if (!await file.exists()) return null;

      final raw = await file.readAsString();
      if (raw.isEmpty) return null;

      final Map<String, dynamic> json = jsonDecode(raw);
      final activeIndex = json['activeIndex'] as int? ?? 0;
      final List<dynamic> rawTabs = json['tabs'] as List<dynamic>? ?? [];

      final tabs = rawTabs
          .map((item) => TabSessionData.fromJson(item as Map<String, dynamic>))
          .toList();

      return TabRestoreSession(tabs: tabs, activeIndex: activeIndex);
    } catch (_) {
      return null;
    }
  }
}

class TabSessionData {
  final String filePath;
  final String fileName;
  final int cursorOffset;
  final double scrollOffset;

  TabSessionData({
    required this.filePath,
    required this.fileName,
    this.cursorOffset = 0,
    this.scrollOffset = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'fileName': fileName,
        'cursorOffset': cursorOffset,
        'scrollOffset': scrollOffset,
      };

  factory TabSessionData.fromJson(Map<String, dynamic> json) => TabSessionData(
        filePath: json['filePath'] as String,
        fileName: json['fileName'] as String,
        cursorOffset: json['cursorOffset'] as int? ?? 0,
        scrollOffset: (json['scrollOffset'] as num? ?? 0.0).toDouble(),
      );
}

class TabRestoreSession {
  final List<TabSessionData> tabs;
  final int activeIndex;

  TabRestoreSession({required this.tabs, required this.activeIndex});
}
