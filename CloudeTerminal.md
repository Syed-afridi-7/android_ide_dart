# ☁️ Cloud Terminal Architecture Specification (`CloudTerminal.md`)

## 1. Vision & Purpose
To empower students and developers coding on mobile devices (Android) with a fast, lightweight, and fully functional Linux terminal environment. 

Instead of compiling native C++ binaries (`flutter_pty`, `dart:ffi`) on mobile devices—which causes NDK, Gradle, and storage permission errors—this module routes terminal I/O over a bi-directional WebSocket stream to an isolated cloud container running standard Ubuntu/Debian Linux.

---

## 2. Core Benefits
* **Universal Compatibility:** Works smoothly on low-end Android phones, Web, and Desktop.
* **Full Linux Command Suite:** Natively supports `git`, `python3`, `node`, `npm`, `gcc`, `java`, `bash`, and standard CLI utilities without mobile restrictions.
* **Zero Mobile Overhead:** Saves phone battery and RAM; execution happens on the server.
* **Clean Codebase:** No `dart:ffi` bindings, zero Android NDK setup, and zero local process leaks.

---

## 3. System Architecture Flow

```text
┌─────────────────────────────────────────────────────────────┐
│                       FLUTTER APP                           │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  TerminalView / xterm.dart (Canvas UI Widget)         │  │
│  └───────────────────────────┬───────────────────────────┘  │
│                              │ WebSockets (WSS)             │
└──────────────────────────────┼──────────────────────────────┘
                               │ wss://your-terminal-server.com
┌──────────────────────────────▼──────────────────────────────┐
│                      CLOUD BACKEND                          │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Node.js WebSocket Server (ws)                        │  │
│  └───────────────────────────┬───────────────────────────┘  │
│                              │ I/O Stream Pipe              │
│  ┌───────────────────────────▼───────────────────────────┐  │
│  │ node-pty (Spawns /bin/bash inside Docker Container)   │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘


4. Backend Implementation (server.js)
Deploy this lightweight server to Render, Fly.io, Railway, or any Linux VPS.

const WebSocket = require('ws');
const pty = require('node-pty');

const PORT = process.env.PORT || 8080;
const wss = new WebSocket.Server({ port: PORT });

console.log(`[Cloud Terminal] Server starting on port ${PORT}...`);

wss.on('connection', (ws) => {
  console.log('[Cloud Terminal] New client connected.');

  // Spawn an isolated Linux bash session
  const shell = pty.spawn('bash', [], {
    name: 'xterm-256color',
    cols: 80,
    rows: 30,
    cwd: process.env.HOME || '/root',
    env: process.env
  });

  // 1. Send shell output (stdout/stderr) to Flutter client
  shell.onData((data) => {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(data);
    }
  });

  // 2. Receive keystrokes from Flutter client and write to shell stdin
  ws.on('message', (message) => {
    shell.write(message.toString());
  });

  // Handle connection cleanup
  ws.on('close', () => {
    console.log('[Cloud Terminal] Client disconnected. Killing shell process.');
    shell.kill();
  });

  ws.on('error', (err) => {
    console.error('[Cloud Terminal] WebSocket Error:', err);
    shell.kill();
  });
});


5. Flutter Frontend Implementation (cloud_terminal_widget.dart)
Add web_socket_channel and xterm to your pubspec.yaml:

dependencies:
  flutter:
    sdk: flutter
  xterm: ^3.3.0
  web_socket_channel: ^3.0.0

  Flutter Component:

  import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:xterm/xterm.dart';

class CloudTerminalWidget extends StatefulWidget {
  final String websocketUrl; // Example: 'wss://your-cloud-terminal.onrender.com'

  const CloudTerminalWidget({
    Key? key,
    required this.websocketUrl,
  }) : super(key: key);

  @override
  State<CloudTerminalWidget> createState() => _CloudTerminalWidgetState();
}

class _CloudTerminalWidgetState extends State<CloudTerminalWidget> {
  late Terminal terminal;
  IOWebSocketChannel? _channel;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    terminal = Terminal(maxLines: 1000);
    _initTerminalConnection();
  }

  void _initTerminalConnection() {
    try {
      terminal.write('Connecting to cloud environment...\r\n');
      _channel = IOWebSocketChannel.connect(Uri.parse(widget.websocketUrl));

      setState(() {
        _isConnected = true;
      });

      // Stream incoming stdout from server to xterm canvas
      _channel!.stream.listen(
        (data) {
          terminal.write(data.toString());
        },
        onError: (error) {
          terminal.write('\r\n\x1B[31m[Connection Error]: $error\x1B[0m\r\n');
          setState(() => _isConnected = false);
        },
        onDone: () {
          terminal.write('\r\n\x1B[33m[Session Closed]\x1B[0m\r\n');
          setState(() => _isConnected = false);
        },
      );

      // Stream xterm user keystrokes directly to cloud stdin
      terminal.onInput = (data) {
        if (_isConnected && _channel != null) {
          _channel!.sink.add(data);
        }
      };
    } catch (e) {
      terminal.write('\r\n\x1B[31mFailed to establish WebSocket connection.\x1B[0m\r\n');
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: TerminalView(
          terminal,
          autofocus: true,
        ),
      ),
    );
  }
}

6. Development & Deployment Roadmap
[x] Phase 1: Document Cloud Terminal Specification (CloudTerminal.md).

[ ] Phase 2: Deploy server.js backend to a free host (Render / Fly.io / Railway) or a VPS.

[ ] Phase 3: Replace legacy flutter_pty service with CloudTerminalWidget.

[ ] Phase 4: Add Mobile Symbol Toolbar (Quick keys: Tab, {, }, [, ], ;, =>, Ctrl+C).

[ ] Phase 5: Handle terminal resize events (terminal.onResize -> send cols/rows payload to backend).