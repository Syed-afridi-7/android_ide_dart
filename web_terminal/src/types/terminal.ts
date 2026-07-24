export interface VFSNode {
  name: String;
  path: String;
  isDirectory: boolean;
  content?: string;
  updatedAt: number;
  size: number;
}

export interface VFSEntry {
  name: string;
  isDirectory: boolean;
  size: number;
  updatedAt: number;
}

export interface CommandContext {
  cwd: string;
  setCwd: (path: string) => void;
  vfs: VirtualFileSystem;
  print: (text: string) => void;
  printError: (text: string) => void;
  clear: () => void;
  enterNano: (filePath: string, initialContent: string) => void;
}

export interface CommandResult {
  output?: string;
  error?: string;
  newCwd?: string;
  exitCode: number;
}

export interface GitStatusItem {
  filepath: string;
  status: 'modified' | 'added' | 'deleted' | 'unmodified' | 'untracked';
}

export interface TerminalTheme {
  background: string;
  foreground: string;
  cursor: string;
  selection: string;
  black: string;
  red: string;
  green: string;
  yellow: string;
  blue: string;
  magenta: string;
  cyan: string;
  white: string;
  brightBlack: string;
  brightRed: string;
  brightGreen: string;
  brightYellow: string;
  brightBlue: string;
  brightMagenta: string;
  brightCyan: string;
  brightWhite: string;
}

export interface VirtualFileSystem {
  readFile: (path: string) => Promise<string>;
  writeFile: (path: string, content: string) => Promise<void>;
  appendFile: (path: string, content: string) => Promise<void>;
  mkdir: (path: string) => Promise<void>;
  rmdir: (path: string, recursive?: boolean) => Promise<void>;
  unlink: (path: string) => Promise<void>;
  readdir: (path: string) => Promise<VFSEntry[]>;
  stat: (path: string) => Promise<VFSNode | null>;
  exists: (path: string) => Promise<boolean>;
  resolvePath: (cwd: string, targetPath: string) => string;
}
