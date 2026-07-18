# Mobile Integrated Development Environment (Android IDE) Development Blueprint

This blueprint outlines the design, architecture, tech stack, and step-by-step roadmap for building **Android IDE**—a professional, scalable, and feature-rich mobile development environment built using Flutter (Dart).

---

## 1. System Architecture Design

Building an IDE on Android requires bridging a cross-platform Flutter UI with local OS-level compilers, terminal shells, and low-level filesystem systems. 

```mermaid
graph TD
    subgraph Flutter UI Layer (Dart)
        A[Multi-tab Editor UI] --> B[Editor State Cubit]
        C[File Explorer UI] --> D[File Node Controller]
        E[Terminal Console UI] --> F[Terminal Stream Provider]
        G[Live Web Preview UI] --> H[Local HTTP Host Controller]
    end

    subgraph Native Interop Layer (C / Dart FFI / Platform Channels)
        I[Dart FFI / libgit2dart] --> J[libgit2 Native Binaries]
        K[Dart FFI / flutter_pty] --> L[Pseudo-Terminal Engine]
        M[MethodChannels] --> N[Android Scoped Storage Helper]
    end

    subgraph Compiler & Shell Execution Layer (Android OS)
        L --> O[Local Process: sh / bash / termux-chroot]
        O --> P[Alpine Linux / Debian bootstrap via PRoot]
        P --> Q[Compilers: GCC/Clang, Python interpreter, OpenJDK]
        R[Dynamic ClassLoader] --> S[Dex bytecode Runner]
    end

    subgraph Project Storage Layer
        N --> T[External Shared Storage / Projects]
        B --> U[Isar Cache / State Persistence]
    end

    B -.-> I
    D -.-> N
    F -.-> K
    H -.-> T
    Q -.-> T
```

### Core Architecture Components

1.  **Flutter UI Layer (Dart):**
    *   Runs the main render thread.
    *   Uses **Material 3** for responsiveness, implementing responsive layouts (`NavigationRail` for landscape/tablets, `BottomNavigationBar` for portrait mobile views).
    *   Integrates specialized views: code canvases, file trees, shell outputs, and preview frames.
2.  **Native Interop Layer:**
    *   **Dart FFI:** Used for high-frequency operations that cannot tolerate Platform Channel overhead (e.g., git commands via `libgit2dart` and PTY interaction via `flutter_pty`).
    *   **MethodChannels:** Used for querying system permissions (Scoped Storage), handling system notifications, and querying Android battery/thermal throttling status.
3.  **Compiler & Shell Execution Layer (Android OS Boundary):**
    *   Because Android restricts execution of downloaded binaries inside writable directories (`W^X` policy on Android 10+), the runner extracts native assets to the application's private files directory (`/data/data/com.example.android_ide/files/`) and launches compiled code inside a PRoot jail or direct subprocesses.
4.  **Local HTTP Web Server:**
    *   Spins up a local `HttpServer` inside Dart to serve HTML, CSS, and JS files from the project directory.
    *   Injects a lightweight JavaScript snippet dynamically to facilitate real-time **Hot Reload** over WebSockets whenever a saved file is detected by the Dart `DirectoryWatcher`.

---

## 2. Standardized Flutter Folder Structure

The application adopts a **Feature-First Clean Architecture** directory layout inside `lib/`. This keeps features modular, making it simple to scale language support or add cloud engines later.

```
lib/
├── app/
│   ├── app.dart                        # Main application widget
│   ├── routes.dart                     # App navigation and page routes
│   └── theme.dart                      # Material 3 dark/light design system
├── core/                               # Cross-cutting concerns & global utilities
│   ├── constants/                      # Global keys, paths, and assets
│   ├── errors/                         # Custom failure objects & error handlers
│   ├── network/                        # Shared socket & local servers
│   ├── storage/                        # Persistent key-value database wrapper
│   ├── utils/                          # File extension mappers, platform-check helpers
│   └── widgets/                        # Modular, reusable UI widgets (buttons, input fields)
├── features/                           # Independent domain modules
│   ├── project_explorer/               # Project and file explorer management
│   │   ├── data/                       # Local filesystem datasources, model mappers
│   │   ├── domain/                     # Entities (FileNode, Project) & Use Cases
│   │   └── presentation/               # Explorer Bloc, FileTree, DirectoryPicker UI
│   ├── code_editor/                    # Advanced code editor & multi-tab workspace
│   │   ├── data/                       # Code parser, diagnostics client
│   │   ├── domain/                     # Entity: EditorTab, AutoCompleteSuggestions
│   │   └── presentation/               # Editor Workspace Bloc, CodeCanvas, TabBar UI
│   ├── terminal/                       # In-app interactive shell terminal
│   │   ├── data/                       # PTY wrapper, Process controllers
│   │   └── presentation/               # Terminal Bloc, xterm viewport
│   ├── compiler/                       # Local execution, compilers, runtimes
│   │   ├── data/                       # PRoot config, Dex wrapper, execution script
│   │   ├── domain/                     # Compiler Interface (Java, C, Python)
│   │   └── presentation/               # Execution Console Bloc, Runner console sheet
│   └── git_client/                     # Git integration controls
│       ├── data/                       # libgit2 wrapper, local auth manager
│       ├── domain/                     # Entity: Commit, Diff, BranchInfo
│       └── presentation/               # Version Control Panel, Commit UI, DiffViewer
└── main.dart                           # Entry point
```

---

## 3. Comprehensive Tech Stack & Android Code Execution

Android’s security model presents unique challenges for code compilation and execution. The following runtime execution engine configuration details how compilers and interpreters run on userland.

| Language | Environment Type | Android Compilation / Execution Mechanism |
| :--- | :--- | :--- |
| **Java** | Dynamic Classloading / Dex Runtime | Java source is compiled to Dex bytecode using a local port of the `d8` tool. The resulting `.dex` file is loaded directly into the app's Dalvik/ART process runtime via Java's `DexClassLoader`, bypassing execution bans. |
| **Python** | Local Native Interpreter | A statically compiled ARM64 Python binary is extracted into the app’s internal files path (`/data/data/com.example.android_ide/files/bin/python`). Script files are passed to it via standard terminal execution. |
| **C / C++** | PRoot Sandbox / TinyCC | A pre-compiled minimal Linux environment (Alpine ARM64) is bootstrapped. TinyCC (`tcc`) compiles C source directly to ARM64 binary formats, which are executed inside a sandboxed PRoot namespace. |
| **HTML/CSS/JS**| Local HTTP Server & WebView | A localized static `HttpServer` is run in the background. It hosts the target directory assets on `http://localhost:<random-port>`. The layout is rendered in an in-app WebView. |

### Handling the Android 10+ W^X Constraint

Android prohibits the execution of binaries stored inside shared directories (like `/sdcard` or `/storage/emulated/0`). To compile and run C, C++, or Python:

1.  **Staging Directory:** User-authored code is read from the project folder and copied (or symlinked) to the application sandbox directory: `/data/data/com.example.android_ide/files/sandbox/`.
2.  **Native Assets:** Binary engines (`python`, `tcc`, `d8`, `git`) are shipped inside the Flutter APK as assets, copied to `/data/data/com.example.android_ide/app_bin/`, and marked executable via `chmod 755` immediately after installation.
3.  **PRoot Wrapper:** The PRoot layer translates standard path lookups (e.g. `/usr/bin/gcc`) into local app-sandbox directory assets on-the-fly.

---

## 4. Recommended Flutter Packages

To avoid reinventing core IDE components, the project integrates the following high-quality packages:

```yaml
dependencies:
  # UI & Routing
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  go_router: ^14.2.0                       # High performance routing

  # State Management
  flutter_bloc: ^8.1.6                     # Structured event-driven state
  flutter_riverpod: ^2.5.1                 # DI and stream provider management

  # Code Editor
  re_editor: ^0.3.2                        # Virtualized, high-performance editor canvas
  re_highlight: ^0.1.2                     # High performance parser binding

  # Terminal Simulation
  xterm: ^3.3.0                            # Terminal UI grid emulator
  flutter_pty: ^1.0.2                      # Low-level pseudo-terminal bindings

  # Git & Credentials
  libgit2dart: ^0.4.3                      # Native-speed Git binding via Dart FFI
  flutter_secure_storage: ^9.2.2           # Encrypted keychain storage for Git tokens

  # Database & Filesystem
  isar: ^3.1.0+7                           # Fast database for project configurations
  isar_flutter_libs: ^3.1.0+7
  path_provider: ^2.1.3                    # System directory mapper
  path: ^1.9.0                             # Path operations utility
  file_picker: ^8.0.0                      # System native file selection
  watcher: ^1.1.0                          # Monitors filesystem changes

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  isar_generator: ^3.1.0+7
```

---

## 5. State Management Strategy

The IDE manages two primary state types:
*   **Workspace State:** Current opened files, selected tabs, cursor position, and edit buffers (uses **Bloc/Cubit** for strict state transitions).
*   **Background Compiler & Terminal Process Streams:** Running subprocesses, stdout/stderr streams, and hot-reload triggers (uses **Riverpod Providers/Streams** for reactive propagation).

### Multi-Tab File System Manager Code Example

```dart
// lib/features/code_editor/domain/entities/editor_tab.dart
class EditorTab {
  final String filePath;
  final String fileName;
  final String content;
  final bool isDirty;
  final int cursorOffset;
  final double scrollOffset;

  EditorTab({
    required this.filePath,
    required this.fileName,
    required this.content,
    this.isDirty = false,
    this.cursorOffset = 0,
    this.scrollOffset = 0.0,
  });

  EditorTab copyWith({
    String? content,
    bool? isDirty,
    int? cursorOffset,
    double? scrollOffset,
  }) {
    return EditorTab(
      filePath: this.filePath,
      fileName: this.fileName,
      content: content ?? this.content,
      isDirty: isDirty ?? this.isDirty,
      cursorOffset: cursorOffset ?? this.cursorOffset,
      scrollOffset: scrollOffset ?? this.scrollOffset,
    );
  }
}

// lib/features/code_editor/presentation/state/workspace_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/editor_tab.dart';

class WorkspaceState {
  final List<EditorTab> tabs;
  final int activeIndex;

  WorkspaceState({required this.tabs, required this.activeIndex});

  EditorTab? get activeTab =>
      tabs.isNotEmpty && activeIndex < tabs.length ? tabs[activeIndex] : null;

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

  void closeTab(int index) {
    if (index < 0 || index >= state.tabs.length) return;
    final updatedTabs = List<EditorTab>.from(state.tabs)..removeAt(index);
    int newActive = state.activeIndex;
    if (newActive >= updatedTabs.length) {
      newActive = updatedTabs.length - 1;
    }
    emit(state.copyWith(tabs: updatedTabs, activeIndex: newActive));
  }
}
```

---

## 6. Database & Storage Strategy

The application stores lightweight structural data locally inside **Isar** database schemas. Big code files remain on the OS filesystem, never copied inside the database, ensuring zero runtime memory bloating.

### Local Settings and Sessions Schema

```dart
// lib/core/storage/models/project_config.dart
import 'package:isar/isar.dart';

part 'project_config.g.dart';

@collection
class ProjectConfig {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String rootPath;
  
  late String projectName;
  late String primaryLanguage;
  late DateTime lastOpened;
  
  String? gitRemoteUrl;
  
  // Persisted state of open tabs for session restore
  List<String> openTabPaths = [];
  int activeTabIdx = 0;
}

@collection
class UserSettings {
  Id id = Isar.autoIncrement;
  
  String themeMode = 'dark'; // 'dark' | 'light' | 'system'
  double fontSize = 14.0;
  String fontFamily = 'FiraCode';
  bool lineNumbers = true;
  bool wordWrap = false;
  int tabSpacing = 4;
}
```

### File Storage Locations

*   **App Internal cache (`/data/data/com.example.android_ide/cache`):** Used to write dynamic diagnostics files and cached AST (Abstract Syntax Tree) trees parsed from user files.
*   **App Private documents (`/data/data/com.example.android_ide/files/projects`):** Standard workspace folder location for sandboxed, execute-ready projects.
*   **External Storage (`/storage/emulated/0/AndroidIDE/`):** Shared projects folder allowing users to access files via third-party managers.

---

## 7. Security Considerations

Operating an IDE requires running unknown code on user hardware and managing sensitive developer data.

### Storage Isolation & Android Scoped Storage

*   **Requesting Broad I/O Access:** Android IDE must request access to user projects using the `MANAGE_EXTERNAL_STORAGE` permission on APIs 30+. This requires adding the permission key inside the manifest and requesting it programmatically:
    ```xml
    <!-- android/app/src/main/AndroidManifest.xml -->
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
    ```
*   **System Sandboxing Policy:** All compiler and interpreter subprocesses are run under the app’s execution context, isolating them from other system applications. However, to prevent user programs from accessing the private directories of Android IDE, subprocesses are ran using custom paths where the application’s private `lib/` and database configurations are mapped out of bounds.

### Secure Git Authentication Management

*   Developer tokens (Personal Access Tokens) and private SSH keys are stored in the Android system **Keystore** using `flutter_secure_storage`.
*   Authentication headers are fed to `libgit2dart` sessions in memory using credentials callbacks without ever caching plain-text credentials onto disk storage.

```dart
// lib/features/git_client/data/secure_auth_manager.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureAuthManager {
  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String domain, String token) async {
    await _storage.write(key: 'git_token_$domain', value: token);
  }

  Future<String?> getToken(String domain) async {
    return await _storage.read(key: 'git_token_$domain');
  }

  Future<void> saveSshKey(String keyName, String privateKeyContent) async {
    await _storage.write(key: 'ssh_key_$keyName', value: privateKeyContent);
  }
}
```

---

## 8. Performance Optimization Plan

```
                    ┌────────────────────────┐
                    │  Main Thread UI (Dart) │
                    └───────────┬────────────┘
                                │
               Typing Event     │    Yield AST & Spans
               (No UI Jank)     │    (Rendering Pipeline)
                                ▼
                    ┌────────────────────────┐
                    │    Background Isolate  │
                    │   (Tree-sitter Parser) │
                    └────────────────────────┘
```

1.  **Editor Virtualization:**
    *   Using the `re_editor` widget, only the lines within the viewport vertical bounds are calculated and painted. Lines outside the screen layout boundary are completely skipped, keeping framerates at **60fps / 120fps** even when opening files with 10,000+ lines.
2.  **Isolate-Based Syntax Highlighting:**
    *   Large file syntax parsing generates massive syntax trees which causes frame dropping if calculated on the main thread.
    *   The raw string content is sent to a background worker **Dart Isolate** where Tree-Sitter parsing occurs. The isolate yields mapped spans back to the UI thread.
3.  **File System Event Debouncing:**
    *   Directory watching via the filesystem throws multiple notifications per second on build outputs. Changes are debounced by `200ms` inside data controllers to avoid spamming the UI thread with directory tree updates.

---

## 9. Feature Roadmap & Development Phases

```
┌────────────────────────────────────────────────────────┐
│ PHASE 1: File Engine & Canvas (Weeks 1 - 3)            │
│ Core file management, basic editor panel, settings     │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ PHASE 2: Live HTML Web Preview (Weeks 4 - 6)           │
│ Multi-tab implementation, static local preview server   │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ PHASE 3: Shell & Terminal (Weeks 7 - 9)                │
│ PTY compilation, interactive terminal console UI       │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ PHASE 4: Local Runtimes & Git (Weeks 10 - 12)          │
│ Python native running, Dex ClassLoading, Git commits   │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│ PHASE 5: Optimization & release (Weeks 13 - 16)        │
│ Memory profile sweeps, PRoot compilation integrations   │
└────────────────────────────────────────────────────────┘
```

---

## 10. Implementation Milestones

*   **Milestone 1 (Workspace Pipeline Check):** A user can navigate directories, create a standard workspace, and load file contents inside the virtualized editor with responsive theme shifts.
*   **Milestone 2 (Web Render Engine Validation):** A static multi-page portfolio website project (HTML/CSS/JS) is launched via the backend server, and runs in the preview tab, demonstrating dynamic page reloading upon file edits.
*   **Milestone 3 (Subprocess Execution Verification):** Spawning `/system/bin/sh` or bash from within the Dart runtime via PTY handles full bidirectional inputs and outputs inside the xterm emulator.
*   **Milestone 4 (Compiler Toolchain integration):** Python script parses parameters and exits. C-source translates correctly to compiled executable targets inside Alpine PRoot, printing correct values to stderr/stdout.
*   **Milestone 5 (Version Control Proof):** A user executes remote repository clones, views differences inside the Diff Editor, writes a commit message, and pushes to GitHub securely.

---

## 11. Testing Strategy

An IDE must ensure high reliability; a crash during a save operation could ruin a developer's work.

### 1. Unit Testing Model
Tests focus on compiler state changes, line-wrapping managers, and parser mappings.
```dart
// test/features/code_editor/workspace_cubit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:android_ide/features/code_editor/presentation/state/workspace_cubit.dart';

void main() {
  group('WorkspaceCubit Tests', () {
    late WorkspaceCubit cubit;

    setUp(() {
      cubit = WorkspaceCubit();
    });

    test('Initial state is empty', () {
      expect(cubit.state.tabs, isEmpty);
      expect(cubit.state.activeIndex, -1);
    });

    test('Opening a file adds tab and sets active', () {
      cubit.openFile('/path/test.py', 'test.py', 'print("Hello")');
      expect(cubit.state.tabs.length, 1);
      expect(cubit.state.tabs.first.fileName, 'test.py');
      expect(cubit.state.activeIndex, 0);
    });

    test('Updating content marks tab as dirty', () {
      cubit.openFile('/path/test.py', 'test.py', 'print("Hello")');
      cubit.updateActiveContent('print("Hello World")');
      expect(cubit.state.activeTab!.content, 'print("Hello World")');
      expect(cubit.state.activeTab!.isDirty, isTrue);
    });
  });
}
```

### 2. Integration & UI Verification
E2E tests will run inside an Android emulator using ADB commands to verify that standard filesystem workflows complete smoothly without throwing file handle leaks.

### 3. Performance Metrics Thresholds
*   **Frame Budget:** Keep frame execution time under `8.3ms` (for 120Hz screens) or `16.6ms` (for 60Hz screens) during quick typing runs.
*   **Memory Footprint:** IDE must maintain under `250MB` RAM footprint during standard multi-file operations.
*   **File Load Duration:** Opening a 2MB file must register visually within `<300ms`.

---

## 12. Future Enhancements

*   **Remote SSH Workspaces:** Connect to remote servers using `dartssh2`, forwarding ports to access remote workspaces and compiler pipelines from local devices.
*   **Cloud Sync Modules:** Implement auto-backup adapters targeting Google Drive, Dropbox, or standard WebDAV protocols.
*   **AI Pair Programmer:** Build local LLM capabilities via **Gemini Nano** (using Android AICore) or connect to cloud API models (like Gemini 1.5 Pro) for contextual code suggestions, refactoring, and natural-language error debug recommendations.
