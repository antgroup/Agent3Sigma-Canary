import * as fs from 'node:fs/promises';
import * as path from 'node:path';
import type {
  AuditContext,
  AuditFinding,
  HardeningModule,
  HardeningResult,
  HardeningAction,
  DockerComposeConfig,
} from '../types.js';

const HARDENED_SERVICE_CONFIG = {
  read_only: true,
  cap_drop: ['ALL'],
  security_opt: ['no-new-privileges:true'],
  networks: ['restricted-net'],
  volumes: ['openclaw-data:/app/data'],
  deploy: {
    resources: {
      limits: {
        memory: '2G',
        cpus: '2.0',
      },
    },
  },
};

const HARDENED_NETWORK_CONFIG = {
  'restricted-net': {
    driver: 'bridge',
    internal: false,
  },
};

export const dockerHardening: HardeningModule = {
  name: 'docker-hardening',
  priority: 4,

  async check(ctx: AuditContext): Promise<AuditFinding[]> {
    const findings: AuditFinding[] = [];
    const dc = ctx.dockerCompose;

    if (!dc?.services) {
      findings.push({
        id: 'SC-DOCKER-INFO',
        severity: 'INFO',
        category: 'execution',
        title: 'No Docker Compose configuration found',
        description: 'Docker hardening checks skipped — no docker-compose.yml detected.',
        evidence: 'No docker-compose configuration in context',
        remediation: 'If using Docker, provide docker-compose.yml for security analysis',
        autoFixable: false,
        references: [],
        owaspAsi: 'ASI05',
      });
      return findings;
    }

    for (const [name, svc] of Object.entries(dc.services)) {
      if (!svc.read_only) {
        findings.push({
          id: 'SC-EXEC-004',
          severity: 'MEDIUM',
          category: 'execution',
          title: `Service "${name}" not read-only`,
          description: 'Will add read_only: true.',
          evidence: `read_only not set`,
          remediation: 'Add read_only: true',
          autoFixable: true,
          references: [],
          owaspAsi: 'ASI05',
        });
      }
      if (svc.network_mode === 'host') {
        findings.push({
          id: 'SC-EXEC-007',
          severity: 'HIGH',
          category: 'execution',
          title: `Service "${name}" uses host network`,
          description: 'Will switch to bridge network.',
          evidence: 'network_mode = "host"',
          remediation: 'Remove host network mode',
          autoFixable: true,
          references: [],
          owaspAsi: 'ASI05',
        });
      }
    }

    return findings;
  },

  async fix(ctx: AuditContext, backupDir: string): Promise<HardeningResult> {
    const applied: HardeningAction[] = [];
    const skipped: HardeningAction[] = [];
    const errors: string[] = [];

    try {
      const overridePath = path.join(ctx.stateDir, 'docker-compose.secureclaw.yml');

      // Backup existing override if present
      try {
        await fs.copyFile(overridePath, path.join(backupDir, 'docker-compose.secureclaw.yml'));
      } catch {
        // No existing override
      }

      const overrideConfig: DockerComposeConfig = {
        services: {
          'openclaw-gateway': {
            read_only: HARDENED_SERVICE_CONFIG.read_only,
            cap_drop: [...HARDENED_SERVICE_CONFIG.cap_drop],
            security_opt: [...HARDENED_SERVICE_CONFIG.security_opt],
            networks: [...HARDENED_SERVICE_CONFIG.networks],
            volumes: [...HARDENED_SERVICE_CONFIG.volumes],
            deploy: {
              resources: {
                limits: {
                  memory: HARDENED_SERVICE_CONFIG.deploy.resources.limits.memory,
                  cpus: HARDENED_SERVICE_CONFIG.deploy.resources.limits.cpus,
                },
              },
            },
          },
        },
        networks: { ...HARDENED_NETWORK_CONFIG },
      };

      // Write as YAML-like JSON (user should convert to YAML for Docker)
      await fs.writeFile(
        overridePath,
        JSON.stringify(overrideConfig, null, 2),
        'utf-8'
      );

      applied.push({
        id: 'docker-override',
        description: 'Generated hardened docker-compose override',
        before: 'no override',
        after: 'docker-compose.secureclaw.yml with read-only, cap-drop=ALL, no-new-privileges',
      });
    } catch (err) {
      errors.push(`Docker hardening error: ${err instanceof Error ? err.message : String(err)}`);
    }

    return { module: 'docker-hardening', applied, skipped, errors };
  },

  async rollback(backupDir: string): Promise<void> {
    // Rollback is handled by the orchestrator
  },
};
