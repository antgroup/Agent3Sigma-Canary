import * as fs from 'node:fs/promises';
import * as path from 'node:path';
import { hashString } from '../utils/hash.js';
import { isKnownMaliciousHash, matchesTyposquat, loadIOCDatabase } from '../utils/ioc-db.js';
import type { SkillScanResult, IOCDatabase } from '../types.js';

/**
 * All dangerous patterns to scan for in skill files.
 */
const DANGEROUS_PATTERNS: Array<{ pattern: RegExp; description: string; severity: 'critical' | 'high' | 'medium' }> = [
  { pattern: /child_process/, description: 'child_process import', severity: 'critical' },
  { pattern: /\.exec\s*\(/, description: 'exec() call', severity: 'critical' },
  { pattern: /\.spawn\s*\(/, description: 'spawn() call', severity: 'critical' },
  { pattern: /eval\s*\(/, description: 'eval() call', severity: 'critical' },
  { pattern: /Function\s*\(/, description: 'Function() constructor', severity: 'critical' },
  { pattern: /webhook\.site/, description: 'webhook.site exfiltration', severity: 'critical' },
  { pattern: /reverse.shell/, description: 'reverse shell pattern', severity: 'critical' },
  { pattern: /base64.*decode/i, description: 'base64 decode (obfuscation)', severity: 'high' },
  { pattern: /curl\s+.*\|\s*sh/, description: 'curl pipe to shell', severity: 'critical' },
  { pattern: /wget\s+.*\|\s*sh/, description: 'wget pipe to shell', severity: 'critical' },
  { pattern: /~\/\.openclaw/, description: 'openclaw config access', severity: 'high' },
  { pattern: /~\/\.clawdbot/, description: 'legacy clawdbot config access', severity: 'high' },
  { pattern: /creds\.json/, description: 'credential file access', severity: 'high' },
  { pattern: /\.env/, description: '.env file access', severity: 'medium' },
  { pattern: /auth-profiles/, description: 'auth-profiles access', severity: 'high' },
  { pattern: /LD_PRELOAD/, description: 'LD_PRELOAD injection', severity: 'critical' },
  { pattern: /DYLD_INSERT/, description: 'DYLD_INSERT injection', severity: 'critical' },
  { pattern: /NODE_OPTIONS/, description: 'NODE_OPTIONS injection', severity: 'high' },
];

/**
 * Scan a single file's content for dangerous patterns.
 */
export function scanContent(content: string): Array<{ pattern: string; description: string; severity: string }> {
  const matches: Array<{ pattern: string; description: string; severity: string }> = [];

  for (const { pattern, description, severity } of DANGEROUS_PATTERNS) {
    if (pattern.test(content)) {
      matches.push({
        pattern: pattern.source,
        description,
        severity,
      });
    }
  }

  return matches;
}

/**
 * Scan a skill directory for malicious patterns.
 * This is the main entry point for skill scanning.
 */
export async function scanSkill(skillDir: string, skillName: string): Promise<SkillScanResult> {
  const findings: string[] = [];
  const dangerousPatterns: string[] = [];
  const iocMatches: string[] = [];
  let safe = true;

  let db: IOCDatabase;
  try {
    db = await loadIOCDatabase();
  } catch {
    // If no IOC database, create a minimal one
    db = {
      version: '0',
      last_updated: '',
      c2_ips: [],
      malicious_domains: [],
      malicious_skill_hashes: {},
      typosquat_patterns: [],
      dangerous_prerequisite_patterns: [],
      infostealer_artifacts: { macos: [], linux: [] },
    };
  }

  // Check for typosquat
  if (matchesTyposquat(db, skillName)) {
    findings.push(`Skill name "${skillName}" matches known typosquat pattern`);
    iocMatches.push(`typosquat:${skillName}`);
    safe = false;
  }

  // Scan all files in the skill directory
  let files: string[];
  try {
    files = await fs.readdir(skillDir);
  } catch {
    findings.push(`Could not read skill directory: ${skillDir}`);
    return { safe: true, skillName, findings, dangerousPatterns, iocMatches };
  }

  for (const file of files) {
    const filePath = path.join(skillDir, file);

    let stat;
    try {
      stat = await fs.stat(filePath);
    } catch {
      continue;
    }

    if (!stat.isFile()) continue;

    let content: string;
    try {
      content = await fs.readFile(filePath, 'utf-8');
    } catch {
      continue;
    }

    // Check for dangerous patterns
    const matches = scanContent(content);
    for (const match of matches) {
      findings.push(`${file}: ${match.description} (${match.severity})`);
      dangerousPatterns.push(match.pattern);
      if (match.severity === 'critical') {
        safe = false;
      }
    }

    // Check hash against IOC database
    const fileHash = hashString(content);
    const campaign = isKnownMaliciousHash(db, fileHash);
    if (campaign) {
      findings.push(`${file}: matches known malicious hash (campaign: ${campaign})`);
      iocMatches.push(`hash:${fileHash}:${campaign}`);
      safe = false;
    }
  }

  return { safe, skillName, findings, dangerousPatterns, iocMatches };
}

/**
 * Scan a skill from its content directly (for testing without filesystem).
 */
export function scanSkillContent(
  skillName: string,
  files: Record<string, string>,
  db?: IOCDatabase
): SkillScanResult {
  const findings: string[] = [];
  const dangerousPatterns: string[] = [];
  const iocMatches: string[] = [];
  let safe = true;

  // Check typosquat
  if (db && matchesTyposquat(db, skillName)) {
    findings.push(`Skill name "${skillName}" matches known typosquat pattern`);
    iocMatches.push(`typosquat:${skillName}`);
    safe = false;
  }

  for (const [fileName, content] of Object.entries(files)) {
    const matches = scanContent(content);
    for (const match of matches) {
      findings.push(`${fileName}: ${match.description} (${match.severity})`);
      dangerousPatterns.push(match.pattern);
      if (match.severity === 'critical') {
        safe = false;
      }
    }

    if (db) {
      const fileHash = hashString(content);
      const campaign = isKnownMaliciousHash(db, fileHash);
      if (campaign) {
        findings.push(`${fileName}: matches known malicious hash (campaign: ${campaign})`);
        iocMatches.push(`hash:${fileHash}:${campaign}`);
        safe = false;
      }
    }
  }

  return { safe, skillName, findings, dangerousPatterns, iocMatches };
}
