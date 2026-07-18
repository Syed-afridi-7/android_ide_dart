# Android IDE

A professional, scalable, and feature-rich mobile Integrated Development Environment (IDE) built using Flutter (Dart). This application delivers a desktop-like software development experience directly on Android devices.

---

## 🚀 Key Features

*   **Advanced Code Editor**: Multi-tab workspace workspace powered by `re_editor` featuring virtualized line rendering (maintaining 60fps/120fps on large files), syntax highlighting, and local document synchronization.
*   **Project & File Management**: High-speed asynchronous directory explorer mapping with expand/collapse logic and direct local filesystem read/write bridges.
*   **Integrated Developer Tools**: 
    *   In-app Pseudo-Terminal console utilizing the `xterm` grid system and `flutter_pty` streams.
    *   Local process execution pipelines allowing native script parsing and target binary compilation.
    *   Null-safe version control client using `git2dart` to initialize, clone, diff, commit, and push repositories over secure HTTPS channels without relying on external system Git binaries.
*   **Modern Material 3 Theme**: Dark Slate and Light themes with dynamic accent adaptions conforming to Android system preferences.

---

## 🏗️ System Architecture

The application separates UI rendering, platform bindings, and low-level compilers into dedicated clean architecture layers:

```
┌────────────────────────────────────────────────────────┐
│               Flutter UI Layer (Dart)                  │
│  Multi-tab Editor  ·  File Explorer  ·  Terminal UI    │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│     Native Interop / FFI (git2dart / flutter_pty)      │
│  Direct low-overhead memory bindings to native engines  │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│      Compiler & Execution Layer (Android OS)          │
│  Alpine PRoot  ·  Dex ClassLoader  ·  Subprocesses     │
└────────────────────────────────────────────────────────┘
```

---

## 🛠️ Technology Stack & Workarounds

To construct an on-device environment while conforming to modern Android OS security boundaries, the project implements the following mechanisms:

### 1. Overcoming the Android 10+ $W^X$ Security Rule
Android prohibits executing binary payloads inside writable storage structures (such as `/sdcard` or the app cache). 
*   **Workaround**: Native toolchain binary files (such as `python` or `git`) are shipped inside the Flutter package asset bundle. On application load, they are staged inside the app's internal files partition (`/data/data/com.example.android_ide/files/`) and marked executable via `chmod` where system policy still permits execution.

### 2. Android SDK & Namespace Alignment
*   **Gradle Lifecycle Crash Patch**: Added validation wrappers in `build.gradle.kts` checking `project.state.executed` to safely run namespace injections without violating evaluation limits.
*   **Plugin SDK Target Injection**: Added subproject overrides in the Gradle wrapper to force all third-party libraries (like `:file_picker`) to compile against Android SDK `36` to match dependencies.

---

## 📂 Scalable Feature-First Project Structure

The project implements a **Feature-First Clean Architecture** folder structure inside `lib/`:

```
lib/
├── app/
│   ├── app.dart                        # Root MaterialApp
│   ├── routes.dart                     # Router endpoints (GoRouter)
│   └── theme.dart                      # Material 3 Color Schemes
├── core/                               # Cross-cutting utilities & structures
│   ├── constants/                      # Paths, keys
│   └── widgets/                        # Shared base components
└── features/                           # Domain features
    ├── project_explorer/               # Explorer lists, FileNode mapping
    ├── code_editor/                    # Workspace canvases, EditorTab cubit
    └── terminal/                       # Shell emulator panels
```

---

## 🏁 Getting Started

### Prerequisites
*   **Flutter SDK**: `3.44.4` or higher
*   **Dart SDK**: `3.12.2` or higher
*   **Android SDK**: Platform API level `36`

### Setup & Run
1.  Clone the repository:
    ```bash
    git clone https://github.com/Syed-afridi-7/android_ide_dart.git
    cd android_ide_dart
    ```
2.  Clear the build directory caches:
    ```bash
    flutter clean
    ```
3.  Install package dependencies:
    ```bash
    flutter pub get
    ```
4.  Run the application on your connected Android target:
    ```bash
    flutter run -d <YOUR_DEVICE_ID>
    ```

---

## 📄 Reference Document
For a detailed guide on the system design, performance optimizations (such as Isolate-based syntax highlighting), and the execution lifecycle, see [android_ide_blueprint.md](android_ide_blueprint.md).
