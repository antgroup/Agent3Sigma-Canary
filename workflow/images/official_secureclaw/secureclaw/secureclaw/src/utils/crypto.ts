import * as crypto from 'node:crypto';
import * as fs from 'node:fs/promises';
import * as path from 'node:path';
import * as os from 'node:os';

const ALGORITHM = 'aes-256-gcm';
const KEY_LENGTH = 32;
const IV_LENGTH = 16;
const AUTH_TAG_LENGTH = 16;
const SALT_LENGTH = 32;
const PBKDF2_ITERATIONS = 100000;

/**
 * Get a machine-specific identifier for key derivation.
 * Tries /etc/machine-id (Linux), IOPlatformUUID (macOS), or falls back to hostname.
 */
export async function getMachineId(): Promise<string> {
  const platform = os.platform();

  if (platform === 'linux') {
    try {
      const machineId = await fs.readFile('/etc/machine-id', 'utf-8');
      return machineId.trim();
    } catch {
      // fall through
    }
  }

  if (platform === 'darwin') {
    try {
      const { execSync } = await import('node:child_process');
      const result = execSync(
        'ioreg -rd1 -c IOPlatformExpertDevice | grep IOPlatformUUID',
        { encoding: 'utf-8' }
      );
      const match = result.match(/"IOPlatformUUID"\s*=\s*"([^"]+)"/);
      if (match) {
        return match[1];
      }
    } catch {
      // fall through
    }
  }

  // Fallback to hostname
  return os.hostname();
}

/**
 * Derive a machine-local encryption key from machine ID and state directory path.
 */
export function deriveKey(machineId: string, stateDir: string, salt: Buffer): Buffer {
  const material = `${machineId}:${stateDir}`;
  return crypto.pbkdf2Sync(material, salt, PBKDF2_ITERATIONS, KEY_LENGTH, 'sha512');
}

/**
 * Encrypt data using AES-256-GCM.
 * Returns a buffer containing: salt (32) + iv (16) + authTag (16) + ciphertext
 */
export function encrypt(plaintext: string, machineId: string, stateDir: string): Buffer {
  const salt = crypto.randomBytes(SALT_LENGTH);
  const key = deriveKey(machineId, stateDir, salt);
  const iv = crypto.randomBytes(IV_LENGTH);

  const cipher = crypto.createCipheriv(ALGORITHM, key, iv, {
    authTagLength: AUTH_TAG_LENGTH,
  });

  const encrypted = Buffer.concat([
    cipher.update(plaintext, 'utf-8'),
    cipher.final(),
  ]);

  const authTag = cipher.getAuthTag();

  // Format: salt + iv + authTag + ciphertext
  return Buffer.concat([salt, iv, authTag, encrypted]);
}

/**
 * Decrypt data encrypted with encrypt().
 * Throws if data has been tampered with (GCM auth tag verification fails).
 */
export function decrypt(data: Buffer, machineId: string, stateDir: string): string {
  if (data.length < SALT_LENGTH + IV_LENGTH + AUTH_TAG_LENGTH) {
    throw new Error('Invalid encrypted data: too short');
  }

  const salt = data.subarray(0, SALT_LENGTH);
  const iv = data.subarray(SALT_LENGTH, SALT_LENGTH + IV_LENGTH);
  const authTag = data.subarray(SALT_LENGTH + IV_LENGTH, SALT_LENGTH + IV_LENGTH + AUTH_TAG_LENGTH);
  const ciphertext = data.subarray(SALT_LENGTH + IV_LENGTH + AUTH_TAG_LENGTH);

  const key = deriveKey(machineId, stateDir, salt);

  const decipher = crypto.createDecipheriv(ALGORITHM, key, iv, {
    authTagLength: AUTH_TAG_LENGTH,
  });
  decipher.setAuthTag(authTag);

  const decrypted = Buffer.concat([
    decipher.update(ciphertext),
    decipher.final(),
  ]);

  return decrypted.toString('utf-8');
}

/**
 * Ensure the keystore directory exists and write or read the key material.
 */
export async function ensureKeystore(stateDir: string): Promise<{ machineId: string; keystorePath: string }> {
  const secureclawDir = path.join(stateDir, '.secureclaw');
  const keystorePath = path.join(secureclawDir, 'keystore');

  try {
    await fs.mkdir(secureclawDir, { recursive: true, mode: 0o700 });
  } catch {
    // directory may already exist
  }

  const machineId = await getMachineId();

  try {
    await fs.access(keystorePath);
  } catch {
    // Keystore doesn't exist; create it with a verification token
    const verificationToken = encrypt('secureclaw-keystore-verify', machineId, stateDir);
    await fs.writeFile(keystorePath, verificationToken, { mode: 0o400 });
  }

  return { machineId, keystorePath };
}

/**
 * Encrypt a file in place, creating a backup first.
 */
export async function encryptFile(
  filePath: string,
  machineId: string,
  stateDir: string,
  backupDir: string
): Promise<void> {
  const content = await fs.readFile(filePath, 'utf-8');
  const backupPath = path.join(backupDir, path.basename(filePath));
  await fs.copyFile(filePath, backupPath);
  const encrypted = encrypt(content, machineId, stateDir);
  await fs.writeFile(filePath + '.enc', encrypted, { mode: 0o600 });
}

/**
 * Decrypt a .enc file and return its content.
 */
export async function decryptFile(
  filePath: string,
  machineId: string,
  stateDir: string
): Promise<string> {
  const encPath = filePath.endsWith('.enc') ? filePath : filePath + '.enc';
  const data = await fs.readFile(encPath);
  return decrypt(data, machineId, stateDir);
}

/**
 * Generate a cryptographically strong random token.
 */
export function generateToken(length: number = 32): string {
  return crypto.randomBytes(length).toString('hex');
}
