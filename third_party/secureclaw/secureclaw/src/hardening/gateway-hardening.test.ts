import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import * as fs from 'node:fs/promises';
import * as path from 'node:path';
import * as os from 'node:os';
import { gatewayHardening } from './gateway-hardening.js';
import type { AuditContext, OpenClawConfig } from '../types.js';

describe('gateway-hardening', () => {
  let tmpDir: string;
  let backupDir: string;

  beforeEach(async () => {
    tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'sc-gw-test-'));
    backupDir = path.join(tmpDir, 'backup');
    await fs.mkdir(backupDir, { recursive: true });
  });

  afterEach(async () => {
    await fs.rm(tmpDir, { recursive: true, force: true });
  });

  function makeCtx(config: OpenClawConfig): AuditContext {
    return {
      stateDir: tmpDir,
      config,
      platform: 'darwin-arm64',
      deploymentMode: 'native',
      openclawVersion: '2026.2.0',
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

  it('check() detects insecure gateway config', async () => {
    const ctx = makeCtx({ gateway: { bind: '0.0.0.0', auth: { mode: 'none' } } });
    const findings = await gatewayHardening.check(ctx);
    expect(findings.length).toBeGreaterThan(0);
    expect(findings.some((f) => f.id === 'SC-GW-001')).toBe(true);
    expect(findings.some((f) => f.id === 'SC-GW-002')).toBe(true);
  });

  it('fix() creates backup and applies fixes', async () => {
    const configPath = path.join(tmpDir, 'openclaw.json');
    await fs.writeFile(configPath, JSON.stringify({
      gateway: { bind: '0.0.0.0', auth: { mode: 'none' } },
    }), 'utf-8');

    const ctx = makeCtx({ gateway: { bind: '0.0.0.0', auth: { mode: 'none' } } });
    const result = await gatewayHardening.fix(ctx, backupDir);

    // Backup was created
    const backupFiles = await fs.readdir(backupDir);
    expect(backupFiles).toContain('openclaw.json');

    // Config was updated
    const updatedConfig = JSON.parse(await fs.readFile(configPath, 'utf-8'));
    expect(updatedConfig.gateway.bind).toBe('loopback');
    expect(updatedConfig.gateway.auth.mode).toBe('password');
    expect(updatedConfig.gateway.auth.password.length).toBeGreaterThanOrEqual(64);

    // Result shows actions taken
    expect(result.applied.length).toBeGreaterThan(0);
    expect(result.errors).toHaveLength(0);
  });

  it('fix() disables dangerous flags', async () => {
    const configPath = path.join(tmpDir, 'openclaw.json');
    await fs.writeFile(configPath, JSON.stringify({
      gateway: {
        bind: 'loopback',
        auth: { mode: 'password', password: 'a'.repeat(64) },
        controlUi: { dangerouslyDisableDeviceAuth: true, allowInsecureAuth: true },
      },
    }), 'utf-8');

    const ctx = makeCtx({
      gateway: {
        bind: 'loopback',
        auth: { mode: 'password', password: 'a'.repeat(64) },
        controlUi: { dangerouslyDisableDeviceAuth: true, allowInsecureAuth: true },
      },
    });
    await gatewayHardening.fix(ctx, backupDir);

    const updatedConfig = JSON.parse(await fs.readFile(configPath, 'utf-8'));
    expect(updatedConfig.gateway.controlUi.dangerouslyDisableDeviceAuth).toBe(false);
    expect(updatedConfig.gateway.controlUi.allowInsecureAuth).toBe(false);
  });

  it('fix() is idempotent when config already hardened', async () => {
    const configPath = path.join(tmpDir, 'openclaw.json');
    await fs.writeFile(configPath, JSON.stringify({
      gateway: {
        bind: 'loopback',
        auth: { mode: 'password', password: 'a'.repeat(64) },
        controlUi: { dangerouslyDisableDeviceAuth: false, allowInsecureAuth: false },
        trustedProxies: [],
      },
    }), 'utf-8');

    const ctx = makeCtx({
      gateway: {
        bind: 'loopback',
        auth: { mode: 'password', password: 'a'.repeat(64) },
        controlUi: { dangerouslyDisableDeviceAuth: false, allowInsecureAuth: false },
        trustedProxies: [],
      },
    });

    const backupDir2 = path.join(tmpDir, 'backup2');
    await fs.mkdir(backupDir2, { recursive: true });
    const result = await gatewayHardening.fix(ctx, backupDir2);
    expect(result.applied).toHaveLength(0);
  });

  it('fix() strips gateway.mdns key (not in OpenClaw schema)', async () => {
    const configPath = path.join(tmpDir, 'openclaw.json');
    await fs.writeFile(configPath, JSON.stringify({
      gateway: {
        bind: 'loopback',
        auth: { mode: 'password', password: 'a'.repeat(64) },
        mdns: { mode: 'full' },
        controlUi: {},
        trustedProxies: [],
      },
    }), 'utf-8');

    const ctx = makeCtx({
      gateway: {
        bind: 'loopback',
        auth: { mode: 'password', password: 'a'.repeat(64) },
        mdns: { mode: 'full' },
        controlUi: {},
        trustedProxies: [],
      },
    });

    const backupDir2 = path.join(tmpDir, 'backup2');
    await fs.mkdir(backupDir2, { recursive: true });
    const result = await gatewayHardening.fix(ctx, backupDir2);

    // mdns key should be stripped
    const updated = JSON.parse(await fs.readFile(configPath, 'utf-8'));
    expect(updated.gateway.mdns).toBeUndefined();
    expect(result.applied.some(a => a.id === 'gw-strip-mdns')).toBe(true);
  });
});
