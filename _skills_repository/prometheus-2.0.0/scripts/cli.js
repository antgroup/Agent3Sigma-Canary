#!/usr/bin/env node

/**
 * Prometheus CLI - Query multiple Prometheus instances
 * 
 * Usage:
 *   node cli.js init                              - Interactive config setup
 *   node cli.js query '<promql>'                  - Run instant query
 *   node cli.js query '<promql>' --all            - Run query on all instances
 *   node cli.js query '<promql>' -i prod          - Run query on specific instance
 *   node cli.js range '<promql>' <start> <end>    - Run range query
 *   node cli.js instances                         - List configured instances
 * 
 * Global flags:
 *   -c, --config <path>     Path to config file
 *   -i, --instance <name>   Target specific instance
 *   -a, --all              Query all instances
 */

import { 
  instantQuery, 
  rangeQuery, 
  getLabels, 
  getLabelValues, 
  getSeries, 
  getMetadata,
  getAlerts,
  getTargets
} from './query.js';
import { loadConfig, getAllInstances } from './common.js';
import { existsSync, writeFileSync, mkdirSync } from 'fs';
import { createInterface } from 'readline';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

/**
 * Get OpenClaw workspace directory
 */
function getWorkspaceDir() {
  let dir = __dirname;
  while (dir !== '/') {
    if (existsSync(join(dir, 'AGENTS.md')) || existsSync(join(dir, 'SOUL.md'))) {
      return dir;
    }
    dir = dirname(dir);
  }
  return process.env.OPENCLAW_WORKSPACE || join(process.env.HOME || '', '.openclaw', 'workspace');
}

// Parse arguments
const args = process.argv.slice(2);
const command = args[0];

// Extract global flags
let configPath = null;
let targetInstance = null;
let queryAll = false;
const remainingArgs = [];

for (let i = 0; i < args.length; i++) {
  const arg = args[i];
  if (arg === '-c' || arg === '--config') {
    configPath = args[++i];
  } else if (arg === '-i' || arg === '--instance') {
    targetInstance = args[++i];
  } else if (arg === '-a' || arg === '--all') {
    queryAll = true;
  } else {
    remainingArgs.push(arg);
  }
}

// Set config path if provided
if (configPath) {
  process.env.PROMETHEUS_CONFIG = configPath;
}

function output(data) {
  console.log(JSON.stringify(data, null, 2));
}

function errorExit(message) {
  console.error(`Error: ${message}`);
  process.exit(1);
}

async function prompt(rl, question, defaultValue = '') {
  return new Promise((resolve) => {
    const text = defaultValue 
      ? `${question} (${defaultValue}): `
      : `${question}: `;
    rl.question(text, (answer) => {
      resolve(answer.trim() || defaultValue);
    });
  });
}

async function initConfig() {
  const workspaceDir = getWorkspaceDir();
  const defaultConfigPath = join(workspaceDir, 'prometheus.json');
  const configFile = process.env.PROMETHEUS_CONFIG || defaultConfigPath;
  
  console.log('\n🎯 Prometheus CLI Configuration\n');
  console.log(`Config will be saved to: ${configFile}\n`);
  
  const rl = createInterface({
    input: process.stdin,
    output: process.stdout
  });
  
  const instances = [];
  let addMore = true;
  
  while (addMore) {
    console.log(`\n📡 Instance #${instances.length + 1}`);
    
    const name = await prompt(rl, 'Name (e.g., prod, staging)', instances.length === 0 ? 'main' : `instance-${instances.length + 1}`);
    const url = await prompt(rl, 'URL (e.g., http://localhost:9090)');
    
    if (!url) {
      console.log('❌ URL is required, skipping this instance');
      break;
    }
    
    const auth = await prompt(rl, 'Use HTTP Basic Auth? (y/N)');
    let user = null;
    let password = null;
    
    if (auth.toLowerCase() === 'y') {
      user = await prompt(rl, 'Username');
      password = await prompt(rl, 'Password');
    }
    
    instances.push({
      name,
      url: url.replace(/\/$/, ''), // Remove trailing slash
      ...(user && { user }),
      ...(password && { password })
    });
    
    const more = await prompt(rl, 'Add another instance? (y/N)');
    addMore = more.toLowerCase() === 'y';
  }
  
  if (instances.length === 0) {
    console.log('\n❌ No instances configured. Aborting.');
    rl.close();
    process.exit(1);
  }
  
  let defaultInstance = instances[0].name;
  if (instances.length > 1) {
    const names = instances.map(i => i.name).join(', ');
    defaultInstance = await prompt(rl, `Default instance (${names})`, instances[0].name);
  }
  
  rl.close();
  
  const config = {
    instances,
    default: defaultInstance
  };
  
  try {
    // Ensure directory exists
    const configDir = dirname(configFile);
    if (!existsSync(configDir)) {
      mkdirSync(configDir, { recursive: true });
    }
    
    writeFileSync(configFile, JSON.stringify(config, null, 2));
    console.log(`\n✅ Configuration saved to ${configFile}`);
    console.log(`\nConfigured instances:`);
    instances.forEach(i => {
      const auth = i.user ? ' (with auth)' : '';
      const def = i.name === defaultInstance ? ' [default]' : '';
      console.log(`  • ${i.name}: ${i.url}${auth}${def}`);
    });
    console.log('\nYou can now run queries:\n');
    console.log('  node cli.js query \'up\'');
    console.log('  node cli.js query \'node_load1\' --all');
    console.log(`  node cli.js query \'up\' -i ${instances[0].name}`);
  } catch (err) {
    console.error(`\n❌ Failed to save config: ${err.message}`);
    process.exit(1);
  }
}

async function main() {
  try {
    switch (command) {
      case 'init': {
        await initConfig();
        break;
      }

      case 'query':
      case 'q': {
        const queryStr = remainingArgs[1];
        if (!queryStr) errorExit('Query string required');
        
        const result = await instantQuery(queryStr, {
          instance: targetInstance,
          all: queryAll
        });
        output(result);
        break;
      }

      case 'range':
      case 'r': {
        const queryStr = remainingArgs[1];
        const start = remainingArgs[2];
        const end = remainingArgs[3];
        const step = parseInt(remainingArgs[4]) || 60;
        
        if (!queryStr || !start || !end) {
          errorExit('Usage: range <query> <start> <end> [step]');
        }
        
        const result = await rangeQuery(queryStr, start, end, {
          instance: targetInstance,
          all: queryAll,
          step
        });
        output(result);
        break;
      }

      case 'labels':
      case 'l': {
        const result = await getLabels({
          instance: targetInstance,
          all: queryAll
        });
        output(result);
        break;
      }

      case 'label-values':
      case 'lv': {
        const label = remainingArgs[1];
        if (!label) errorExit('Label name required');
        
        const result = await getLabelValues(label, {
          instance: targetInstance,
          all: queryAll
        });
        output(result);
        break;
      }

      case 'series':
      case 's': {
        const match = remainingArgs[1];
        if (!match) errorExit('Series selector required (e.g., \'{__name__="up"}\')');
        
        const result = await getSeries(match, {
          instance: targetInstance,
          all: queryAll
        });
        output(result);
        break;
      }

      case 'metrics':
      case 'm': {
        const pattern = remainingArgs[1] || '';
        const result = await getMetadata(pattern, {
          instance: targetInstance,
          all: queryAll
        });
        output(result);
        break;
      }

      case 'alerts':
      case 'a': {
        const result = await getAlerts({
          instance: targetInstance,
          all: queryAll
        });
        output(result);
        break;
      }

      case 'targets':
      case 't': {
        const result = await getTargets({
          instance: targetInstance,
          all: queryAll
        });
        output(result);
        break;
      }

      case 'instances':
      case 'list': {
        const config = loadConfig();
        const instances = getAllInstances();
        output({
          default: config.default,
          instances: instances.map(i => ({
            name: i.name,
            url: i.url,
            hasAuth: !!(i.user && i.password)
          }))
        });
        break;
      }

      case 'help':
      case 'h':
      case '--help':
      case '-h':
      default: {
        const workspaceDir = getWorkspaceDir();
        const defaultConfigPath = join(workspaceDir, 'prometheus.json');
        
        console.log(`
Prometheus CLI - Query multiple Prometheus instances

Setup:
  init                     Interactive configuration wizard

Commands:
  query <promql>           Run instant query
  range <q> <start> <end>  Run range query (timestamps in RFC3339 or Unix)
  labels                   List all label names
  label-values <label>     Get values for a specific label
  series <selector>        Find time series by label matchers
  metrics [pattern]        Get metrics metadata
  alerts                   Get active alerts
  targets                  Get scrape targets
  instances                List configured instances

Global flags:
  -c, --config <path>      Path to config file
  -i, --instance <name>    Target specific instance
  -a, --all                Query all configured instances

Examples:
  # Initial setup
  node cli.js init
  
  # Query default instance
  node cli.js query 'up'
  
  # Query specific instance
  node cli.js query 'up' -i prod
  
  # Query all instances
  node cli.js query 'up' --all

Config file locations (searched in order):
  1. Path from PROMETHEUS_CONFIG env var
  2. ${defaultConfigPath}
  3. ~/.config/prometheus/config.json

Config file format (prometheus.json):
  {
    "instances": [
      { "name": "prod", "url": "http://prom-prod:9090" },
      { "name": "staging", "url": "http://prom-staging:9090", "user": "admin", "password": "secret" }
    ],
    "default": "prod"
  }
`);
        break;
      }
    }
  } catch (err) {
    const workspaceDir = getWorkspaceDir();
    const defaultConfigPath = join(workspaceDir, 'prometheus.json');
    
    if (err.message.includes('No Prometheus configuration found') || 
        err.message.includes('No instances configured')) {
      console.error(`
❌ Configuration not found!

To get started, run the setup wizard:
  node cli.js init

Or create a config file manually at:
  ${defaultConfigPath}

Example config:
  {
    "instances": [
      { "name": "main", "url": "http://localhost:9090" }
    ],
    "default": "main"
  }
`);
      process.exit(1);
    }
    errorExit(err.message);
  }
}

main();
