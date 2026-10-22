import { describe, it, expect } from 'vitest';
import { deriveKey, encrypt, decrypt, generateToken } from './crypto.js';

describe('crypto', () => {
  const machineId = 'test-machine-id';
  const stateDir = '/tmp/test-state';

  describe('deriveKey', () => {
    it('produces deterministic output for same inputs', () => {
      const salt = Buffer.from('a'.repeat(64), 'hex');
      const key1 = deriveKey(machineId, stateDir, salt);
      const key2 = deriveKey(machineId, stateDir, salt);
      expect(key1.equals(key2)).toBe(true);
    });

    it('produces different output for different machine IDs', () => {
      const salt = Buffer.from('b'.repeat(64), 'hex');
      const key1 = deriveKey('machine-1', stateDir, salt);
      const key2 = deriveKey('machine-2', stateDir, salt);
      expect(key1.equals(key2)).toBe(false);
    });

    it('produces 32-byte keys', () => {
      const salt = Buffer.from('c'.repeat(64), 'hex');
      const key = deriveKey(machineId, stateDir, salt);
      expect(key.length).toBe(32);
    });
  });

  describe('encrypt/decrypt', () => {
    it('roundtrip works for simple string', () => {
      const plaintext = 'Hello, SecureClaw!';
      const encrypted = encrypt(plaintext, machineId, stateDir);
      const decrypted = decrypt(encrypted, machineId, stateDir);
      expect(decrypted).toBe(plaintext);
    });

    it('roundtrip works for empty string', () => {
      const plaintext = '';
      const encrypted = encrypt(plaintext, machineId, stateDir);
      const decrypted = decrypt(encrypted, machineId, stateDir);
      expect(decrypted).toBe(plaintext);
    });

    it('roundtrip works for JSON content', () => {
      const plaintext = JSON.stringify({ apiKey: 'test-key-12345', value: 'my-value' });
      const encrypted = encrypt(plaintext, machineId, stateDir);
      const decrypted = decrypt(encrypted, machineId, stateDir);
      expect(decrypted).toBe(plaintext);
    });

    it('produces different ciphertext for same plaintext (random IV)', () => {
      const plaintext = 'same text';
      const e1 = encrypt(plaintext, machineId, stateDir);
      const e2 = encrypt(plaintext, machineId, stateDir);
      expect(e1.equals(e2)).toBe(false);
    });

    it('fails to decrypt with wrong machine ID', () => {
      const plaintext = 'secret data';
      const encrypted = encrypt(plaintext, machineId, stateDir);
      expect(() => decrypt(encrypted, 'wrong-machine', stateDir)).toThrow();
    });

    it('detects tampered ciphertext', () => {
      const plaintext = 'important data';
      const encrypted = encrypt(plaintext, machineId, stateDir);
      // Tamper with a byte in the ciphertext area
      encrypted[encrypted.length - 5] ^= 0xff;
      expect(() => decrypt(encrypted, machineId, stateDir)).toThrow();
    });

    it('rejects too-short data', () => {
      const shortData = Buffer.from('too short');
      expect(() => decrypt(shortData, machineId, stateDir)).toThrow('too short');
    });
  });

  describe('generateToken', () => {
    it('generates hex token of correct length', () => {
      const token = generateToken(32);
      expect(token.length).toBe(64); // 32 bytes = 64 hex chars
    });

    it('generates unique tokens', () => {
      const t1 = generateToken();
      const t2 = generateToken();
      expect(t1).not.toBe(t2);
    });
  });
});
