import { CommandContext, CommandResult } from '../types/terminal';

export async function handleFsCommand(
  command: string,
  args: string[],
  context: CommandContext
): Promise<CommandResult> {
  const { cwd, setCwd, vfs } = context;

  switch (command) {
    case 'pwd': {
      return { output: cwd, exitCode: 0 };
    }

    case 'cd': {
      const target = args[0] || '/home/user';
      try {
        const resolved = vfs.resolvePath(cwd, target);
        const node = await vfs.stat(resolved);
        if (!node) {
          return { error: `cd: no such file or directory: ${target}`, exitCode: 1 };
        }
        if (!node.isDirectory) {
          return { error: `cd: not a directory: ${target}`, exitCode: 1 };
        }
        setCwd(resolved);
        return { exitCode: 0, newCwd: resolved };
      } catch (err: any) {
        return { error: err.message, exitCode: 1 };
      }
    }

    case 'ls': {
      const showAll = args.includes('-a') || args.includes('-la') || args.includes('-al');
      const showLong = args.includes('-l') || args.includes('-la') || args.includes('-al');
      const targetArg = args.find((a) => !a.startsWith('-')) || '.';

      try {
        const resolved = vfs.resolvePath(cwd, targetArg);
        const entries = await vfs.readdir(resolved);
        const filtered = showAll ? entries : entries.filter((e) => !e.name.startsWith('.'));

        if (filtered.length === 0) {
          return { output: '', exitCode: 0 };
        }

        if (showLong) {
          const lines = filtered.map((e) => {
            const typeChar = e.isDirectory ? 'd' : '-';
            const perm = typeChar + 'rw-r--r--';
            const size = e.size.toString().padStart(8, ' ');
            const date = new Date(e.updatedAt).toISOString().substring(0, 16).replace('T', ' ');
            return `${perm} 1 user group ${size} ${date} ${e.name}${e.isDirectory ? '/' : ''}`;
          });
          return { output: lines.join('\r\n'), exitCode: 0 };
        }

        const formatted = filtered
          .map((e) => (e.isDirectory ? `\x1b[1;34m${e.name}/\x1b[0m` : e.name))
          .join('  ');

        return { output: formatted, exitCode: 0 };
      } catch (err: any) {
        return { error: err.message, exitCode: 1 };
      }
    }

    case 'mkdir': {
      const target = args.find((a) => !a.startsWith('-'));
      if (!target) {
        return { error: 'mkdir: missing operand', exitCode: 1 };
      }
      try {
        const resolved = vfs.resolvePath(cwd, target);
        await vfs.mkdir(resolved);
        return { exitCode: 0 };
      } catch (err: any) {
        return { error: err.message, exitCode: 1 };
      }
    }

    case 'rmdir': {
      const recursive = args.includes('-r') || args.includes('-rf') || args.includes('-p');
      const target = args.find((a) => !a.startsWith('-'));
      if (!target) {
        return { error: 'rmdir: missing operand', exitCode: 1 };
      }
      try {
        const resolved = vfs.resolvePath(cwd, target);
        await vfs.rmdir(resolved, recursive);
        return { exitCode: 0 };
      } catch (err: any) {
        return { error: err.message, exitCode: 1 };
      }
    }

    case 'touch': {
      if (args.length === 0) {
        return { error: 'touch: missing file operand', exitCode: 1 };
      }
      try {
        for (const arg of args) {
          if (arg.startsWith('-')) continue;
          const resolved = vfs.resolvePath(cwd, arg);
          if (!(await vfs.exists(resolved))) {
            await vfs.writeFile(resolved, '');
          }
        }
        return { exitCode: 0 };
      } catch (err: any) {
        return { error: err.message, exitCode: 1 };
      }
    }

    case 'rm': {
      const recursive = args.includes('-r') || args.includes('-rf') || args.includes('-R');
      const target = args.find((a) => !a.startsWith('-'));
      if (!target) {
        return { error: 'rm: missing operand', exitCode: 1 };
      }
      try {
        const resolved = vfs.resolvePath(cwd, target);
        const node = await vfs.stat(resolved);
        if (!node) {
          return { error: `rm: cannot remove '${target}': No such file or directory`, exitCode: 1 };
        }
        if (node.isDirectory) {
          if (!recursive) {
            return { error: `rm: cannot remove '${target}': Is a directory`, exitCode: 1 };
          }
          await vfs.rmdir(resolved, true);
        } else {
          await vfs.unlink(resolved);
        }
        return { exitCode: 0 };
      } catch (err: any) {
        return { error: err.message, exitCode: 1 };
      }
    }

    case 'cat': {
      if (args.length === 0) {
        return { error: 'cat: missing operand', exitCode: 1 };
      }
      try {
        const results: string[] = [];
        for (const arg of args) {
          const resolved = vfs.resolvePath(cwd, arg);
          const content = await vfs.readFile(resolved);
          results.push(content);
        }
        return { output: results.join('\n'), exitCode: 0 };
      } catch (err: any) {
        return { error: err.message, exitCode: 1 };
      }
    }

    case 'echo': {
      // Handles echo "text" > file.txt or echo "text" >> file.txt or normal echo
      const fullArgsStr = args.join(' ');
      const redirectAppend = fullArgsStr.indexOf('>>');
      const redirectWrite = fullArgsStr.indexOf('>');

      if (redirectAppend !== -1) {
        const textPart = fullArgsStr.substring(0, redirectAppend).trim().replace(/^["']|["']$/g, '');
        const filePart = fullArgsStr.substring(redirectAppend + 2).trim();
        if (!filePart) {
          return { error: 'bash: syntax error near unexpected token `newline`', exitCode: 1 };
        }
        try {
          const resolved = vfs.resolvePath(cwd, filePart);
          await vfs.appendFile(resolved, textPart + '\n');
          return { exitCode: 0 };
        } catch (err: any) {
          return { error: err.message, exitCode: 1 };
        }
      } else if (redirectWrite !== -1) {
        const textPart = fullArgsStr.substring(0, redirectWrite).trim().replace(/^["']|["']$/g, '');
        const filePart = fullArgsStr.substring(redirectWrite + 1).trim();
        if (!filePart) {
          return { error: 'bash: syntax error near unexpected token `newline`', exitCode: 1 };
        }
        try {
          const resolved = vfs.resolvePath(cwd, filePart);
          await vfs.writeFile(resolved, textPart + '\n');
          return { exitCode: 0 };
        } catch (err: any) {
          return { error: err.message, exitCode: 1 };
        }
      }

      const textOutput = args.join(' ').replace(/^["']|["']$/g, '');
      return { output: textOutput, exitCode: 0 };
    }

    default:
      return { error: `fs: command not found: ${command}`, exitCode: 127 };
  }
}
