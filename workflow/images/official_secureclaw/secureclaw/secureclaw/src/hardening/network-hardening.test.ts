import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import * as fs from 'node:fs/promises';
import * as path from 'node:path';
import * as os from 'node:os';
import { networkHardening } from './network-hardening.js';
import type { AuditContext, OpenClawConfig } from '../types.js';

describe('network-hardening', () => {
  let tmpDir: string;
  let backupDir: string;

  beforeEach(async () => {
    tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'sc-net-test-'));
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
      async readFile(p) { try { return await fs.readFile(p, 'utf-8'); } catch { return null; } },
      async listDir(p) { return fs.readdir(p); },
      async fileExists(p) { try { await fs.access(p); return true; } catch { return false; } },
      async getFilePermissions(p) { try { const s = await fs.stat(p); return s.mode & 0o777; } catch { return null; } },
    };
  }

  // ── check() tests ──────────────────────────────────────────────────

  it('check() returns INFO finding about network hardening', async () => {
    const ctx = makeCtx();
    const findings = await networkHardening.check(ctx);

    expect(findings).toHaveLength(1);
    expect(findings[0].id).toBe('SC-NET-001');
    expect(findings[0].severity).toBe('INFO');
    expect(findings[0].category).toBe('network');
    expect(findings[0].title).toContain('Network hardening available');
    expect(findings[0].evidence).toContain('darwin-arm64');
    expect(findings[0].autoFixable).toBe(true);
  });

  // ── fix() tests ────────────────────────────────────────────────────

  it('fix() creates network scripts directory', async () => {
    const ctx = makeCtx();
    await networkHardening.fix(ctx, backupDir);

    const scriptDir = path.join(tmpDir, '.secureclaw', 'network');
    const stat = await fs.stat(scriptDir);
    expect(stat.isDirectory()).toBe(true);
  });

  it('fix() generates pf rules on darwin', async () => {
    // Tests run on macOS (darwin), so we should get pf rules
    const ctx = makeCtx();
    const result = await networkHardening.fix(ctx, backupDir);

    expect(result.module).toBe('network-hardening');
    expect(result.errors).toHaveLength(0);

    // On darwin, should generate pf-rules.conf
    const pfApplied = result.applied.find((a) => a.id === 'net-pf');
    expect(pfApplied).toBeDefined();
    expect(pfApplied!.description).toContain('pf');

    const scriptDir = path.join(tmpDir, '.secureclaw', 'network');
    const pfPath = path.join(scriptDir, 'pf-rules.conf');
    const content = await fs.readFile(pfPath, 'utf-8');

    // Verify it contains SecureClaw branding and pf syntax
    expect(content).toContain('SecureClaw');
    expect(content).toContain('pf rules');
    expect(content).toContain('macOS');

    // Verify egress allowlist domains are referenced (commented out)
    expect(content).toContain('api.anthropic.com');
    expect(content).toContain('api.openai.com');

    // Verify pf-specific syntax
    expect(content).toContain('pass out on en0');
    expect(content).toContain('block out');
  });

  it('fix() creates c2-blocklist.txt when blocklist has entries', async () => {
    // The fix() loads the IOC database; if it fails it uses a fallback with
    // empty c2_ips. We provide a custom config with egressAllowlist but the
    // blocklist comes from the IOC db. If the fallback db has empty c2_ips,
    // the blocklist file will not be created.
    //
    // To test blocklist creation, we can check whether the file is created.
    // If loadIOCDatabase() succeeds and returns IPs, we get the file.
    // If it falls back to empty, we won't.
    const ctx = makeCtx();
    const result = await networkHardening.fix(ctx, backupDir);

    const scriptDir = path.join(tmpDir, '.secureclaw', 'network');
    const blocklistPath = path.join(scriptDir, 'c2-blocklist.txt');

    const blocklistAction = result.applied.find((a) => a.id === 'net-blocklist');
    if (blocklistAction) {
      // IOC database loaded successfully and had C2 IPs
      const content = await fs.readFile(blocklistPath, 'utf-8');
      expect(content.trim().length).toBeGreaterThan(0);
      expect(blocklistAction.description).toContain('C2 IP blocklist');
    } else {
      // Fallback db used, no C2 IPs => no blocklist file
      const exists = await fs.access(blocklistPath).then(() => true).catch(() => false);
      expect(exists).toBe(false);
    }
  });

  it('fix() returns correct module name', async () => {
    const ctx = makeCtx();
    const result = await networkHardening.fix(ctx, backupDir);

    expect(result.module).toBe('network-hardening');
  });

  it('fix() uses custom egressAllowlist from config', async () => {
    const ctx = makeCtx({
      secureclaw: {
        network: {
          egressAllowlist: ['custom.example.com', 'api.custom.io'],
        },
      },
    });
    const result = await networkHardening.fix(ctx, backupDir);

    expect(result.errors).toHaveLength(0);

    const scriptDir = path.join(tmpDir, '.secureclaw', 'network');
    const pfPath = path.join(scriptDir, 'pf-rules.conf');
    const content = await fs.readFile(pfPath, 'utf-8');

    // Custom allowlist domains should appear, default ones should not
    expect(content).toContain('custom.example.com');
    expect(content).toContain('api.custom.io');
    expect(content).not.toContain('api.anthropic.com');
  });

  // ── rollback() test ────────────────────────────────────────────────

  it('rollback() is a no-op', async () => {
    await expect(networkHardening.rollback(backupDir)).resolves.toBeUndefined();
  });
});
