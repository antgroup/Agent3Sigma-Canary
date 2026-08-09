import * as fs from 'node:fs/promises';
import * as path from 'node:path';
import { gatewayHardening } from './hardening/gateway-hardening.js';
import { credentialHardening } from './hardening/credential-hardening.js';
import { configHardening } from './hardening/config-hardening.js';
import { dockerHardening } from './hardening/docker-hardening.js';
import { networkHardening } from './hardening/network-hardening.js';
import type {
  AuditContext,
  HardenOptions,
  HardeningModule,
  HardeningResult,
} from './types.js';

// Hardening modules in priority order
const MODULES: HardeningModule[] = [
  gatewayHardening,
  credentialHardening,
  configHardening,
  dockerHardening,
  networkHardening,
].sort((a, b) => a.priority - b.priority);

/**
 * Create a timestamped backup directory.
 */
async function createBackupDir(stateDir: string): Promise<string> {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupDir = path.join(stateDir, '.secureclaw', 'backup', timestamp);
  await fs.mkdir(backupDir, { recursive: true });
  return backupDir;
}

/**
 * List available backups, sorted newest first.
 */
export async function listBackups(stateDir: string): Promise<string[]> {
  const backupBase = path.join(stateDir, '.secureclaw', 'backup');
  try {
    const entries = await fs.readdir(backupBase);
    return entries.sort().reverse();
  } catch {
    return [];
  }
}

/**
 * Run all hardening modules in priority order.
 */
export async function harden(options: HardenOptions = {}): Promise<{
  backupDir: string;
  results: HardeningResult[];
}> {
  const ctx = options.context;
  if (!ctx) {
    throw new Error('AuditContext is required. Provide it via options.context');
  }

  const backupDir = await createBackupDir(ctx.stateDir);
  const results: HardeningResult[] = [];

  // Backup the main config file before any changes
  const configPath = path.join(ctx.stateDir, 'openclaw.json');
  try {
    await fs.access(configPath);
    await fs.copyFile(configPath, path.join(backupDir, 'openclaw.json.original'));
  } catch (err: unknown) {
    // Only ignore if the file doesn't exist; propagate real I/O errors
    const code = (err as NodeJS.ErrnoException)?.code;
    if (code !== 'ENOENT') {
      throw new Error(`Failed to backup config before hardening: ${err}`);
    }
  }

  for (const mod of MODULES) {
    if (options.interactive) {
      // In interactive mode, check first and show findings
      const findings = await mod.check(ctx);
      if (findings.length === 0) {
        results.push({
          module: mod.name,
          applied: [],
          skipped: [],
          errors: [],
        });
        continue;
      }
      // In interactive mode, the caller would show findings and get confirmation.
      // Since we're a library, we just apply all fixes.
      // The interactive CLI layer would handle prompts.
    }

    const result = await mod.fix(ctx, backupDir);
    results.push(result);
  }

  // Write a manifest of what was done
  const manifest = {
    timestamp: new Date().toISOString(),
    backupDir,
    modules: results.map((r) => ({
      module: r.module,
      actionsApplied: r.applied.length,
      actionsSkipped: r.skipped.length,
      errors: r.errors.length,
    })),
  };
  await fs.writeFile(
    path.join(backupDir, 'manifest.json'),
    JSON.stringify(manifest, null, 2),
    'utf-8'
  );

  return { backupDir, results };
}

/**
 * Rollback to a previous backup.
 */
export async function rollback(stateDir: string, timestamp?: string): Promise<void> {
  const backups = await listBackups(stateDir);
  if (backups.length === 0) {
    throw new Error('No backups available for rollback');
  }

  const targetTimestamp = timestamp ?? backups[0];
  const backupDir = path.join(stateDir, '.secureclaw', 'backup', targetTimestamp);

  try {
    await fs.access(backupDir);
  } catch {
    throw new Error(`Backup directory not found: ${backupDir}`);
  }

  // Restore the original config
  const originalConfig = path.join(backupDir, 'openclaw.json.original');
  const targetConfig = path.join(stateDir, 'openclaw.json');
  try {
    await fs.copyFile(originalConfig, targetConfig);
  } catch {
    // Try the non-suffixed backup
    try {
      await fs.copyFile(path.join(backupDir, 'openclaw.json'), targetConfig);
    } catch {
      throw new Error('No config backup found in backup directory');
    }
  }

  // Restore any other backed-up files
  const backupFiles = await fs.readdir(backupDir);
  for (const file of backupFiles) {
    if (file === 'manifest.json') continue;
    if (file === 'openclaw.json.original') continue;
    if (file === 'openclaw.json') continue;
    if (file === 'openclaw-config.json') continue; // duplicate

    // Restore credential files
    if (file.startsWith('cred-')) {
      const originalName = file.replace(/^cred-/, '');
      const destPath = path.join(stateDir, 'credentials', originalName);
      try {
        await fs.copyFile(path.join(backupDir, file), destPath);
      } catch {
        // Skip if destination dir doesn't exist
      }
    }

    // Restore .env
    if (file === '.env') {
      await fs.copyFile(path.join(backupDir, file), path.join(stateDir, '.env'));
    }

    // Restore auth-profiles
    if (file.startsWith('auth-profiles-')) {
      const agent = file.replace(/^auth-profiles-/, '').replace(/\.json$/, '');
      const destPath = path.join(stateDir, 'agents', agent, 'agent', 'auth-profiles.json');
      try {
        await fs.copyFile(path.join(backupDir, file), destPath);
      } catch {
        // Skip
      }
    }

    // Restore memory files
    const memoryMatch = file.match(/^(.+)-(soul\.md|SOUL\.md|MEMORY\.md)$/);
    if (memoryMatch) {
      const agent = memoryMatch[1];
      const memFile = memoryMatch[2];
      const destPath = path.join(stateDir, 'agents', agent, memFile);
      try {
        await fs.copyFile(path.join(backupDir, file), destPath);
      } catch {
        // Skip
      }
    }
  }
}
