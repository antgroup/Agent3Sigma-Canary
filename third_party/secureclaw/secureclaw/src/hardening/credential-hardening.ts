import * as fs from 'node:fs/promises';
import * as path from 'node:path';
import { encrypt, ensureKeystore } from '../utils/crypto.js';
import type {
  AuditContext,
  AuditFinding,
  HardeningModule,
  HardeningResult,
  HardeningAction,
} from '../types.js';

const API_KEY_PATTERNS = [
  /sk-ant-[a-zA-Z0-9_-]{20,}/g,
  /sk-proj-[a-zA-Z0-9_-]{20,}/g,
  /sk-[a-zA-Z0-9_-]{20,}/g,
  /xoxb-[a-zA-Z0-9_-]{20,}/g,
  /xoxp-[a-zA-Z0-9_-]{20,}/g,
];

function redactApiKeys(content: string): string {
  let redacted = content;
  for (const pattern of API_KEY_PATTERNS) {
    // Reset lastIndex for global regex
    pattern.lastIndex = 0;
    redacted = redacted.replace(pattern, '[REDACTED_BY_SECURECLAW]');
  }
  return redacted;
}

async function chmodSafe(filePath: string, mode: number): Promise<boolean> {
  try {
    await fs.chmod(filePath, mode);
    return true;
  } catch {
    return false;
  }
}

export const credentialHardening: HardeningModule = {
  name: 'credential-hardening',
  priority: 2,

  async check(ctx: AuditContext): Promise<AuditFinding[]> {
    const findings: AuditFinding[] = [];

    const stateDirPerms = await ctx.getFilePermissions(ctx.stateDir);
    if (stateDirPerms !== null && (stateDirPerms & 0o077) !== 0) {
      findings.push({
        id: 'SC-CRED-001',
        severity: 'HIGH',
        category: 'credentials',
        title: 'State directory permissions too open',
        description: 'Will chmod 700 the state directory.',
        evidence: `Permissions: ${stateDirPerms.toString(8)}`,
        remediation: 'chmod 700',
        autoFixable: true,
        references: [],
        owaspAsi: 'ASI03',
      });
    }

    return findings;
  },

  async fix(ctx: AuditContext, backupDir: string): Promise<HardeningResult> {
    const applied: HardeningAction[] = [];
    const skipped: HardeningAction[] = [];
    const errors: string[] = [];

    try {
      // 1. Lock state directory permissions
      const stateDirFixed = await chmodSafe(ctx.stateDir, 0o700);
      if (stateDirFixed) {
        applied.push({
          id: 'cred-statedir-perms',
          description: 'Set state directory permissions to 700',
          before: 'open',
          after: '700',
        });
      }

      // 2. Lock config file permissions
      const configPath = path.join(ctx.stateDir, 'openclaw.json');
      const configFixed = await chmodSafe(configPath, 0o600);
      if (configFixed) {
        applied.push({
          id: 'cred-config-perms',
          description: 'Set config file permissions to 600',
          before: 'open',
          after: '600',
        });
      }

      // 3. Lock credential files
      const credsDir = path.join(ctx.stateDir, 'credentials');
      try {
        const credFiles = await fs.readdir(credsDir);
        for (const file of credFiles) {
          if (!file.endsWith('.json')) continue;
          const filePath = path.join(credsDir, file);
          // Backup
          try {
            await fs.copyFile(filePath, path.join(backupDir, `cred-${file}`));
          } catch {
            // skip
          }
          const fixed = await chmodSafe(filePath, 0o600);
          if (fixed) {
            applied.push({
              id: `cred-${file}-perms`,
              description: `Set ${file} permissions to 600`,
              before: 'open',
              after: '600',
            });
          }
        }
      } catch {
        // No credentials directory
      }

      // 4. Lock auth-profiles
      const agentsDir = path.join(ctx.stateDir, 'agents');
      try {
        const agents = await fs.readdir(agentsDir);
        for (const agent of agents) {
          const authPath = path.join(agentsDir, agent, 'agent', 'auth-profiles.json');
          try {
            await fs.access(authPath);
            await fs.copyFile(authPath, path.join(backupDir, `auth-profiles-${agent}.json`));
            await chmodSafe(authPath, 0o600);
            applied.push({
              id: `cred-auth-${agent}`,
              description: `Set auth-profiles.json permissions for agent "${agent}" to 600`,
              before: 'open',
              after: '600',
            });
          } catch {
            // File doesn't exist
          }
        }
      } catch {
        // No agents directory
      }

      // 5. Encrypt .env file
      const envPath = path.join(ctx.stateDir, '.env');
      try {
        const envContent = await fs.readFile(envPath, 'utf-8');
        // Backup
        await fs.copyFile(envPath, path.join(backupDir, '.env'));

        const { machineId } = await ensureKeystore(ctx.stateDir);
        const encrypted = encrypt(envContent, machineId, ctx.stateDir);
        await fs.writeFile(envPath + '.enc', encrypted, { mode: 0o600 });
        applied.push({
          id: 'cred-env-encrypt',
          description: 'Encrypted .env file',
          before: 'plaintext',
          after: '.env.enc (AES-256-GCM)',
        });
      } catch {
        // No .env file or encryption failed
      }

      // 6. Redact API keys from memory/soul files
      try {
        const agents = await fs.readdir(agentsDir);
        for (const agent of agents) {
          const memoryFiles = ['soul.md', 'SOUL.md', 'MEMORY.md'];
          for (const memFile of memoryFiles) {
            const memPath = path.join(agentsDir, agent, memFile);
            try {
              const content = await fs.readFile(memPath, 'utf-8');
              const redacted = redactApiKeys(content);
              if (redacted !== content) {
                await fs.copyFile(memPath, path.join(backupDir, `${agent}-${memFile}`));
                await fs.writeFile(memPath, redacted, 'utf-8');
                applied.push({
                  id: `cred-redact-${agent}-${memFile}`,
                  description: `Redacted API keys from ${memFile} for agent "${agent}"`,
                  before: 'contained API keys',
                  after: 'keys redacted',
                });
              }
            } catch {
              // File doesn't exist
            }
          }
        }
      } catch {
        // No agents directory
      }
    } catch (err) {
      errors.push(`Credential hardening error: ${err instanceof Error ? err.message : String(err)}`);
    }

    return { module: 'credential-hardening', applied, skipped, errors };
  },

  async rollback(backupDir: string): Promise<void> {
    // Rollback is handled by the orchestrator
  },
};
