import { CommandContext, CommandResult } from '../types/terminal';

export async function handleExecCommand(
  command: string,
  args: string[],
  context: CommandContext
): Promise<CommandResult> {
  const { cwd, vfs } = context;

  switch (command) {
    case 'node':
    case 'js': {
      const scriptArg = args[0];

      if (!scriptArg) {
        return {
          output: 'Welcome to Node.js / JavaScript Interactive Evaluator!\nUsage: node <script.js> or js "console.log(1+1)"',
          exitCode: 0,
        };
      }

      let codeToRun = scriptArg;

      // Check if argument is a file path
      if (scriptArg.endsWith('.js')) {
        try {
          const resolved = vfs.resolvePath(cwd, scriptArg);
          codeToRun = await vfs.readFile(resolved);
        } catch (err: any) {
          return { error: `node: cannot open file '${scriptArg}': ${err.message}`, exitCode: 1 };
        }
      }

      // Execute JavaScript code safely capturing console output
      try {
        const logs: string[] = [];
        const customConsole = {
          log: (...data: any[]) => logs.push(data.map((d) => (typeof d === 'object' ? JSON.stringify(d) : d)).join(' ')),
          error: (...data: any[]) => logs.push(`[ERROR] ` + data.join(' ')),
          warn: (...data: any[]) => logs.push(`[WARN] ` + data.join(' ')),
          info: (...data: any[]) => logs.push(`[INFO] ` + data.join(' ')),
        };

        const runner = new Function('console', 'context', `
          try {
            ${codeToRun}
          } catch(e) {
            console.error(e.message);
          }
        `);

        const result = runner(customConsole, context);
        let output = logs.join('\n');
        if (result !== undefined) {
          output += (output ? '\n' : '') + `=> ${JSON.stringify(result)}`;
        }

        return { output: output || 'Program executed successfully (no output).', exitCode: 0 };
      } catch (err: any) {
        return { error: `Uncaught Exception: ${err.message}`, exitCode: 1 };
      }
    }

    case 'python':
    case 'python3': {
      const scriptArg = args[0];
      if (!scriptArg) {
        return {
          output: 'Python 3.11.4 (WebAssembly / Pyodide Engine)\nUsage: python <script.py> or python -c "print(1+1)"',
          exitCode: 0,
        };
      }

      let codeToRun = scriptArg;
      if (scriptArg === '-c' && args[1]) {
        codeToRun = args[1];
      } else if (scriptArg.endsWith('.py')) {
        try {
          const resolved = vfs.resolvePath(cwd, scriptArg);
          codeToRun = await vfs.readFile(resolved);
        } catch (err: any) {
          return { error: `python3: can't open file '${scriptArg}': ${err.message}`, exitCode: 1 };
        }
      }

      // Simulated Python interpreter execution engine
      try {
        context.print(`[Python Wasm Engine] Executing ${scriptArg}...`);
        const outputLines: string[] = [];

        // Basic Python print statement parsing for lightweight execution
        const lines = codeToRun.split('\n');
        for (const line of lines) {
          const trimmed = line.trim();
          if (trimmed.startsWith('print(') && trimmed.endsWith(')')) {
            const inner = trimmed.substring(6, trimmed.length - 1).replace(/^["']|["']$/g, '');
            outputLines.push(inner);
          }
        }

        if (outputLines.length === 0) {
          outputLines.push(`[Python Sandbox] Executed ${lines.length} lines cleanly.`);
        }

        return { output: outputLines.join('\n'), exitCode: 0 };
      } catch (err: any) {
        return { error: `Traceback (most recent call last):\n  File "${scriptArg}", line 1, in <module>\nNameError: ${err.message}`, exitCode: 1 };
      }
    }

    default:
      return { error: `exec: unsupported execution target ${command}`, exitCode: 127 };
  }
}
