import 'dart:async';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

/// Lightweight in-app HTTP server for serving local workspace HTML/CSS/JS files.
/// Allows live web preview with relative links (<script src="app.js">) working 100%.
class LocalWebServerService {
  HttpServer? _server;
  int _port = 8080;
  String? _servingDirectory;

  bool get isRunning => _server != null;
  int get port => _port;
  String? get servingDirectory => _servingDirectory;

  /// Start serving [workspacePath] on local HTTP server.
  Future<int> startServer(String workspacePath, {int preferredPort = 8080}) async {
    if (_server != null && _servingDirectory == workspacePath) {
      return _port; // Already serving this workspace
    }

    await stopServer();

    final dir = Directory(workspacePath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final pipeline = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(createStaticHandler(
          workspacePath,
          defaultDocument: 'index.html',
          serveFilesOutsidePath: false,
        ));

    try {
      _server = await shelf_io.serve(pipeline, InternetAddress.loopbackIPv4, preferredPort);
      _port = _server!.port;
      _servingDirectory = workspacePath;
      return _port;
    } catch (_) {
      // If preferred port in use, bind to any available port (0)
      _server = await shelf_io.serve(pipeline, InternetAddress.loopbackIPv4, 0);
      _port = _server!.port;
      _servingDirectory = workspacePath;
      return _port;
    }
  }

  /// Get the full local HTTP URL for a given relative or absolute file path.
  String getPreviewUrl(String workspacePath, String filePath) {
    String relativePath = filePath;
    if (filePath.startsWith(workspacePath)) {
      relativePath = filePath.substring(workspacePath.length);
    }
    if (relativePath.startsWith('/') || relativePath.startsWith('\\')) {
      relativePath = relativePath.substring(1);
    }
    relativePath = relativePath.replaceAll('\\', '/');

    return 'http://127.0.0.1:$_port/$relativePath';
  }

  /// Stop the running server.
  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
    _servingDirectory = null;
  }
}
