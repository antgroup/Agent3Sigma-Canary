import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import * as fs from 'node:fs/promises';
import * as path from 'node:path';
import * as os from 'node:os';
import { hashFile, hashString, hashDirectory, createBaseline, compareBaseline } from './hash.js';

describe('hash', () => {
  let tmpDir: string;

  beforeEach(async () => {
    tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'sc-hash-test-'));
  });

  afterEach(async () => {
    await fs.rm(tmpDir, { recursive: true, force: true });
  });

  describe('hashString', () => {
    it('produces consistent SHA-256 hashes', () => {
      const hash1 = hashString('hello');
      const hash2 = hashString('hello');
      expect(hash1).toBe(hash2);
    });

    it('produces different hashes for different input', () => {
      const hash1 = hashString('hello');
      const hash2 = hashString('world');
      expect(hash1).not.toBe(hash2);
    });

    it('produces 64-char hex string', () => {
      const hash = hashString('test');
      expect(hash.length).toBe(64);
      expect(/^[0-9a-f]{64}$/.test(hash)).toBe(true);
    });
  });

  describe('hashFile', () => {
    it('hashes a file correctly', async () => {
      const filePath = path.join(tmpDir, 'test.txt');
      await fs.writeFile(filePath, 'file content', 'utf-8');
      const hash = await hashFile(filePath);
      expect(hash.length).toBe(64);
      expect(hash).toBe(hashString('file content'));
    });
  });

  describe('hashDirectory', () => {
    it('hashes all files in a directory', async () => {
      await fs.writeFile(path.join(tmpDir, 'a.txt'), 'aaa', 'utf-8');
      await fs.writeFile(path.join(tmpDir, 'b.txt'), 'bbb', 'utf-8');
      const hashes = await hashDirectory(tmpDir);
      expect(Object.keys(hashes)).toHaveLength(2);
      expect(hashes['a.txt']).toBeDefined();
      expect(hashes['b.txt']).toBeDefined();
    });

    it('handles nested directories', async () => {
      await fs.mkdir(path.join(tmpDir, 'sub'), { recursive: true });
      await fs.writeFile(path.join(tmpDir, 'sub', 'c.txt'), 'ccc', 'utf-8');
      const hashes = await hashDirectory(tmpDir);
      expect(hashes[path.join('sub', 'c.txt')]).toBeDefined();
    });

    it('returns empty for empty directory', async () => {
      const emptyDir = path.join(tmpDir, 'empty');
      await fs.mkdir(emptyDir);
      const hashes = await hashDirectory(emptyDir);
      expect(Object.keys(hashes)).toHaveLength(0);
    });
  });

  describe('compareBaseline', () => {
    it('detects added files', () => {
      const baseline = { timestamp: '', files: { 'a.txt': 'hash-a' } };
      const current = { 'a.txt': 'hash-a', 'b.txt': 'hash-b' };
      const result = compareBaseline(baseline, current);
      expect(result.added).toEqual(['b.txt']);
      expect(result.modified).toEqual([]);
      expect(result.removed).toEqual([]);
    });

    it('detects modified files', () => {
      const baseline = { timestamp: '', files: { 'a.txt': 'hash-a' } };
      const current = { 'a.txt': 'hash-a-modified' };
      const result = compareBaseline(baseline, current);
      expect(result.added).toEqual([]);
      expect(result.modified).toEqual(['a.txt']);
      expect(result.removed).toEqual([]);
    });

    it('detects removed files', () => {
      const baseline = { timestamp: '', files: { 'a.txt': 'hash-a', 'b.txt': 'hash-b' } };
      const current = { 'a.txt': 'hash-a' };
      const result = compareBaseline(baseline, current);
      expect(result.added).toEqual([]);
      expect(result.modified).toEqual([]);
      expect(result.removed).toEqual(['b.txt']);
    });

    it('detects combination of add/modify/remove', () => {
      const baseline = { timestamp: '', files: { 'a.txt': 'hash-a', 'b.txt': 'hash-b' } };
      const current = { 'a.txt': 'hash-a-modified', 'c.txt': 'hash-c' };
      const result = compareBaseline(baseline, current);
      expect(result.added).toEqual(['c.txt']);
      expect(result.modified).toEqual(['a.txt']);
      expect(result.removed).toEqual(['b.txt']);
    });

    it('returns empty for identical baseline', () => {
      const baseline = { timestamp: '', files: { 'a.txt': 'hash-a' } };
      const current = { 'a.txt': 'hash-a' };
      const result = compareBaseline(baseline, current);
      expect(result.added).toEqual([]);
      expect(result.modified).toEqual([]);
      expect(result.removed).toEqual([]);
    });
  });
});
