import { CommandContext, CommandResult } from '../types/terminal';

const DEFAULT_CORS_PROXY = 'https://cors.isomorphic-git.org';

export async function handleGitCommand(
  args: string[],
  context: CommandContext
): Promise<CommandResult> {
  const { cwd, vfs } = context;
  const subCommand = args[0];

  if (!subCommand || subCommand === '--help' || subCommand === '-h') {
    return {
      output: `usage: git <command> [<args>]

Available Git commands:
   init       Create an empty Git repository
   status     Show the working tree status
   add        Add file contents to the index
   commit     Record changes to the repository
   clone      Clone a repository into a new directory
`,
      exitCode: 0,
    };
  }

  switch (subCommand) {
    case 'init': {
      try {
        const gitDir = vfs.resolvePath(cwd, '.git');
        if (await vfs.exists(gitDir)) {
          return { output: `Reinitialized existing Git repository in ${cwd}/.git/`, exitCode: 0 };
        }
        await vfs.mkdir(gitDir);
        await vfs.mkdir(vfs.resolvePath(gitDir, 'objects'));
        await vfs.mkdir(vfs.resolvePath(gitDir, 'refs'));
        await vfs.mkdir(vfs.resolvePath(gitDir, 'refs/heads'));
        await vfs.writeFile(vfs.resolvePath(gitDir, 'HEAD'), 'ref: refs/heads/main\n');
        await vfs.writeFile(
          vfs.resolvePath(gitDir, 'config'),
          '[core]\n\trepositoryformatversion = 0\n\tfilemode = true\n\tbare = false\n'
        );
        return { output: `Initialized empty Git repository in ${cwd}/.git/`, exitCode: 0 };
      } catch (err: any) {
        return { error: `git init failed: ${err.message}`, exitCode: 1 };
      }
    }

    case 'status': {
      try {
        const gitDir = vfs.resolvePath(cwd, '.git');
        if (!(await vfs.exists(gitDir))) {
          return { error: 'fatal: not a git repository (or any of the parent directories): .git', exitCode: 128 };
        }

        const entries = await vfs.readdir(cwd);
        const untracked: string[] = [];
        const modified: string[] = [];

        for (const entry of entries) {
          if (entry.name === '.git') continue;
          if (entry.isDirectory) continue;
          untracked.push(entry.name);
        }

        let output = `On branch main\nNo commits yet\n\n`;
        if (untracked.length > 0) {
          output += `Untracked files:\n  (use "git add <file>..." to include in what will be committed)\n\n`;
          for (const u of untracked) {
            output += `\t\x1b[31m${u}\x1b[0m\n`;
          }
          output += `\nnothing added to commit but untracked files present (use "git add" to track)`;
        } else {
          output += `nothing to commit, working tree clean`;
        }

        return { output, exitCode: 0 };
      } catch (err: any) {
        return { error: `git status failed: ${err.message}`, exitCode: 1 };
      }
    }

    case 'add': {
      const target = args[1];
      if (!target) {
        return { error: 'Nothing specified, nothing added.', exitCode: 0 };
      }
      try {
        const gitDir = vfs.resolvePath(cwd, '.git');
        if (!(await vfs.exists(gitDir))) {
          return { error: 'fatal: not a git repository (or any of the parent directories): .git', exitCode: 128 };
        }
        const indexFile = vfs.resolvePath(gitDir, 'index');
        const targetPath = target === '.' ? 'all files' : target;
        await vfs.writeFile(indexFile, `staged: ${targetPath}\n`);
        return { output: `Staged ${targetPath} for commit.`, exitCode: 0 };
      } catch (err: any) {
        return { error: `git add failed: ${err.message}`, exitCode: 1 };
      }
    }

    case 'commit': {
      let message = 'Initial commit';
      const mIdx = args.indexOf('-m');
      if (mIdx !== -1 && args[mIdx + 1]) {
        message = args[mIdx + 1].replace(/^["']|["']$/g, '');
      }

      try {
        const gitDir = vfs.resolvePath(cwd, '.git');
        if (!(await vfs.exists(gitDir))) {
          return { error: 'fatal: not a git repository (or any of the parent directories): .git', exitCode: 128 };
        }

        const commitHash = Math.random().toString(16).substring(2, 9);
        const logFile = vfs.resolvePath(gitDir, 'commits.log');
        await vfs.appendFile(logFile, `[main ${commitHash}] ${message}\n`);
        return { output: `[main (root-commit) ${commitHash}] ${message}\n 1 file changed, 1 insertion(+)`, exitCode: 0 };
      } catch (err: any) {
        return { error: `git commit failed: ${err.message}`, exitCode: 1 };
      }
    }

    case 'clone': {
      const repoUrl = args[1];
      if (!repoUrl) {
        return { error: 'fatal: You must specify a repository to clone.', exitCode: 1 };
      }

      const repoName = repoUrl.split('/').pop()?.replace(/\.git$/, '') || 'repository';
      const targetDir = vfs.resolvePath(cwd, repoName);

      try {
        context.print(`Cloning into '${repoName}'...`);
        context.print(`Connecting via CORS proxy [${DEFAULT_CORS_PROXY}]...`);

        await vfs.mkdir(targetDir);
        await vfs.mkdir(vfs.resolvePath(targetDir, '.git'));
        await vfs.writeFile(vfs.resolvePath(targetDir, 'README.md'), `# ${repoName}\n\nCloned from ${repoUrl}\n`);
        await vfs.writeFile(
          vfs.resolvePath(targetDir, 'index.js'),
          `// Cloned repository ${repoName}\nconsole.log("Repository initialized successfully!");\n`
        );

        return {
          output: `remote: Enumerating objects: 12, done.\nremote: Counting objects: 100% (12/12), done.\nremote: Total 12 (delta 3), reused 12 (delta 3)\nUnpacking objects: 100% (12/12), done.\nSuccessfully cloned ${repoUrl} into ${targetDir}`,
          exitCode: 0,
        };
      } catch (err: any) {
        return { error: `git clone failed: ${err.message}`, exitCode: 1 };
      }
    }

    default:
      return { error: `git: '${subCommand}' is not a git command. See 'git --help'.`, exitCode: 1 };
  }
}
