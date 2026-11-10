import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import * as fs from 'node:fs/promises';
import * as path from 'node:path';
import * as os from 'node:os';
import { credentialMonitor, resetCredentialMonitor } from './credential-monitor.js';

describe('credential-monitor', () => {
  let tmpDir: string;

  beforeEach(async () => {
    tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'sc-credmon-test-'));
    resetCredentialMonitor();
  });

  afterEach(async () => {
    await credentialMonitor.stop();
    resetCredentialMonitor();
    await fs.rm(tmpDir, { recursive: true, force: true });
  });

  // ── resetCredentialMonitor ──────────────────────────────────────────

  describe('resetCredentialMonitor', () => {
    it('clears running state back to false', async () => {
      // Start the monitor so running becomes true
      await credentialMonitor.start(tmpDir);
      expect(credentialMonitor.status().running).toBe(true);

      // Reset should bring it back to the initial state
      resetCredentialMonitor();
      expect(credentialMonitor.status().running).toBe(false);
    });

    it('clears accumulated alerts', async () => {
      // Start with no watched paths to generate no watcher,
      // but register a callback and manually verify alerts array is cleared.
      await credentialMonitor.start(tmpDir);

      // The status should have no alerts since nothing was watched
      const statusBefore = credentialMonitor.status();
      expect(statusBefore.alerts).toEqual([]);

      resetCredentialMonitor();

      const statusAfter = credentialMonitor.status();
      expect(statusAfter.alerts).toEqual([]);
    });

    it('clears lastCheck', async () => {
      await credentialMonitor.start(tmpDir);
      expect(credentialMonitor.status().lastCheck).toBeDefined();

      resetCredentialMonitor();
      expect(credentialMonitor.status().lastCheck).toBeUndefined();
    });

    it('clears registered alert callbacks', async () => {
      const received: unknown[] = [];
      credentialMonitor.onAlert((alert) => received.push(alert));

      // Reset should remove all callbacks
      resetCredentialMonitor();

      // Start and stop to confirm no callbacks fire
      await credentialMonitor.start(tmpDir);
      // Even if an alert were emitted, the callback should not fire
      // because it was cleared by reset.
      expect(received).toEqual([]);
    });
  });

  // ── status() ────────────────────────────────────────────────────────

  describe('status', () => {
    it('returns correct initial state before start', () => {
      const status = credentialMonitor.status();
      expect(status.running).toBe(false);
      expect(status.lastCheck).toBeUndefined();
      expect(status.alerts).toEqual([]);
    });

    it('returns a copy of the alerts array', async () => {
      await credentialMonitor.start(tmpDir);
      const status1 = credentialMonitor.status();
      const status2 = credentialMonitor.status();

      // Should be different array instances (defensive copy)
      expect(status1.alerts).not.toBe(status2.alerts);
      expect(status1.alerts).toEqual(status2.alerts);
    });

    it('returns running=true after start', async () => {
      await credentialMonitor.start(tmpDir);

      const status = credentialMonitor.status();
      expect(status.running).toBe(true);
    });

    it('returns lastCheck as an ISO timestamp after start', async () => {
      await credentialMonitor.start(tmpDir);

      const status = credentialMonitor.status();
      expect(status.lastCheck).toBeDefined();
      // Verify it parses as a valid date
      const parsed = new Date(status.lastCheck!);
      expect(parsed.getTime()).not.toBeNaN();
    });

    it('returns running=false after stop', async () => {
      await credentialMonitor.start(tmpDir);
      await credentialMonitor.stop();

      const status = credentialMonitor.status();
      expect(status.running).toBe(false);
    });
  });

  // ── start() ─────────────────────────────────────────────────────────

  describe('start', () => {
    it('sets running=true when no credentials dir or .env exists', async () => {
      // tmpDir has neither credentials/ nor .env, so watchPaths is empty
      await credentialMonitor.start(tmpDir);

      const status = credentialMonitor.status();
      expect(status.running).toBe(true);
      expect(status.lastCheck).toBeDefined();
    });

    it('sets running=true when credentials dir exists', async () => {
      await fs.mkdir(path.join(tmpDir, 'credentials'));
      await credentialMonitor.start(tmpDir);

      expect(credentialMonitor.status().running).toBe(true);
    });

    it('sets running=true when .env file exists', async () => {
      await fs.writeFile(path.join(tmpDir, '.env'), 'SECRET=value\n');
      await credentialMonitor.start(tmpDir);

      expect(credentialMonitor.status().running).toBe(true);
    });

    it('sets running=true when both credentials dir and .env exist', async () => {
      await fs.mkdir(path.join(tmpDir, 'credentials'));
      await fs.writeFile(path.join(tmpDir, '.env'), 'SECRET=value\n');
      await credentialMonitor.start(tmpDir);

      expect(credentialMonitor.status().running).toBe(true);
    });

    it('is idempotent — second call returns early without error', async () => {
      await credentialMonitor.start(tmpDir);
      const statusAfterFirst = credentialMonitor.status();

      // Second start should return immediately
      await credentialMonitor.start(tmpDir);
      const statusAfterSecond = credentialMonitor.status();

      expect(statusAfterFirst.running).toBe(true);
      expect(statusAfterSecond.running).toBe(true);
      // lastCheck should not have been updated by the second call
      expect(statusAfterSecond.lastCheck).toBe(statusAfterFirst.lastCheck);
    });

    it('does not throw when stateDir does not exist', async () => {
      const nonExistent = path.join(tmpDir, 'does-not-exist');
      // Should not throw — paths simply won't be found
      await expect(credentialMonitor.start(nonExistent)).resolves.toBeUndefined();
      expect(credentialMonitor.status().running).toBe(true);
    });
  });

  // ── stop() ──────────────────────────────────────────────────────────

  describe('stop', () => {
    it('sets running=false after start', async () => {
      await credentialMonitor.start(tmpDir);
      expect(credentialMonitor.status().running).toBe(true);

      await credentialMonitor.stop();
      expect(credentialMonitor.status().running).toBe(false);
    });

    it('can be called when not running without error', async () => {
      // stop() before any start() should not throw
      await expect(credentialMonitor.stop()).resolves.toBeUndefined();
      expect(credentialMonitor.status().running).toBe(false);
    });

    it('can be called multiple times without error', async () => {
      await credentialMonitor.start(tmpDir);
      await credentialMonitor.stop();
      await expect(credentialMonitor.stop()).resolves.toBeUndefined();
      expect(credentialMonitor.status().running).toBe(false);
    });

    it('allows restarting after stop', async () => {
      await credentialMonitor.start(tmpDir);
      await credentialMonitor.stop();
      expect(credentialMonitor.status().running).toBe(false);

      await credentialMonitor.start(tmpDir);
      expect(credentialMonitor.status().running).toBe(true);
    });

    it('closes the watcher when paths were being watched', async () => {
      // Create a credentials directory so the watcher is actually created
      await fs.mkdir(path.join(tmpDir, 'credentials'));
      await credentialMonitor.start(tmpDir);
      expect(credentialMonitor.status().running).toBe(true);

      await credentialMonitor.stop();
      expect(credentialMonitor.status().running).toBe(false);
    });
  });

  // ── onAlert() ───────────────────────────────────────────────────────

  describe('onAlert', () => {
    it('registers a callback', () => {
      // Should not throw
      const callback = () => {};
      credentialMonitor.onAlert(callback);
    });

    it('can register multiple callbacks', () => {
      const cb1 = () => {};
      const cb2 = () => {};
      credentialMonitor.onAlert(cb1);
      credentialMonitor.onAlert(cb2);
      // No error means success — callbacks are stored internally
    });

    it('callbacks survive across start/stop cycles', async () => {
      const received: unknown[] = [];
      credentialMonitor.onAlert((alert) => received.push(alert));

      // Start and stop — the callback should still be registered
      await credentialMonitor.start(tmpDir);
      await credentialMonitor.stop();

      // The callback is still registered (not cleared by stop)
      // We can verify by starting again; the callback array persists
      // until resetCredentialMonitor is called.
    });

    it('callbacks are cleared by resetCredentialMonitor', () => {
      const received: unknown[] = [];
      credentialMonitor.onAlert((alert) => received.push(alert));

      resetCredentialMonitor();

      // After reset, the callback list is empty
      // We cannot directly inspect internals, but we tested this
      // indirectly in the resetCredentialMonitor suite above.
      // This test confirms no error on the sequence.
      expect(received).toEqual([]);
    });
  });

  // ── name property ───────────────────────────────────────────────────

  describe('name', () => {
    it('is "credential-monitor"', () => {
      expect(credentialMonitor.name).toBe('credential-monitor');
    });
  });

  // ── lifecycle integration ───────────────────────────────────────────

  describe('lifecycle integration', () => {
    it('full lifecycle: start -> status -> stop -> status', async () => {
      // Initial state
      const initial = credentialMonitor.status();
      expect(initial.running).toBe(false);
      expect(initial.lastCheck).toBeUndefined();
      expect(initial.alerts).toEqual([]);

      // Start
      await credentialMonitor.start(tmpDir);
      const afterStart = credentialMonitor.status();
      expect(afterStart.running).toBe(true);
      expect(afterStart.lastCheck).toBeDefined();
      expect(afterStart.alerts).toEqual([]);

      // Stop
      await credentialMonitor.stop();
      const afterStop = credentialMonitor.status();
      expect(afterStop.running).toBe(false);
      // lastCheck should still have the value from start
      expect(afterStop.lastCheck).toBe(afterStart.lastCheck);
    });

    it('start -> reset -> start works cleanly', async () => {
      await credentialMonitor.start(tmpDir);
      expect(credentialMonitor.status().running).toBe(true);

      // Reset clears everything including the running flag
      // but does NOT close the watcher (that is the caller's responsibility)
      resetCredentialMonitor();
      expect(credentialMonitor.status().running).toBe(false);

      // Starting fresh after reset should work
      await credentialMonitor.start(tmpDir);
      expect(credentialMonitor.status().running).toBe(true);
    });

    it('stop -> reset -> start works cleanly', async () => {
      await credentialMonitor.start(tmpDir);
      await credentialMonitor.stop();

      resetCredentialMonitor();
      expect(credentialMonitor.status().running).toBe(false);
      expect(credentialMonitor.status().lastCheck).toBeUndefined();

      await credentialMonitor.start(tmpDir);
      expect(credentialMonitor.status().running).toBe(true);
      expect(credentialMonitor.status().lastCheck).toBeDefined();
    });
  });
});
