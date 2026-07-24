import { useState, useEffect, useCallback } from 'react';
import { vfsService } from '../services/vfsService';
import { VirtualFileSystem } from '../types/terminal';

export function useFileSystem() {
  const [cwd, setCwd] = useState<string>('/home/user');
  const [isReady, setIsReady] = useState<boolean>(false);

  useEffect(() => {
    async function initFileSystem() {
      try {
        // Ensure default directory hierarchy exists
        if (!(await vfsService.exists('/home'))) {
          await vfsService.mkdir('/home');
        }
        if (!(await vfsService.exists('/home/user'))) {
          await vfsService.mkdir('/home/user');
        }
        if (!(await vfsService.exists('/home/user/projects'))) {
          await vfsService.mkdir('/home/user/projects');
        }

        // Create initial welcome sample files if empty
        if (!(await vfsService.exists('/home/user/welcome.txt'))) {
          await vfsService.writeFile(
            '/home/user/welcome.txt',
            'Welcome to Web Terminal OS v1.0!\nType `help` to list all available commands.\nTry git, python, js execution, and nano editor!\n'
          );
        }
        if (!(await vfsService.exists('/home/user/script.js'))) {
          await vfsService.writeFile(
            '/home/user/script.js',
            '// JavaScript Execution Sandbox\nconst msg = "Hello from Web Terminal!";\nconsole.log(msg);\nreturn 42;\n'
          );
        }

        setIsReady(true);
      } catch (err) {
        console.error('Failed to initialize VFS:', err);
        setIsReady(true);
      }
    }

    initFileSystem();
  }, []);

  const changeDirectory = useCallback(async (targetPath: string): Promise<string> => {
    const resolved = vfsService.resolvePath(cwd, targetPath);
    const node = await vfsService.stat(resolved);

    if (!node) {
      throw new Error(`cd: no such file or directory: ${targetPath}`);
    }
    if (!node.isDirectory) {
      throw new Error(`cd: not a directory: ${targetPath}`);
    }

    setCwd(resolved);
    return resolved;
  }, [cwd]);

  return {
    cwd,
    setCwd,
    changeDirectory,
    isReady,
    vfs: vfsService as VirtualFileSystem,
  };
}
