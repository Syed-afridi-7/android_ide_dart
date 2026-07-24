import { VFSNode, VFSEntry, VirtualFileSystem } from '../types/terminal';

const DB_NAME = 'web_terminal_vfs_db';
const STORE_NAME = 'files';
const DB_VERSION = 1;

class IndexedDBVFS implements VirtualFileSystem {
  private dbPromise: Promise<IDBDatabase>;

  constructor() {
    this.dbPromise = this.initDB();
  }

  private initDB(): Promise<IDBDatabase> {
    return new Promise((resolve, reject) => {
      if (typeof window === 'undefined' || !window.indexedDB) {
        reject(new Error('IndexedDB is not available in this environment.'));
        return;
      }

      const request = indexedDB.open(DB_NAME, DB_VERSION);

      request.onupgradeneeded = (event) => {
        const db = (event.target as IDBOpenDBRequest).result;
        if (!db.objectStoreNames.contains(STORE_NAME)) {
          const store = db.createObjectStore(STORE_NAME, { keyPath: 'path' });
          store.createIndex('parent', 'parent', { unique: false });
        }
      };

      request.onsuccess = async () => {
        const db = request.result;
        resolve(db);
        // Ensure root directory exists
        const root = await this.getNode('/');
        if (!root) {
          await this.putNode({
            name: '/',
            path: '/',
            isDirectory: true,
            updatedAt: Date.now(),
            size: 0,
          });
        }
      };

      request.onerror = () => reject(request.error);
    });
  }

  private async getNode(path: string): Promise<VFSNode | null> {
    const db = await this.dbPromise;
    const normalized = this.normalizePath(path);
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE_NAME, 'readonly');
      const store = tx.objectStore(STORE_NAME);
      const req = store.get(normalized);
      req.onsuccess = () => resolve(req.result || null);
      req.onerror = () => reject(req.error);
    });
  }

  private async putNode(node: VFSNode): Promise<void> {
    const db = await this.dbPromise;
    const normalized = this.normalizePath(node.path);
    const parent = this.getParentPath(normalized);

    const record = {
      ...node,
      path: normalized,
      parent: parent,
    };

    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE_NAME, 'readwrite');
      const store = tx.objectStore(STORE_NAME);
      const req = store.put(record);
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  }

  public normalizePath(path: string): string {
    if (!path || path === '/') return '/';

    const parts = path.split('/').filter(Boolean);
    const stack: string[] = [];

    for (const part of parts) {
      if (part === '.') continue;
      if (part === '..') {
        stack.pop();
      } else {
        stack.push(part);
      }
    }

    return '/' + stack.join('/');
  }

  public getParentPath(path: string): string {
    const normalized = this.normalizePath(path);
    if (normalized === '/') return '/';
    const lastSlash = normalized.lastIndexOf('/');
    if (lastSlash === 0) return '/';
    return normalized.substring(0, lastSlash);
  }

  public resolvePath(cwd: string, targetPath: string): string {
    if (!targetPath) return this.normalizePath(cwd);
    if (targetPath.startsWith('/')) {
      return this.normalizePath(targetPath);
    }
    if (targetPath.startsWith('~')) {
      return this.normalizePath('/home/user' + targetPath.substring(1));
    }
    return this.normalizePath(cwd + '/' + targetPath);
  }

  async exists(path: string): Promise<boolean> {
    const node = await this.getNode(path);
    return node !== null;
  }

  async stat(path: string): Promise<VFSNode | null> {
    return this.getNode(path);
  }

  async readFile(path: string): Promise<string> {
    const node = await this.getNode(path);
    if (!node) {
      throw new Error(`cat: ${path}: No such file or directory`);
    }
    if (node.isDirectory) {
      throw new Error(`cat: ${path}: Is a directory`);
    }
    return node.content || '';
  }

  async writeFile(path: string, content: string): Promise<void> {
    const normalized = this.normalizePath(path);
    const parentPath = this.getParentPath(normalized);

    if (parentPath !== '/') {
      const parentNode = await this.getNode(parentPath);
      if (!parentNode || !parentNode.isDirectory) {
        throw new Error(`Cannot create file ${path}: Parent directory does not exist`);
      }
    }

    const filename = normalized.split('/').pop() || '';
    await this.putNode({
      name: filename,
      path: normalized,
      isDirectory: false,
      content: content,
      updatedAt: Date.now(),
      size: new Blob([content]).size,
    });
  }

  async appendFile(path: string, content: string): Promise<void> {
    const normalized = this.normalizePath(path);
    const node = await this.getNode(normalized);

    if (!node) {
      await this.writeFile(normalized, content);
      return;
    }

    if (node.isDirectory) {
      throw new Error(`Cannot append: ${path} is a directory`);
    }

    const updatedContent = (node.content || '') + content;
    await this.writeFile(normalized, updatedContent);
  }

  async mkdir(path: string): Promise<void> {
    const normalized = this.normalizePath(path);
    if (await this.exists(normalized)) {
      throw new Error(`mkdir: cannot create directory '${path}': File exists`);
    }

    const parentPath = this.getParentPath(normalized);
    if (parentPath !== '/' && !(await this.exists(parentPath))) {
      await this.mkdir(parentPath); // Auto parent recursive creation
    }

    const dirname = normalized.split('/').pop() || '';
    await this.putNode({
      name: dirname,
      path: normalized,
      isDirectory: true,
      updatedAt: Date.now(),
      size: 0,
    });
  }

  async rmdir(path: string, recursive: boolean = false): Promise<void> {
    const normalized = this.normalizePath(path);
    const node = await this.getNode(normalized);

    if (!node) {
      throw new Error(`rmdir: failed to remove '${path}': No such file or directory`);
    }
    if (!node.isDirectory) {
      throw new Error(`rmdir: failed to remove '${path}': Not a directory`);
    }

    const children = await this.readdir(normalized);
    if (children.length > 0 && !recursive) {
      throw new Error(`rmdir: failed to remove '${path}': Directory not empty`);
    }

    if (recursive) {
      for (const child of children) {
        const childPath = this.normalizePath(normalized + '/' + child.name);
        if (child.isDirectory) {
          await this.rmdir(childPath, true);
        } else {
          await this.unlink(childPath);
        }
      }
    }

    await this.unlink(normalized);
  }

  async unlink(path: string): Promise<void> {
    const db = await this.dbPromise;
    const normalized = this.normalizePath(path);

    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE_NAME, 'readwrite');
      const store = tx.objectStore(STORE_NAME);
      const req = store.delete(normalized);
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  }

  async readdir(path: string): Promise<VFSEntry[]> {
    const db = await this.dbPromise;
    const normalized = this.normalizePath(path);
    const dirNode = await this.getNode(normalized);

    if (!dirNode) {
      throw new Error(`ls: cannot access '${path}': No such file or directory`);
    }
    if (!dirNode.isDirectory) {
      throw new Error(`ls: cannot access '${path}': Not a directory`);
    }

    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE_NAME, 'readonly');
      const store = tx.objectStore(STORE_NAME);
      const index = store.index('parent');
      const req = index.getAll(normalized);

      req.onsuccess = () => {
        const results: VFSNode[] = req.result || [];
        const entries: VFSEntry[] = results.map((n) => ({
          name: n.name,
          isDirectory: n.isDirectory,
          size: n.size,
          updatedAt: n.updatedAt,
        }));
        resolve(entries);
      };

      req.onerror = () => reject(req.error);
    });
  }
}

export const vfsService = new IndexedDBVFS();
