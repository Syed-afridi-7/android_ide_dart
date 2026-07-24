# Android IDE

A professional, mobile-first, VS Code-inspired Integrated Development Environment (IDE) built using Flutter (Dart). Designed for daily software engineering on Android, this application delivers a 100% full-screen code editing canvas, off-thread PTY terminal isolation, reactive file watching, and touch-first developer tools.

---

## 🚀 Key Features & Architectural Highlights

* **100% Full-Screen Code Canvas**: Center-stage editor powered by `re_editor` featuring line-number gutters, auto-indentation, touch text selection, and multi-language syntax themes (`atomOneDarkTheme`) via `re_highlight`.
* **Modal Popup Workspace Explorer**: Floating 75% height modal bottom sheet workspace explorer with lazy tree loading (`FileNode`), recursive sub-directory expansion, touch-first CRUD context actions, and reactive file system patching via `watcher`. Auto-dismisses upon selecting a file.
* **Off-Main-Thread PTY Terminal Overlay**: Floating 60% height modal bottom sheet xterm terminal console powered by `flutter_pty`. Runs stdout read loops inside a dedicated background `Isolate` with a **16ms frame-coalescing buffer** (~60fps), eliminating main-thread UI jank during high-volume terminal output.
* **Language-Aware Run Execution Pipeline**: Context-aware RUN engine that verifies on-device toolchain availability (`python3`, `node`, `gcc`, `g++`, `javac`, `dart`, `bash`) before piping commands into the active PTY isolate stream. Features an integrated HTML5 Webview Live Preview modal with responsive viewport switching (375px mobile, 768px tablet, 100% full).
* **Android Lifecycle Session Persistence**: Catches `AppLifecycleState.paused` events to automatically serialize open tab paths, active indices, cursor positions, and scroll offsets to JSON via `TabSessionService`, restoring your workspace seamlessly after low-memory process kills.
* **Touch-First Developer Productivity**:
  * **Keyboard Symbol Bar**: Access bar (`{ } ( ) [ ] ; : = " ' < > / \ + - * & | ! ? _ $ Tab`) pinned below the code canvas for rapid symbol entry without soft-keyboard switching.
  * **VS Code Command Palette**: `Ctrl+Shift+P` style action search modal (`CommandPaletteModal`) for instant keyboard or touch execution of IDE commands.
  * **Git Status Indicators**: Visual status badges (`M`, `A`, `U`, `D`) on workspace file nodes via `git2dart`.

---

## 🏗️ Architectural Boundaries & Layering

The application enforces a strict separation between global infrastructure DI (`flutter_riverpod`) and feature UI state machines (`flutter_bloc`):

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                     Global Infrastructure & Services Layer                      │
│                               (Flutter Riverpod)                                │
│                                                                                 │
│  • FileSystemService (dart:io operations, recursive watcher stream pipeline)    │
│  • TabSessionService (AppLifecycleState.paused JSON session persistence)        │
│  • TerminalIsolateService (Off-main-thread PTY Isolate, 16ms frame coalescer)   │
└──────────────────────────────────────┬──────────────────────────────────────────┘
                                       │
                              Riverpod DI Injection
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────────┐
│                          Feature UI & State Layer                               │
│                              (Flutter BLoC/Cubit)                               │
│                                                                                 │
│  • ProjectExplorerCubit (Lazy tree expansion, tree patch, file CRUD)            │
│  • WorkspaceCubit (Multi-tab strip, debounced baseline diffing, dirty dots)     │
│  • TerminalCubit (16ms frame stream writer, PTY process input piping)           │
│  • RunnerCubit (On-device toolchain verifier, execution command builder)        │
└──────────────────────────────────────┬──────────────────────────────────────────┘
                                       │
                             Reactive State Listeners
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────────┐
│                         Touch-First UI Components                               │
│                                                                                 │
│  • WorkspaceDrawer (Floating 75% height modal bottom sheet explorer)            │
│  • EditorTopActionBar (Dynamic RUN button, Command Palette, Terminal launcher)  │
│  • KeyboardSymbolBar (Fast symbol accessory bar: { } ( ) [ ] ; : Tab)          │
│  • LivePreviewModal (HTML5 Webview preview with 375px/768px/100% viewports)     │
│  • TerminalDockModal (Floating 60% height modal bottom sheet xterm terminal)    │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Android Permissions & 16KB NDK Page Alignment

* **Storage Access**: Integrates `MANAGE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE`, and `WRITE_EXTERNAL_STORAGE` permissions via `permission_handler` on startup to enable full access to device filesystems (`/storage/emulated/0/...`).
* **16KB NDK Alignment**: `android/app/build.gradle.kts` specifies 16KB max page size linker flags (`-z max-page-size=16384`) to satisfy Android 15+ 16KB memory page alignment mandates for native shared libraries (`libpty.so`, `libgit2.so`).

---

## 📂 Project Structure

```
lib/
├── app/
│   ├── app.dart                        # Global ProviderScope & MultiBlocProvider
│   ├── routes.dart                     # Endpoint routing configuration (go_router)
│   └── theme.dart                      # Dark Slate & Light M3 Theme definitions
├── core/
│   ├── di/providers.dart               # Riverpod Providers for FileSystem, TabSession & Isolate
│   ├── services/
│   │   ├── file_system_service.dart    # I/O operations & DirectoryWatcher streams
│   │   ├── tab_session_service.dart    # Session JSON serialization & restoration
│   │   └── terminal_isolate_service.dart# Off-thread PTY Isolate & 16ms frame coalescer
│   └── utils/
│       └── language_detector.dart      # Extension parsing & toolchain verifier
└── features/
    ├── project_explorer/               # Lazy FileNode tree & WorkspaceDrawer modal
    ├── code_editor/                    # re_editor canvas, EditorTabBar, KeyboardSymbolBar
    ├── runner_engine/                  # RunnerCubit & LivePreviewModal
    ├── command_palette/                # Searchable CommandPaletteModal (Ctrl+Shift+P)
    └── terminal/                       # TerminalCubit & TerminalDockModal overlay
```

---

## 🏁 Getting Started

### Prerequisites
* **Flutter SDK**: `3.27.0` or higher
* **Dart SDK**: `3.12.2` or higher
* **Android SDK**: Platform API Level `36`

### Setup & Run
1. Clone the repository:
   ```bash
   git clone https://github.com/Syed-afridi-7/android_ide_dart.git
   cd android_ide_dart
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run static analysis:
   ```bash
   flutter analyze
   ```
4. Launch on target device:
   ```bash
   flutter run -d <YOUR_DEVICE_ID>
   ```

---

## 📄 License & Reference Blueprint
System architecture design specifications and lifecycle details are documented in [android_ide_blueprint.md](android_ide_blueprint.md).
