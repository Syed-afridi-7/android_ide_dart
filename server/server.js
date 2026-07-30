const http = require('http');
const WebSocket = require('ws');
const pty = require('node-pty');
const { Client: SSHClient } = require('ssh2');
const fs = require('fs');
const path = require('path');

const PORT = parseInt(process.env.PORT || '8080', 10);
const HEARTBEAT_INTERVAL = 30000;

const WORKSPACE_DIR = path.join(process.env.HOME || '/root', 'workspace');
if (!fs.existsSync(WORKSPACE_DIR)) {
  fs.mkdirSync(WORKSPACE_DIR, { recursive: true });
}

// Create HTTP server for health checks
const httpServer = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'ok',
      connections: wss.clients.size,
      uptime: process.uptime(),
    }));
  } else {
    res.writeHead(404);
    res.end();
  }
});

const wss = new WebSocket.Server({ server: httpServer });

console.log(`[CloudTerminal] Server starting on port ${PORT}...`);

// Heartbeat to detect dead connections
const heartbeat = setInterval(() => {
  wss.clients.forEach((ws) => {
    if (ws.isAlive === false) {
      console.log('[CloudTerminal] Terminating stale connection.');
      return ws.terminate();
    }
    ws.isAlive = false;
    ws.ping();
  });
}, HEARTBEAT_INTERVAL);

wss.on('close', () => clearInterval(heartbeat));

wss.on('connection', (ws, req) => {
  const clientIp = req.socket.remoteAddress;
  console.log(`[CloudTerminal] Client connected from ${clientIp}`);

  ws.isAlive = true;
  ws.on('pong', () => { ws.isAlive = true; });

  // Session state
  let shell = null;       // node-pty instance (local mode)
  let sshConn = null;     // ssh2 Client instance (SSH mode)
  let sshStream = null;   // SSH shell stream
  let sessionMode = null; // 'local' | 'ssh'

  // ── Helper: Start local bash session ──
  function startLocalShell() {
    if (sessionMode) return; // Already started
    sessionMode = 'local';

    shell = pty.spawn('bash', [], {
      name: 'xterm-256color',
      cols: 80,
      rows: 30,
      cwd: process.env.HOME || '/root',
      env: {
        ...process.env,
        TERM: 'xterm-256color',
        COLORTERM: 'truecolor',
      },
    });

    console.log(`[CloudTerminal] Local shell spawned (PID: ${shell.pid})`);

    shell.onData((data) => {
      if (ws.readyState === WebSocket.OPEN) ws.send(data);
    });

    shell.onExit(({ exitCode, signal }) => {
      console.log(`[CloudTerminal] Local shell exited (code: ${exitCode}, signal: ${signal})`);
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(`\r\n\x1b[33m[Session ended: exit code ${exitCode}]\x1b[0m\r\n`);
        ws.close(1000, 'Shell exited');
      }
    });
  }

  // ── Helper: Start SSH session to user's VPS ──
  function startSSHSession(config) {
    sessionMode = 'ssh';
    sshConn = new SSHClient();

    const sshConfig = {
      host: config.host,
      port: parseInt(config.port || '22', 10),
      username: config.username,
      readyTimeout: 10000,
    };

    // Support password or private key auth
    if (config.privateKey) {
      sshConfig.privateKey = config.privateKey;
      if (config.passphrase) sshConfig.passphrase = config.passphrase;
    } else {
      sshConfig.password = config.password;
    }

    console.log(`[SSH Proxy] Connecting to ${config.username}@${config.host}:${sshConfig.port}...`);

    sshConn.on('ready', () => {
      console.log(`[SSH Proxy] Connected to ${config.host}`);
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({ type: 'ssh_status', status: 'connected', host: config.host }));
      }

      sshConn.shell(
        {
          term: 'xterm-256color',
          cols: config.cols || 80,
          rows: config.rows || 30,
        },
        (err, stream) => {
          if (err) {
            console.error('[SSH Proxy] Shell error:', err.message);
            if (ws.readyState === WebSocket.OPEN) {
              ws.send(`\r\n\x1b[31m[SSH Shell Error]: ${err.message}\x1b[0m\r\n`);
            }
            return;
          }

          sshStream = stream;

          // SSH stdout -> WebSocket client
          stream.on('data', (data) => {
            if (ws.readyState === WebSocket.OPEN) {
              ws.send(data.toString('utf-8'));
            }
          });

          // SSH stderr -> WebSocket client (in red)
          stream.stderr.on('data', (data) => {
            if (ws.readyState === WebSocket.OPEN) {
              ws.send(data.toString('utf-8'));
            }
          });

          stream.on('close', () => {
            console.log('[SSH Proxy] SSH stream closed.');
            if (ws.readyState === WebSocket.OPEN) {
              ws.send('\r\n\x1b[33m[SSH Session Closed]\x1b[0m\r\n');
              ws.send(JSON.stringify({ type: 'ssh_status', status: 'disconnected' }));
            }
            sshConn.end();
          });
        }
      );
    });

    sshConn.on('error', (err) => {
      console.error('[SSH Proxy] Connection error:', err.message);
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(`\r\n\x1b[31m[SSH Connection Failed]: ${err.message}\x1b[0m\r\n`);
        ws.send(JSON.stringify({ type: 'ssh_status', status: 'error', message: err.message }));
      }
      sessionMode = null;
    });

    sshConn.on('close', () => {
      console.log('[SSH Proxy] Connection closed.');
      sshStream = null;
      sshConn = null;
      sessionMode = null;
    });

    sshConn.connect(sshConfig);
  }

  // ── Handle incoming WebSocket messages ──
  ws.on('message', (message) => {
    const msg = message.toString();

    // Check for JSON control messages
    if (msg.startsWith('{')) {
      try {
        const parsed = JSON.parse(msg);

        // SSH connect request
        if (parsed.type === 'ssh_connect') {
          // Kill any existing session first
          cleanup();
          startSSHSession(parsed);
          return;
        }

        // SSH disconnect request
        if (parsed.type === 'ssh_disconnect') {
          cleanup();
          if (ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({ type: 'ssh_status', status: 'disconnected' }));
          }
          return;
        }

        // Terminal resize
        if (parsed.type === 'resize' && parsed.cols && parsed.rows) {
          const cols = Math.max(1, Math.min(parsed.cols, 500));
          const rows = Math.max(1, Math.min(parsed.rows, 200));
          if (sessionMode === 'local' && shell) {
            shell.resize(cols, rows);
          } else if (sessionMode === 'ssh' && sshStream) {
            sshStream.setWindow(rows, cols, 0, 0);
          }
          return;
        }

        // File sync
        if (parsed.type === 'sync_file' && parsed.relativePath) {
          const fullPath = path.join(WORKSPACE_DIR, parsed.relativePath);
          fs.mkdirSync(path.dirname(fullPath), { recursive: true });
          fs.writeFileSync(fullPath, parsed.content || '');
          return;
        }

        if (parsed.type === 'sync_workspace' && Array.isArray(parsed.files)) {
          parsed.files.forEach(f => {
            if (!f.relativePath) return;
            const fullPath = path.join(WORKSPACE_DIR, f.relativePath);
            fs.mkdirSync(path.dirname(fullPath), { recursive: true });
            fs.writeFileSync(fullPath, f.content || '');
          });
          return;
        }
      } catch (_) {
        // Not valid JSON, treat as stdin
      }
    }

    // Auto-start local shell on first raw stdin if no session exists
    if (!sessionMode) {
      startLocalShell();
    }

    // Route stdin to active session
    if (sessionMode === 'local' && shell) {
      shell.write(msg);
    } else if (sessionMode === 'ssh' && sshStream) {
      sshStream.write(msg);
    }
  });

  // ── Cleanup function ──
  function cleanup() {
    if (shell) {
      shell.kill();
      shell = null;
    }
    if (sshStream) {
      sshStream.close();
      sshStream = null;
    }
    if (sshConn) {
      sshConn.end();
      sshConn = null;
    }
    sessionMode = null;
  }

  ws.on('close', () => {
    console.log(`[CloudTerminal] Client disconnected.`);
    cleanup();
  });

  ws.on('error', (err) => {
    console.error(`[CloudTerminal] WebSocket error:`, err.message);
    cleanup();
  });
});

httpServer.listen(PORT, () => {
  console.log(`[CloudTerminal] Server listening on http://0.0.0.0:${PORT}`);
  console.log(`[CloudTerminal] Health check: http://0.0.0.0:${PORT}/health`);
  console.log(`[CloudTerminal] Supports: Local PTY + SSH Proxy modes`);
});
