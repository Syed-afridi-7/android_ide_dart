//Architectural Plan: Mobile IDE Engine


┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                ANDROID IDE CLIENT (UI)                                 │
│                                                                                        │
│   ┌────────────────────────────────┐         ┌─────────────────────────────────────┐   │
│   │   Monaco / Code Editor         │         │   Quick-Symbol Key Toolbar          │   │
│   └───────────────┬────────────────┘         └─────────────────────────────────────┘   │
│                   │                                                                    │
│   ┌───────────────▼────────────────────────────────────────────────────────────────┐   │
│   │   Terminal Mode Modal / Launcher                                               │   │
│   └───────────────┬─────────────────────────────────┬──────────────────────────────┘   │
└───────────────────┼─────────────────────────────────┼──────────────────────────────────┘
                    │                                 │
     [ Terminal Mode Selector ]               [ File Execution Handler ]
                    │                                 │
        ┌───────────┴───────────┐         ┌───────────┴───────────┐
        │                       │         │                       │
        ▼                       ▼         ▼                       ▼
┌───────────────┐       ┌───────────────┐ ┌───────────────┐       ┌───────────────┐
│ Local Shell   │       │ Cloud SSH /   │ │ HTML WebView  │       │ Cloud Exec    │
│ Engine        │       │ WebSocket     │ │ Preview       │       │ Engine        │
│ (/system/bin) │       │ (WSS Engine)  │ │ (In-App)      │       │ (Node/Python) │
└───────┬───────┘       └───────┬───────┘ └───────┬───────┘       └───────┬───────┘
        │                       │                 │                       │
        │                       │ Sync Daemon     │                       │
        │                       ▼                 │                       │
        │             ┌───────────────────┐       │                       │
        └────────────►│  Local Storage    │◄──────┴───────────────────────┘
                      │  Engine (/sdcard) │
                      └───────────────────┘


1. Unified Terminal Engine (Local vs. Cloud)
A. Single Entry Point Launcher
The UI features a unified terminal dock. Upon pressing New Terminal or opening the dock, a non-blocking modal prompts the user:

Option 1: 📱 Local Terminal (Offline Mode)

Spawns Android’s native sandboxed shell (/system/bin/sh or a bundled busybox environment).

Direct low-latency execution for file inspection, local scripts, and offline DSA practice.

Option 2: ☁️ Cloud Terminal (Online Container)

Establishes a persistent bi-directional WebSocket connection (wss://) to a containerized cloud Linux environment (node-pty / Ubuntu).

Provides full git, npm, pip, and heavy toolchain support.

B. Local Storage Access & Synchronization
Local Terminal Access: Operates directly on the app's sandboxed storage directory (/data/user/0/com.example.android_ide/app_flutter/workspace).

Cloud Terminal Access (File Syncing): To ensure the Cloud Terminal has real-time access to local files, a Sync Daemon runs in the background:

On Connection: Performs a delta synchronization using rsync or WebSocket chunk streaming to push the local project folder to /root/workspace inside the cloud container.

File Change Watcher: Listens for file mutations (fswatch / Watcher) in the IDE editor and streams text diffs over WebSockets to keep cloud files updated in real time.

2. Dynamic Context-Aware Execution Engine
When the user taps the Run button, the IDE checks the active file extension and routes execution accordingly:


File Type,Execution Route,Mechanism,Target Component
"*.js, *.ts",Cloud Execution,Streams file contents to Cloud Backend via WebSocket API. Executes node file.js and pipes stdout/stderr back to the UI.,Cloud Terminal Dock
"*.html, *.css",Local Web View,Starts an in-app local HTTP server (shelf or localhost:8080) serving the project folder. Loads the preview in an embedded InAppWebView.,Embedded Live Preview Modal
*.py,Hybrid / Offline,Offline: Runs via an embedded CPython runtime (using packages like serious_python).Online: Runs python3 file.py on the Cloud Container.,Terminal Dock / Output Sheet

3. Implementation Plan & Roadmap

Phase 1: Local Terminal Engine (Offline Foundation)
Integrate an Android terminal emulator view (e.g., xterm canvas wrapper).

Bind local terminal input/output streams to Android’s /system/bin/sh shell process.

Configure scoped local file system read/write access under storage permissions.


Phase 2: Cloud Sync & Execution Engine
Build a Node.js + ws + node-pty WebSocket backend container.

Implement CloudTerminalAdapter using WebSocket streams (web_socket_channel).

Implement background file diff sync daemon between local device storage and the cloud workspace.


Phase 3: Execution RouterBuild the ExecutionRouter class that parses the active file extension (.html, .js, .py).Wire up dynamic routing:.html $\rightarrow$ Embedded InAppWebView preview..js $\rightarrow$ Cloud Node.js runner..py $\rightarrow$ Embedded Python runtime / Cloud runner fallback.


Phase 4: UI/UX & Mobile Refinements
Add terminal mode selection dialogs and status indicators (Online/Offline badges).

Integrate an ergonomic mobile symbol toolbar ({ }, [ ], =>, Tab, directional arrows) directly above the soft keyboard.

Implement auto-reconnection logic for WebSockets when switching networks.