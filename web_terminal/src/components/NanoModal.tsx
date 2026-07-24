import React, { useState, useEffect, useRef } from 'react';
import { VirtualFileSystem } from '../types/terminal';

interface NanoModalProps {
  filePath: string;
  initialContent: string;
  vfs: VirtualFileSystem;
  onClose: (saved: boolean) => void;
}

export const NanoModal: React.FC<NanoModalProps> = ({
  filePath,
  initialContent,
  vfs,
  onClose,
}) => {
  const [content, setContent] = useState<string>(initialContent);
  const [statusMessage, setStatusMessage] = useState<string>('');
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    if (textareaRef.current) {
      textareaRef.current.focus();
    }
  }, []);

  const handleSave = async () => {
    try {
      await vfs.writeFile(filePath, content);
      setStatusMessage(`[ Wrote ${content.split('\n').length} lines to ${filePath} ]`);
      setTimeout(() => setStatusMessage(''), 3000);
      return true;
    } catch (err: any) {
      setStatusMessage(`[ Error saving file: ${err.message} ]`);
      return false;
    }
  };

  const handleKeyDown = async (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    // Ctrl + O: WriteOut (Save)
    if (e.ctrlKey && (e.key === 'o' || e.key === 'O')) {
      e.preventDefault();
      await handleSave();
    }

    // Ctrl + X: Exit
    if (e.ctrlKey && (e.key === 'x' || e.key === 'X')) {
      e.preventDefault();
      onClose(true);
    }
  };

  const lineCount = content.split('\n').length;

  return (
    <div className="fixed inset-0 z-50 flex flex-col bg-black text-white font-mono p-4 select-none">
      {/* Nano Header Bar */}
      <div className="bg-gray-800 text-center text-sm py-1 font-bold tracking-wider flex justify-between px-4">
        <span>GNU nano 7.2</span>
        <span className="text-yellow-400">{filePath}</span>
        <span>{content !== initialContent ? 'Modified' : ''}</span>
      </div>

      {/* Editor Main Canvas Textarea */}
      <textarea
        ref={textareaRef}
        value={content}
        onChange={(e) => setContent(e.target.value)}
        onKeyDown={handleKeyDown}
        className="flex-1 bg-black text-green-400 p-2 outline-none resize-none font-mono text-sm leading-relaxed"
        spellCheck={false}
      />

      {/* Status Bar Message */}
      <div className="h-6 text-center text-xs text-yellow-300 font-semibold">
        {statusMessage}
      </div>

      {/* Nano Keybindings Footer Shortcuts */}
      <div className="bg-gray-900 grid grid-cols-4 gap-2 text-xs p-2 text-gray-300 border-t border-gray-800">
        <div>
          <span className="text-black bg-white px-1 font-bold">^G</span> Get Help
        </div>
        <div onClick={handleSave} className="cursor-pointer hover:text-white">
          <span className="text-black bg-white px-1 font-bold">^O</span> WriteOut
        </div>
        <div>
          <span className="text-black bg-white px-1 font-bold">^W</span> Where Is
        </div>
        <div>
          <span className="text-black bg-white px-1 font-bold">^K</span> Cut Text
        </div>
        <div>
          <span className="text-black bg-white px-1 font-bold">^J</span> Justify
        </div>
        <div>
          <span className="text-black bg-white px-1 font-bold">^C</span> Cur Pos
        </div>
        <div onClick={() => onClose(true)} className="cursor-pointer hover:text-white">
          <span className="text-black bg-white px-1 font-bold">^X</span> Exit
        </div>
        <div>
          <span className="text-black bg-white px-1 font-bold">^R</span> Read File
        </div>
      </div>
    </div>
  );
};
