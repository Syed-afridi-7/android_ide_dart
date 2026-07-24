import React, { useEffect, useRef, useState, useCallback } from 'react';
import { Terminal } from 'xterm';
import { FitAddon } from 'xterm-addon-fit';
import 'xterm/css/xterm.css';

import { useFileSystem } from '../hooks/useFileSystem';
import { executeCommandString, buildPromptString, handleTabAutoComplete } from '../services/commandRouter';
import { NanoModal } from './NanoModal';

const DARK_THEME = {
  background: '#1e1e1e',
  foreground: '#d4d4d4',
  cursor: '#00ff66',
  selection: 'rgba(255, 255, 255, 0.3)',
  black: '#000000',
  red: '#cd3131',
  green: '#0dbc79',
  yellow: '#e5e510',
  blue: '#2472c8',
  magenta: '#bc3fbc',
  cyan: '#11a8cd',
  white: '#e5e5e5',
  brightBlack: '#666666',
  brightRed: '#f14c4c',
  brightGreen: '#23d18b',
  brightYellow: '#f5f543',
  brightBlue: '#3b8eea',
  brightMagenta: '#d670d6',
  brightCyan: '#29b8db',
  brightWhite: '#e5e5e5',
};

export const TerminalUI: React.FC = () => {
  const terminalRef = useRef<HTMLDivElement>(null);
  const xtermRef = useRef<Terminal | null>(null);
  const fitAddonRef = useRef<FitAddon | null>(null);

  const { cwd, setCwd, vfs, isReady } = useFileSystem();

  const [inputBuffer, setInputBuffer] = useState<string>('');
  const [history, setHistory] = useState<string[]>([]);
  const [historyIndex, setHistoryIndex] = useState<number>(-1);

  const [nanoState, setNanoState] = useState<{
    isOpen: boolean;
    filePath: string;
    content: string;
  }>({
    isOpen: false,
    filePath: '',
    content: '',
  });

  const writePrompt = useCallback(
    (term: Terminal, currentCwd: string) => {
      const prompt = buildPromptString(currentCwd);
      term.write('\r\n' + prompt);
    },
    []
  );

  useEffect(() => {
    if (!isReady || !terminalRef.current || xtermRef.current) return;

    // Initialize xterm instance
    const term = new Terminal({
      theme: DARK_THEME,
      fontFamily: 'Menlo, Monaco, "Courier New", monospace',
      fontSize: 14,
      cursorBlink: true,
      cursorStyle: 'block',
      rows: 28,
      cols: 90,
    });

    const fitAddon = new FitAddon();
    term.loadAddon(fitAddon);
    term.open(terminalRef.current);
    fitAddon.fit();

    xtermRef.current = term;
    fitAddonRef.current = fitAddon;

    // Banner message
    term.writeln('\x1b[1;32mWeb Terminal OS [Linux Sandbox v1.0.0]\x1b[0m');
    term.writeln('Type \x1b[1;33mhelp\x1b[0m to list available POSIX & Git commands.');
    term.write(buildPromptString(cwd));

    // Handle Window Resize
    const handleResize = () => {
      fitAddon.fit();
    };
    window.addEventListener('resize', handleResize);

    return () => {
      window.removeEventListener('resize', handleResize);
      term.dispose();
      xtermRef.current = null;
    };
  }, [isReady]);

  // Update prompt when CWD changes
  useEffect(() => {
    if (xtermRef.current && isReady) {
      // Prompt updated dynamically in command callback
    }
  }, [cwd, isReady]);

  useEffect(() => {
    const term = xtermRef.current;
    if (!term) return;

    let currentInput = inputBuffer;
    let historyIdx = historyIndex;

    const disposable = term.onKey(async ({ key, domEvent }) => {
      const ev = domEvent;

      // Ctrl + L: Clear screen
      if (ev.ctrlKey && (ev.key === 'l' || ev.key === 'L')) {
        ev.preventDefault();
        term.clear();
        term.write(buildPromptString(cwd) + currentInput);
        return;
      }

      // Enter key: Execute Command
      if (ev.key === 'Enter') {
        term.write('\r\n');
        const cmdToRun = currentInput.trim();

        if (cmdToRun) {
          setHistory((prev) => [...prev, cmdToRun]);
          setHistoryIndex(-1);

          const context = {
            cwd,
            setCwd: (newCwd: string) => setCwd(newCwd),
            vfs,
            print: (text: string) => term.writeln(text),
            printError: (text: string) => term.writeln(`\x1b[31m${text}\x1b[0m`),
            clear: () => term.clear(),
            enterNano: (filePath: string, initialContent: string) => {
              setNanoState({
                isOpen: true,
                filePath,
                content: initialContent,
              });
            },
          };

          const result = await executeCommandString(cmdToRun, context);

          if (result.output) {
            term.writeln(result.output.replace(/\n/g, '\r\n'));
          }
          if (result.error) {
            term.writeln(`\x1b[31m${result.error}\x1b[0m`);
          }
        }

        currentInput = '';
        setInputBuffer('');
        term.write(buildPromptString(cwd));
        return;
      }

      // Backspace Key
      if (ev.key === 'Backspace') {
        if (currentInput.length > 0) {
          currentInput = currentInput.substring(0, currentInput.length - 1);
          setInputBuffer(currentInput);
          term.write('\b \b');
        }
        return;
      }

      // Up Arrow: History Previous
      if (ev.key === 'ArrowUp') {
        ev.preventDefault();
        if (history.length > 0) {
          const nextIdx = historyIdx === -1 ? history.length - 1 : Math.max(0, historyIdx - 1);
          historyIdx = nextIdx;
          setHistoryIndex(nextIdx);

          // Clear current input line
          for (let i = 0; i < currentInput.length; i++) {
            term.write('\b \b');
          }
          currentInput = history[nextIdx] || '';
          setInputBuffer(currentInput);
          term.write(currentInput);
        }
        return;
      }

      // Down Arrow: History Next
      if (ev.key === 'ArrowDown') {
        ev.preventDefault();
        if (historyIdx !== -1) {
          const nextIdx = historyIdx + 1;
          for (let i = 0; i < currentInput.length; i++) {
            term.write('\b \b');
          }

          if (nextIdx >= history.length) {
            historyIdx = -1;
            setHistoryIndex(-1);
            currentInput = '';
          } else {
            historyIdx = nextIdx;
            setHistoryIndex(nextIdx);
            currentInput = history[nextIdx] || '';
          }
          setInputBuffer(currentInput);
          term.write(currentInput);
        }
        return;
      }

      // Tab Key: Auto-completion
      if (ev.key === 'Tab') {
        ev.preventDefault();
        const context = { cwd, setCwd, vfs, print: () => {}, printError: () => {}, clear: () => {}, enterNano: () => {} };
        const { completion, matches } = await handleTabAutoComplete(currentInput, context);

        if (matches.length > 1) {
          term.writeln('\r\n' + matches.join('  '));
          term.write(buildPromptString(cwd) + currentInput);
        } else if (completion !== currentInput) {
          const added = completion.substring(currentInput.length);
          currentInput = completion;
          setInputBuffer(currentInput);
          term.write(added);
        }
        return;
      }

      // Normal Printable Character Input
      if (!ev.ctrlKey && !ev.altKey && key.length === 1) {
        currentInput += key;
        setInputBuffer(currentInput);
        term.write(key);
      }
    });

    return () => {
      disposable.dispose();
    };
  }, [cwd, history, historyIndex, inputBuffer, isReady, setCwd, vfs]);

  return (
    <div className="relative w-full h-full flex flex-col bg-[#1e1e1e] rounded-lg shadow-2xl overflow-hidden border border-gray-800 font-mono">
      {/* Terminal Window Header Bar */}
      <div className="flex items-center justify-between px-4 py-2 bg-[#252526] border-b border-gray-800 select-none">
        <div className="flex items-center space-x-2">
          <div className="w-3 h-3 rounded-full bg-red-500 hover:bg-red-600 cursor-pointer" />
          <div className="w-3 h-3 rounded-full bg-yellow-500 hover:bg-yellow-600 cursor-pointer" />
          <div className="w-3 h-3 rounded-full bg-green-500 hover:bg-green-600 cursor-pointer" />
          <span className="ml-2 text-xs font-bold text-gray-400 tracking-wider">
            bash — user@developer-box: {cwd}
          </span>
        </div>
        <div className="flex items-center space-x-3 text-xs text-gray-400">
          <span className="px-2 py-0.5 rounded bg-gray-800 text-green-400 font-mono">POSIX VFS</span>
          <span className="px-2 py-0.5 rounded bg-gray-800 text-blue-400 font-mono">IndexedDB</span>
        </div>
      </div>

      {/* Terminal xterm Canvas Mount Element */}
      <div className="flex-1 p-2 overflow-hidden" ref={terminalRef} />

      {/* Nano Editor Overlay Modal */}
      {nanoState.isOpen && (
        <NanoModal
          filePath={nanoState.filePath}
          initialContent={nanoState.content}
          vfs={vfs}
          onClose={() => {
            setNanoState({ isOpen: false, filePath: '', content: '' });
            if (xtermRef.current) {
              xtermRef.current.write('\r\n' + buildPromptString(cwd));
            }
          }}
        />
      )}
    </div>
  );
};
