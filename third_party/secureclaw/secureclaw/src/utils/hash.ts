import * as crypto from 'node:crypto';
import * as fs from 'node:fs/promises';
import * as path from 'node:path';
import type { HashBaseline, BaselineComparison } from '../types.js';

/**
 * Compute SHA-256 hash of a file.
 */
export async function hashFile(filePath: string): Promise<string> {
  const content = await fs.readFile(filePath);
  return crypto.createHash('sha256').update(content).digest('hex');
}

/**
 * Compute SHA-256 hash of a string.
 */
export function hashString(content: string): string {
  return crypto.createHash('sha256').update(content, 'utf-8').digest('hex');
}

/**
 * Hash all files in a directory recursively, returning a map of relative path → hash.
 */
export async function hashDirectory(dirPath: string): Promise<Record<string, string>> {
  const hashes: Record<string, string> = {};

  async function walk(dir: string): Promise<void> {
    let entries: string[];
    try {
      entries = await fs.readdir(dir);
    } catch {
      return;
    }

    for (const entry of entries) {
      const fullPath = path.join(dir, entry);
      let stat;
      try {
        stat = await fs.stat(fullPath);
      } catch {
        continue;
      }

      if (stat.isDirectory()) {
        await walk(fullPath);
      } else if (stat.isFile()) {
        const relativePath = path.relative(dirPath, fullPath);
        try {
          hashes[relativePath] = await hashFile(fullPath);
        } catch {
          // Skip files we can't read
        }
      }
    }
  }

  await walk(dirPath);
  return hashes;
}

/**
 * Create a hash baseline for a directory.
 */
export async function createBaseline(dirPath: string): Promise<HashBaseline> {
  const files = await hashDirectory(dirPath);
  return {
    timestamp: new Date().toISOString(),
    files,
  };
}

/**
 * Compare current directory state against a stored baseline.
 * Returns lists of added, modified, and removed files.
 */
export function compareBaseline(
  baseline: HashBaseline,
  current: Record<string, string>
): BaselineComparison {
  const added: string[] = [];
  const modified: string[] = [];
  const removed: string[] = [];

  // Check for modified and removed files
  for (const [filePath, hash] of Object.entries(baseline.files)) {
    if (!(filePath in current)) {
      removed.push(filePath);
    } else if (current[filePath] !== hash) {
      modified.push(filePath);
    }
  }

  // Check for added files
  for (const filePath of Object.keys(current)) {
    if (!(filePath in baseline.files)) {
      added.push(filePath);
    }
  }

  return { added, modified, removed };
}

/**
 * Save a baseline to a JSON file.
 */
export async function saveBaseline(baseline: HashBaseline, filePath: string): Promise<void> {
  const dir = path.dirname(filePath);
  await fs.mkdir(dir, { recursive: true });
  await fs.writeFile(filePath, JSON.stringify(baseline, null, 2), 'utf-8');
}

/**
 * Load a baseline from a JSON file.
 */
export async function loadBaseline(filePath: string): Promise<HashBaseline | null> {
  try {
    const content = await fs.readFile(filePath, 'utf-8');
    return JSON.parse(content) as HashBaseline;
  } catch {
    return null;
  }
}
