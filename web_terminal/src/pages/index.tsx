import React from 'react';
import { TerminalUI } from '../components/TerminalUI';

export default function WebTerminalPage() {
  return (
    <div className="min-h-screen bg-gray-950 flex flex-col items-center justify-center p-4">
      <div className="w-full max-w-5xl h-[650px] shadow-2xl">
        <TerminalUI />
      </div>
    </div>
  );
}
