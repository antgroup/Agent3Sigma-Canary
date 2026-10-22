import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import * as fs from 'node:fs/promises';
import * as path from 'node:path';
import * as os from 'node:os';
import { harden, rollback, listBackups } from './hardener.js';
import type { AuditContext, OpenClawConfig } from './types.js';

describe('hardener', () => {
  let tmpDir: string;

  beforeEach(async () => {
    tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'sc-hardener-test-'));
  });

  afterEach(async () => {
    await fs.rm(tmpDir, { recursive: true, force: true });
  });

  function makeCtx(config: OpenClawConfig = {}): AuditContext {
    return {
      stateDir: tmpDir,
      config,
      platform: 'darwin-arm64',
      deploymentMode: 'native',
      openclawVersion: '2026.2.0',
      channels: [],
      skills: [],
      async fileInfo(p) { return { path: p, exists: true }; },
      async readFile(p) {
        try { return await fs.readFile(p, 'utf-8'); } catch { return null; }
      },
      async listDir(p) { return fs.readdir(p); },
      async fileExists(p) {
        try { await fs.access(p); return true; } catch { return false; }
      },
      async getFilePermissions(p) {
        try { const s = await fs.stat(p); return s.mode & 0o777; } catch { return null; }
      },
    };
  }

  it('creates a backup directory', async () => {
    const configPath = path.join(tmpDir, 'openclaw.json');
    await fs.writeFile(configPath, JSON.stringify({
      gateway: { bind: '0.0.0.0' },
      exec: { approvals: 'off' },
    }), 'utf-8');

    const ctx = makeCtx({
      gateway: { bind: '0.0.0.0' },
      exec: { approvals: 'off' },
    });

    const result = await harden({ full: true, context: ctx });
    expect(result.backupDir).toBeDefined();

    const backupExists = await fs.access(result.backupDir).then(() => true).catch(() => false);
    expect(backupExists).toBe(true);
  });

  it('applies all hardening modules', async () => {
    const configPath = path.join(tmpDir, 'openclaw.json');
    await fs.writeFile(configPath, JSON.stringify({
      gateway: { bind: '0.0.0.0', auth: { mode: 'none' } },
      exec: { approvals: 'off' },
    }), 'utf-8');

    const ctx = makeCtx({
      gateway: { bind: '0.0.0.0', auth: { mode: 'none' } },
      exec: { approvals: 'off' },
    });

    const result = await harden({ full: true, context: ctx });
    expect(result.results.length).toBeGreaterThan(0);

    // Check that config was updated with valid OpenClaw keys
    const updated = JSON.parse(await fs.readFile(configPath, 'utf-8'));
    expect(updated.gateway.bind).toBe('loopback');
    expect(updated.tools.exec.host).toBe('sandbox');
    // exec and sandbox keys should be stripped (not valid in OpenClaw schema)
    expect(updated.exec).toBeUndefined();
    expect(updated.sandbox).toBeUndefined();
  });

  it('writes a manifest file', async () => {
    const configPath = path.join(tmpDir, 'openclaw.json');
    await fs.writeFile(configPath, JSON.stringify({}), 'utf-8');

    const ctx = makeCtx({});
    const result = await harden({ full: true, context: ctx });

    const manifestPath = path.join(result.backupDir, 'manifest.json');
    const manifest = JSON.parse(await fs.readFile(manifestPath, 'utf-8'));
    expect(manifest.timestamp).toBeDefined();
    expect(manifest.modules).toBeDefined();
  });

  it('can list backups', async () => {
    const configPath = path.join(tmpDir, 'openclaw.json');
    await fs.writeFile(configPath, JSON.stringify({}), 'utf-8');

    const ctx = makeCtx({});
    await harden({ full: true, context: ctx });

    const backups = await listBackups(tmpDir);
    expect(backups.length).toBeGreaterThan(0);
  });

  it('rollback restores original config', async () => {
    const configPath = path.join(tmpDir, 'openclaw.json');
    const originalConfig = { gateway: { bind: '0.0.0.0' }, exec: { approvals: 'off' } };
    await fs.writeFile(configPath, JSON.stringify(originalConfig), 'utf-8');

    const ctx = makeCtx(originalConfig);
    const result = await harden({ full: true, context: ctx });

    // Config should be hardened now
    const hardened = JSON.parse(await fs.readFile(configPath, 'utf-8'));
    expect(hardened.gateway.bind).toBe('loopback');

    // Rollback to the backup
    const backupTimestamp = path.basename(result.backupDir);
    await rollback(tmpDir, backupTimestamp);

    const restored = JSON.parse(await fs.readFile(configPath, 'utf-8'));
    expect(restored.gateway.bind).toBe('0.0.0.0');
  });

  it('rollback throws when no backups exist', async () => {
    await expect(rollback(tmpDir)).rejects.toThrow('No backups available');
  });
});
