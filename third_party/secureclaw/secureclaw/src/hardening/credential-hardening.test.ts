import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import * as fs from 'node:fs/promises';
import * as path from 'node:path';
import * as os from 'node:os';
import { credentialHardening } from './credential-hardening.js';
import { decrypt } from '../utils/crypto.js';
import type { AuditContext, OpenClawConfig } from '../types.js';

// Build fake API keys at runtime so secrets-scanners don't flag the source file.
const FAKE_KEY = ['sk', 'ant', 'abcdefghijklmnopqrstuvwxyz12345'].join('-');

describe('credential-hardening', () => {
  let tmpDir: string;
  let backupDir: string;

  beforeEach(async () => {
    tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'sc-cred-test-'));
    backupDir = path.join(tmpDir, 'backup');
    await fs.mkdir(backupDir, { recursive: true });
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

  it('sets state directory permissions to 700', async () => {
    await fs.chmod(tmpDir, 0o777);
    const ctx = makeCtx();
    await credentialHardening.fix(ctx, backupDir);

    const stat = await fs.stat(tmpDir);
    expect(stat.mode & 0o777).toBe(0o700);
  });

  it('sets config file permissions to 600', async () => {
    const configPath = path.join(tmpDir, 'openclaw.json');
    await fs.writeFile(configPath, '{}', { mode: 0o644 });
    const ctx = makeCtx();
    await credentialHardening.fix(ctx, backupDir);

    const stat = await fs.stat(configPath);
    expect(stat.mode & 0o777).toBe(0o600);
  });

  it('encrypts .env file', async () => {
    const envPath = path.join(tmpDir, '.env');
    await fs.writeFile(envPath, 'API_KEY=test-key-12345', 'utf-8');

    const ctx = makeCtx();
    const result = await credentialHardening.fix(ctx, backupDir);

    // .env.enc should exist
    const encPath = envPath + '.enc';
    const encExists = await fs.access(encPath).then(() => true).catch(() => false);
    expect(encExists).toBe(true);

    // Backup should exist
    const backupExists = await fs.access(path.join(backupDir, '.env')).then(() => true).catch(() => false);
    expect(backupExists).toBe(true);

    // Check that encryption action was recorded
    const encAction = result.applied.find((a) => a.id === 'cred-env-encrypt');
    expect(encAction).toBeDefined();
  });

  it('locks credential file permissions', async () => {
    const credsDir = path.join(tmpDir, 'credentials');
    await fs.mkdir(credsDir, { recursive: true });
    await fs.writeFile(path.join(credsDir, 'google.json'), '{}', { mode: 0o644 });

    const ctx = makeCtx();
    await credentialHardening.fix(ctx, backupDir);

    const stat = await fs.stat(path.join(credsDir, 'google.json'));
    expect(stat.mode & 0o777).toBe(0o600);
  });

  it('redacts API keys from memory files', async () => {
    const agentsDir = path.join(tmpDir, 'agents', 'agent1');
    await fs.mkdir(agentsDir, { recursive: true });
    await fs.writeFile(
      path.join(agentsDir, 'soul.md'),
      `My key is ${FAKE_KEY} and it works great`,
      'utf-8'
    );

    const ctx = makeCtx();
    await credentialHardening.fix(ctx, backupDir);

    const content = await fs.readFile(path.join(agentsDir, 'soul.md'), 'utf-8');
    expect(content).not.toContain(FAKE_KEY);
    expect(content).toContain('[REDACTED_BY_SECURECLAW]');
  });
});
