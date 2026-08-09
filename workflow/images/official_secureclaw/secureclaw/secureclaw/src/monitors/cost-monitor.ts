import * as fs from 'node:fs/promises';
import * as path from 'node:path';
import type { Monitor, MonitorStatus, MonitorAlert, AlertCallback, CostEntry, CostReport } from '../types.js';

// Approximate cost per token (USD) for common models
const TOKEN_COSTS: Record<string, { input: number; output: number }> = {
  'claude-opus-4': { input: 0.000015, output: 0.000075 },
  'claude-sonnet-4': { input: 0.000003, output: 0.000015 },
  'claude-haiku-4': { input: 0.0000008, output: 0.000004 },
  'gpt-4': { input: 0.00003, output: 0.00006 },
  'gpt-4o': { input: 0.0000025, output: 0.00001 },
  'default': { input: 0.000003, output: 0.000015 },
};

let alertCallbacks: AlertCallback[] = [];
let alerts: MonitorAlert[] = [];
let running = false;
let lastCheck: string | undefined;
let checkInterval: ReturnType<typeof setInterval> | null = null;
let costEntries: CostEntry[] = [];

// Configurable limits
let hourlyLimitUsd = 2;
let dailyLimitUsd = 10;
let monthlyLimitUsd = 100;
let circuitBreakerEnabled = true;
let circuitBreakerTripped = false;

function emitAlert(alert: MonitorAlert): void {
  alerts.push(alert);
  for (const cb of alertCallbacks) {
    cb(alert);
  }
}

/**
 * Parse a JSONL session log and extract cost entries.
 */
export function parseSessionLog(content: string): CostEntry[] {
  const entries: CostEntry[] = [];
  const lines = content.split('\n').filter(Boolean);

  for (const line of lines) {
    try {
      const entry = JSON.parse(line);
      if (entry.inputTokens || entry.outputTokens || entry.model) {
        const model = entry.model ?? 'default';
        const inputTokens = entry.inputTokens ?? 0;
        const outputTokens = entry.outputTokens ?? 0;
        const costs = TOKEN_COSTS[model] ?? TOKEN_COSTS['default'];
        const estimatedCostUsd = (inputTokens * costs.input) + (outputTokens * costs.output);

        entries.push({
          timestamp: entry.timestamp ?? new Date().toISOString(),
          model,
          inputTokens,
          outputTokens,
          estimatedCostUsd,
        });
      }
    } catch {
      // Skip non-JSON lines
    }
  }

  return entries;
}

/**
 * Calculate cost for a time window.
 */
export function calculateCostForWindow(
  entries: CostEntry[],
  windowMs: number
): number {
  const now = Date.now();
  const cutoff = now - windowMs;
  let total = 0;

  for (const entry of entries) {
    const entryTime = new Date(entry.timestamp).getTime();
    if (entryTime >= cutoff) {
      total += entry.estimatedCostUsd;
    }
  }

  return total;
}

/**
 * Generate a cost report from accumulated entries.
 */
export function generateCostReport(entries: CostEntry[]): CostReport {
  const hourMs = 60 * 60 * 1000;
  const dayMs = 24 * hourMs;
  const monthMs = 30 * dayMs;

  const hourly = calculateCostForWindow(entries, hourMs);
  const daily = calculateCostForWindow(entries, dayMs);
  const monthly = calculateCostForWindow(entries, monthMs);

  // Simple projection based on recent hourly rate
  const projectedDaily = hourly * 24;
  const projectedMonthly = projectedDaily * 30;

  return {
    hourly,
    daily,
    monthly,
    projection: {
      daily: projectedDaily,
      monthly: projectedMonthly,
    },
    circuitBreakerTripped,
    entries,
  };
}

/**
 * Check spending limits and emit alerts.
 */
export function checkLimits(entries: CostEntry[]): void {
  const hourMs = 60 * 60 * 1000;
  const dayMs = 24 * hourMs;
  const monthMs = 30 * dayMs;

  const hourly = calculateCostForWindow(entries, hourMs);
  const daily = calculateCostForWindow(entries, dayMs);
  const monthly = calculateCostForWindow(entries, monthMs);

  if (hourly > hourlyLimitUsd) {
    emitAlert({
      timestamp: new Date().toISOString(),
      severity: 'CRITICAL',
      monitor: 'cost-monitor',
      message: `Hourly spend ($${hourly.toFixed(2)}) exceeds limit ($${hourlyLimitUsd})`,
      details: `Entries in window: ${entries.length}`,
    });

    if (circuitBreakerEnabled) {
      circuitBreakerTripped = true;
      emitAlert({
        timestamp: new Date().toISOString(),
        severity: 'CRITICAL',
        monitor: 'cost-monitor',
        message: 'Circuit breaker TRIPPED — pausing agent sessions',
        details: `Hourly spend: $${hourly.toFixed(2)}, Limit: $${hourlyLimitUsd}`,
      });
    }
  }

  if (daily > dailyLimitUsd) {
    emitAlert({
      timestamp: new Date().toISOString(),
      severity: 'HIGH',
      monitor: 'cost-monitor',
      message: `Daily spend ($${daily.toFixed(2)}) exceeds limit ($${dailyLimitUsd})`,
    });
  }

  if (monthly > monthlyLimitUsd) {
    emitAlert({
      timestamp: new Date().toISOString(),
      severity: 'HIGH',
      monitor: 'cost-monitor',
      message: `Monthly spend ($${monthly.toFixed(2)}) exceeds limit ($${monthlyLimitUsd})`,
    });
  }

  // Spike detection: current hourly > 3x average
  if (entries.length > 0) {
    const totalCost = entries.reduce((sum, e) => sum + e.estimatedCostUsd, 0);
    const avgCost = totalCost / entries.length;
    const recentEntries = entries.filter(
      (e) => Date.now() - new Date(e.timestamp).getTime() < 60 * 60 * 1000
    );
    const recentTotal = recentEntries.reduce((sum, e) => sum + e.estimatedCostUsd, 0);

    if (recentTotal > avgCost * 3 && recentTotal > 0.1) {
      emitAlert({
        timestamp: new Date().toISOString(),
        severity: 'HIGH',
        monitor: 'cost-monitor',
        message: `Unusual cost spike detected: $${recentTotal.toFixed(2)} in the last hour (3x normal)`,
      });
    }
  }
}

export const costMonitor: Monitor = {
  name: 'cost-monitor',

  async start(stateDir: string): Promise<void> {
    if (running) return;

    // Load config limits
    try {
      const configPath = path.join(stateDir, 'openclaw.json');
      const configContent = await fs.readFile(configPath, 'utf-8');
      const config = JSON.parse(configContent);
      if (config.secureclaw?.cost) {
        hourlyLimitUsd = config.secureclaw.cost.hourlyLimitUsd ?? hourlyLimitUsd;
        dailyLimitUsd = config.secureclaw.cost.dailyLimitUsd ?? dailyLimitUsd;
        monthlyLimitUsd = config.secureclaw.cost.monthlyLimitUsd ?? monthlyLimitUsd;
        circuitBreakerEnabled = config.secureclaw.cost.circuitBreakerEnabled ?? circuitBreakerEnabled;
      }
    } catch {
      // Use defaults
    }

    // Scan existing session logs for initial data
    const agentsDir = path.join(stateDir, 'agents');
    try {
      const agents = await fs.readdir(agentsDir);
      for (const agent of agents) {
        const sessionsDir = path.join(agentsDir, agent, 'sessions');
        try {
          const sessionFiles = await fs.readdir(sessionsDir);
          for (const file of sessionFiles) {
            if (!file.endsWith('.jsonl')) continue;
            try {
              const content = await fs.readFile(path.join(sessionsDir, file), 'utf-8');
              const entries = parseSessionLog(content);
              costEntries.push(...entries);
            } catch {
              // Skip unreadable files
            }
          }
        } catch {
          // No sessions directory for this agent
        }
      }
    } catch {
      // No agents directory
    }

    // Check limits on initial data
    if (costEntries.length > 0) {
      checkLimits(costEntries);
    }

    // Set up periodic checking (every 60 seconds)
    checkInterval = setInterval(() => {
      lastCheck = new Date().toISOString();
      checkLimits(costEntries);
    }, 60000);

    running = true;
    lastCheck = new Date().toISOString();
  },

  async stop(): Promise<void> {
    if (checkInterval) {
      clearInterval(checkInterval);
      checkInterval = null;
    }
    running = false;
  },

  status(): MonitorStatus {
    return {
      running,
      lastCheck,
      alerts: [...alerts],
    };
  },

  onAlert(callback: AlertCallback): void {
    alertCallbacks.push(callback);
  },
};

/**
 * Add cost entries externally (e.g., from session hooks).
 */
export function addCostEntries(entries: CostEntry[]): void {
  costEntries.push(...entries);
}

/**
 * Set spending limits programmatically.
 */
export function setLimits(limits: {
  hourly?: number;
  daily?: number;
  monthly?: number;
  circuitBreaker?: boolean;
}): void {
  if (limits.hourly !== undefined) hourlyLimitUsd = limits.hourly;
  if (limits.daily !== undefined) dailyLimitUsd = limits.daily;
  if (limits.monthly !== undefined) monthlyLimitUsd = limits.monthly;
  if (limits.circuitBreaker !== undefined) circuitBreakerEnabled = limits.circuitBreaker;
}

/**
 * Get the circuit breaker status.
 */
export function isCircuitBreakerTripped(): boolean {
  return circuitBreakerTripped;
}

/**
 * Reset the circuit breaker.
 */
export function resetCircuitBreaker(): void {
  circuitBreakerTripped = false;
}

/**
 * Reset all state (for testing).
 */
export function resetCostMonitor(): void {
  alerts = [];
  alertCallbacks = [];
  running = false;
  lastCheck = undefined;
  costEntries = [];
  circuitBreakerTripped = false;
  if (checkInterval) {
    clearInterval(checkInterval);
    checkInterval = null;
  }
}
