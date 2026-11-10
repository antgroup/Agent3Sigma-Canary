/**
 * Common utilities for Prometheus API client
 * Supports multiple instances via config file
 */

import { readFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
let configCache = null;
let envLoaded = false;

/**
 * Get OpenClaw workspace directory
 * @returns {string} Path to workspace
 */
function getWorkspaceDir() {
  // Try to find workspace by walking up from current file
  let dir = __dirname;
  while (dir !== '/') {
    if (existsSync(join(dir, 'AGENTS.md')) || existsSync(join(dir, 'SOUL.md'))) {
      return dir;
    }
    dir = dirname(dir);
  }
  // Fallback to standard location
  return process.env.OPENCLAW_WORKSPACE || join(process.env.HOME || '', '.openclaw', 'workspace');
}

/**
 * Load environment variables from .env file
 */
function loadEnvFile() {
  if (envLoaded) return;
  
  const workspaceDir = getWorkspaceDir();
  const envPaths = [
    join(workspaceDir, '.env'),
    join(process.cwd(), '.env'),
  ];
  
  for (const envPath of envPaths) {
    if (existsSync(envPath)) {
      try {
        const content = readFileSync(envPath, 'utf8');
        const lines = content.split('\n');
        
        for (const line of lines) {
          const trimmed = line.trim();
          // Skip comments and empty lines
          if (!trimmed || trimmed.startsWith('#')) continue;
          
          const match = trimmed.match(/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/);
          if (match) {
            const [, key, value] = match;
            // Only set if not already in env
            if (!process.env[key]) {
              // Remove quotes if present
              const cleanValue = value.replace(/^["']|["']$/g, '');
              process.env[key] = cleanValue;
            }
          }
        }
      } catch (err) {
        // Silently ignore .env read errors
      }
    }
  }
  
  envLoaded = true;
}

/**
 * Load config from file or environment
 * @returns {Object} Config object with instances array
 */
export function loadConfig() {
  if (configCache) return configCache;

  // Load .env file first for fallback
  loadEnvFile();

  const workspaceDir = getWorkspaceDir();

  // Try to load from config file (priority: workspace -> env -> local -> home)
  const configPaths = [
    process.env.PROMETHEUS_CONFIG,
    join(workspaceDir, 'prometheus.json'),
    join(workspaceDir, 'config', 'prometheus.json'),
    './prometheus.json',
    './config.json',
    join(process.env.HOME || '', '.config', 'prometheus', 'config.json'),
  ].filter(Boolean);

  for (const configPath of configPaths) {
    if (existsSync(configPath)) {
      try {
        const content = readFileSync(configPath, 'utf8');
        const parsed = JSON.parse(content);
        
        // Validate config structure
        if (!parsed.instances || !Array.isArray(parsed.instances)) {
          throw new Error(`Invalid config: "instances" array is required`);
        }
        
        if (parsed.instances.length === 0) {
          throw new Error(`No instances configured. Run: node cli.js init`);
        }
        
        configCache = parsed;
        return configCache;
      } catch (err) {
        if (err.message.includes('Run:')) throw err;
        console.error(`Warning: Failed to load config from ${configPath}: ${err.message}`);
      }
    }
  }

  // Fallback to environment variables (backward compatibility)
  const url = process.env.PROMETHEUS_URL;
  if (url) {
    configCache = {
      instances: [{
        name: 'default',
        url: url,
        user: process.env.PROMETHEUS_USER || null,
        password: process.env.PROMETHEUS_PASSWORD || null
      }],
      default: 'default'
    };
    return configCache;
  }

  throw new Error('No Prometheus configuration found. Run: node cli.js init');
}

/**
 * Get all configured instances
 * @returns {Array} Array of instance objects
 */
export function getAllInstances() {
  const config = loadConfig();
  return config.instances || [];
}

/**
 * Get a specific instance by name
 * @param {string} name - Instance name
 * @returns {Object} Instance configuration
 */
export function getInstance(name = null) {
  const config = loadConfig();
  const instances = config.instances || [];
  
  // If no name specified, use default
  const targetName = name || config.default;
  if (!targetName) {
    throw new Error('No instance specified and no default configured');
  }

  const instance = instances.find(i => i.name === targetName);
  if (!instance) {
    const available = instances.map(i => i.name).join(', ');
    throw new Error(`Instance "${targetName}" not found. Available: ${available}`);
  }

  return instance;
}

/**
 * Create authentication headers for a specific instance
 * @param {Object} instance - Instance configuration
 * @returns {Object} Headers object
 */
export function createAuthHeader(instance = null) {
  const headers = {
    'Accept': 'application/json'
  };
  
  const user = instance?.user || process.env.PROMETHEUS_USER;
  const password = instance?.password || process.env.PROMETHEUS_PASSWORD;
  
  if (user && password) {
    const auth = Buffer.from(`${user}:${password}`).toString('base64');
    headers['Authorization'] = `Basic ${auth}`;
  }
  
  return headers;
}

/**
 * Build full URL for API endpoint
 * @param {Object} instance - Instance configuration
 * @param {string} path - API path
 * @returns {string} Full URL
 */
export function buildUrl(instance, path) {
  const baseUrl = instance.url.replace(/\/$/, ''); // Remove trailing slash
  return `${baseUrl}${path}`;
}

/**
 * Handle API response and parse JSON
 * @param {Response} response - Fetch response
 * @returns {Promise<any>} Parsed response data
 */
export async function handleResponse(response) {
  if (!response.ok) {
    const text = await response.text().catch(() => 'Unknown error');
    throw new Error(`HTTP ${response.status}: ${text}`);
  }
  
  const data = await response.json();
  
  if (data.status !== 'success') {
    throw new Error(`Prometheus error: ${data.error || 'Unknown error'}`);
  }
  
  return data.data;
}

/**
 * Format bytes to human readable string
 * @param {number} bytes - Bytes to format
 * @returns {string} Formatted string
 */
export function formatBytes(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

/**
 * Format seconds to human readable duration
 * @param {number} seconds - Seconds to format
 * @returns {string} Formatted string
 */
export function formatDuration(seconds) {
  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  const mins = Math.floor((seconds % 3600) / 60);
  
  if (days > 0) return `${days}d ${hours}h`;
  if (hours > 0) return `${hours}h ${mins}m`;
  return `${mins}m`;
}
