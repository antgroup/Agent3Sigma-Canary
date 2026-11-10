import * as path from 'node:path';
import * as fs from 'node:fs/promises';
import type { FSWatcher } from 'chokidar';
import type { Monitor, MonitorStatus, MonitorAlert, AlertCallback } from '../types.js';

let watcher: FSWatcher | null = null;
let alertCallbacks: AlertCallback[] = [];
let alerts: MonitorAlert[] = [];
let running = false;
let lastCheck: string | undefined;

function emitAlert(alert: MonitorAlert): void {
  alerts.push(alert);
  for (const cb of alertCallbacks) {
    cb(alert);
  }
}

export const credentialMonitor: Monitor = {
  name: 'credential-monitor',

  async start(stateDir: string): Promise<void> {
    if (running) return;

    const credsDir = path.join(stateDir, 'credentials');
    const envPath = path.join(stateDir, '.env');

    // Dynamically import chokidar to avoid issues when not installed
    let chokidar: typeof import('chokidar');
    try {
      chokidar = await import('chokidar');
    } catch {
      emitAlert({
        timestamp: new Date().toISOString(),
        severity: 'INFO',
        monitor: 'credential-monitor',
        message: 'chokidar not available, credential monitoring disabled',
      });
      return;
    }

    const watchPaths: string[] = [];

    // Check which paths exist
    try {
      await fs.access(credsDir);
      watchPaths.push(credsDir);
    } catch {
      // No credentials directory
    }

    try {
      await fs.access(envPath);
      watchPaths.push(envPath);
    } catch {
      // No .env file
    }

    if (watchPaths.length === 0) {
      running = true;
      lastCheck = new Date().toISOString();
      return;
    }

    watcher = chokidar.watch(watchPaths, {
      persistent: true,
      ignoreInitial: true,
      awaitWriteFinish: { stabilityThreshold: 500 },
    });

    watcher.on('add', (filePath: string) => {
      emitAlert({
        timestamp: new Date().toISOString(),
        severity: 'HIGH',
        monitor: 'credential-monitor',
        message: `New credential file detected: ${path.basename(filePath)}`,
        details: `Path: ${filePath}`,
      });
    });

    watcher.on('change', (filePath: string) => {
      lastCheck = new Date().toISOString();
      // Check if permissions changed
      fs.stat(filePath).then((stat) => {
        const mode = stat.mode & 0o777;
        if ((mode & 0o077) !== 0) {
          emitAlert({
            timestamp: new Date().toISOString(),
            severity: 'CRITICAL',
            monitor: 'credential-monitor',
            message: `Credential file permissions are too open: ${path.basename(filePath)} (${mode.toString(8)})`,
            details: `Path: ${filePath}, Permissions: ${mode.toString(8)}`,
          });
        }
      }).catch(() => {
        // File may have been deleted
      });
    });

    watcher.on('unlink', (filePath: string) => {
      emitAlert({
        timestamp: new Date().toISOString(),
        severity: 'MEDIUM',
        monitor: 'credential-monitor',
        message: `Credential file deleted: ${path.basename(filePath)}`,
        details: `Path: ${filePath}`,
      });
    });

    running = true;
    lastCheck = new Date().toISOString();
  },

  async stop(): Promise<void> {
    if (watcher) {
      await watcher.close();
      watcher = null;
    }
    running = false;
  },

  status(): MonitorStatus {
    return {
      running,
      lastCheck,
      alerts: [...alerts],
    };
  },

  onAlert(callback: AlertCallback): void {
    alertCallbacks.push(callback);
  },
};

/**
 * Reset monitor state (for testing).
 */
export function resetCredentialMonitor(): void {
  alerts = [];
  alertCallbacks = [];
  running = false;
  lastCheck = undefined;
  watcher = null;
}
