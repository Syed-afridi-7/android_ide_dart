import { CommandContext, CommandResult } from '../types/terminal';
import { handleFsCommand } from '../modules/fsModule';
import { handleGitCommand } from '../modules/gitModule';
import { handleExecCommand } from '../modules/execModule';

export function buildPromptString(cwd: string): string {
  let displayPath = cwd;
  if (cwd.startsWith('/home/user')) {
    displayPath = '~' + cwd.substring('/home/user'.length);
  }
  return `\x1b[1;32muser@developer-box\x1b[0m:\x1b[1;34m${displayPath}\x1b[0m\$ `;
}

export async function executeCommandString(
  input: string,
  context: CommandContext
): Promise<CommandResult> {
  const trimmed = input.trim();
  if (!trimmed) {
    return { exitCode: 0 };
  }

  // Parse arguments handling quotes
  const tokens: string[] = [];
  let currentToken = '';
  let inQuotes = false;
  let quoteChar = '';

  for (let i = 0; i < trimmed.length; i++) {
    const char = trimmed[i];
    if ((char === '"' || char === "'") && !inQuotes) {
      inQuotes = true;
      quoteChar = char;
    } else if (char === quoteChar && inQuotes) {
      inQuotes = false;
      quoteChar = '';
    } else if (char === ' ' && !inQuotes) {
      if (currentToken) {
        tokens.push(currentToken);
        currentToken = '';
      }
    } else {
      currentToken += char;
    }
  }
  if (currentToken) {
    tokens.push(currentToken);
  }

  const mainCmd = tokens[0]?.toLowerCase();
  const args = tokens.slice(1);

  // System Core Commands
  switch (mainCmd) {
    case 'clear': {
      context.clear();
      return { exitCode: 0 };
    }

    case 'help': {
      const helpText = `Web Terminal OS v1.0 [Linux Shell Emulator]

File System Operations:
  pwd                      Print current working directory
  cd <dir>                 Change directory
  ls [-la] [path]          List directory contents
  mkdir <dir>              Create new directory
  rmdir [-r] <dir>         Remove directory
  touch <file>             Create empty file
  rm [-rf] <path>          Remove file or directory
  cat <file>               Print file content
  echo "text" > file       Write text into file

Git Version Control:
  git init                 Initialize Git repository
  git status               Show repository status
  git add <file|.>         Stage changes for commit
  git commit -m "msg"      Record commit
  git clone <url>          Clone repository via CORS proxy

Code Execution & Editing:
  nano <file>              In-terminal multi-line text editor
  node <script.js>         Execute JavaScript code/script
  python <script.py>       Execute Python script

Utility Commands:
  clear                    Clear terminal screen
  help                     Show this help overview
  whoami                   Print current user
  date                     Print current timestamp
`;
      return { output: helpText, exitCode: 0 };
    }

    case 'whoami':
      return { output: 'user', exitCode: 0 };

    case 'date':
      return { output: new Date().toString(), exitCode: 0 };

    case 'nano': {
      const targetFile = args[0];
      if (!targetFile) {
        return { error: 'nano: missing filename argument', exitCode: 1 };
      }
      try {
        const resolved = context.vfs.resolvePath(context.cwd, targetFile);
        let existingContent = '';
        if (await context.vfs.exists(resolved)) {
          const node = await context.vfs.stat(resolved);
          if (node?.isDirectory) {
            return { error: `nano: ${targetFile} is a directory`, exitCode: 1 };
          }
          existingContent = await context.vfs.readFile(resolved);
        }
        context.enterNano(resolved, existingContent);
        return { exitCode: 0 };
      } catch (err: any) {
        return { error: `nano: ${err.message}`, exitCode: 1 };
      }
    }
  }

  // Route to File System Module
  if (['pwd', 'cd', 'ls', 'mkdir', 'rmdir', 'touch', 'rm', 'cat', 'echo'].includes(mainCmd)) {
    return handleFsCommand(mainCmd, args, context);
  }

  // Route to Git Module
  if (mainCmd === 'git') {
    return handleGitCommand(args, context);
  }

  // Route to Execution Engine Module
  if (['node', 'js', 'python', 'python3'].includes(mainCmd)) {
    return handleExecCommand(mainCmd, args, context);
  }

  return {
    error: `bash: ${mainCmd}: command not found. Type 'help' for available commands.`,
    exitCode: 127,
  };
}

export async function handleTabAutoComplete(
  currentLine: string,
  context: CommandContext
): Promise<{ completion: string; matches: string[] }> {
  const trimmed = currentLine.trimLeft();
  const parts = trimmed.split(' ');
  const lastPart = parts[parts.length - 1] || '';

  const knownCommands = [
    'pwd',
    'cd',
    'ls',
    'mkdir',
    'rmdir',
    'touch',
    'rm',
    'cat',
    'echo',
    'git',
    'nano',
    'node',
    'python',
    'clear',
    'help',
    'whoami',
    'date',
  ];

  if (parts.length === 1) {
    const matches = knownCommands.filter((cmd) => cmd.startsWith(lastPart));
    if (matches.length === 1) {
      return { completion: matches[0] + ' ', matches };
    }
    return { completion: lastPart, matches };
  }

  // File/Folder Auto-completion
  try {
    const entries = await context.vfs.readdir(context.cwd);
    const names = entries.map((e) => e.name + (e.isDirectory ? '/' : ''));
    const matches = names.filter((n) => n.startsWith(lastPart));

    if (matches.length === 1) {
      const completionSuffix = matches[0].substring(lastPart.length);
      return { completion: lastPart + completionSuffix, matches };
    }
    return { completion: lastPart, matches };
  } catch (_) {
    return { completion: lastPart, matches: [] };
  }
}
