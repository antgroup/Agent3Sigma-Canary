---
name: prometheus
description: Query Prometheus monitoring data to check server metrics, resource usage, and system health. Use when the user asks about server status, disk space, CPU/memory usage, network stats, or any metrics collected by Prometheus. Supports multiple Prometheus instances with aggregated queries, config file or environment variables, and HTTP Basic Auth.
---

# Prometheus Skill

Query Prometheus monitoring data from one or multiple instances. Supports federation across multiple Prometheus servers with a single command.

## Quick Start

### 1. Initial Setup

Run the interactive configuration wizard:

```bash
cd ~/.openclaw/workspace/skills/prometheus
node scripts/cli.js init
```

This will create a `prometheus.json` config file in your OpenClaw workspace (`~/.openclaw/workspace/prometheus.json`).

### 2. Start Querying

```bash
# Query default instance
node scripts/cli.js query 'up'

# Query all instances at once
node scripts/cli.js query 'up' --all

# List configured instances
node scripts/cli.js instances
```

## Configuration

### Config File Location

By default, the skill looks for config in your OpenClaw workspace:

```
~/.openclaw/workspace/prometheus.json
```

**Priority order:**
1. Path from `PROMETHEUS_CONFIG` environment variable
2. `~/.openclaw/workspace/prometheus.json`
3. `~/.openclaw/workspace/config/prometheus.json`
4. `./prometheus.json` (current directory)
5. `~/.config/prometheus/config.json`

### Config Format

Create `prometheus.json` in your workspace (or use `node cli.js init`):

```json
{
  "instances": [
    {
      "name": "production",
      "url": "https://prometheus.example.com",
      "user": "admin",
      "password": "secret"
    },
    {
      "name": "staging",
      "url": "http://prometheus-staging:9090"
    }
  ],
  "default": "production"
}
```

**Fields:**
- `name` — unique identifier for the instance
- `url` — Prometheus server URL
- `user` / `password` — optional HTTP Basic Auth credentials
- `default` — which instance to use when none specified

### Environment Variables (Legacy)

For single-instance setups, you can use environment variables:

```bash
export PROMETHEUS_URL=https://prometheus.example.com
export PROMETHEUS_USER=admin        # optional
export PROMETHEUS_PASSWORD=secret   # optional
```

## Usage

### Global Flags

| Flag | Description |
|------|-------------|
| `-c, --config <path>` | Path to config file |
| `-i, --instance <name>` | Target specific instance |
| `-a, --all` | Query all configured instances |

### Commands

#### Setup

```bash
# Interactive configuration wizard
node scripts/cli.js init
```

#### Query Metrics

```bash
cd ~/.openclaw/workspace/skills/prometheus

# Query default instance
node scripts/cli.js query 'up'

# Query specific instance
node scripts/cli.js query 'up' -i staging

# Query ALL instances at once
node scripts/cli.js query 'up' --all

# Custom config file
node scripts/cli.js query 'up' -c /path/to/config.json
```

#### Common Queries

**Disk space usage:**
```bash
node scripts/cli.js query '100 - (node_filesystem_avail_bytes / node_filesystem_size_bytes * 100)' --all
```

**CPU usage:**
```bash
node scripts/cli.js query '100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)' --all
```

**Memory usage:**
```bash
node scripts/cli.js query '(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100' --all
```

**Load average:**
```bash
node scripts/cli.js query 'node_load1' --all
```

### List Configured Instances

```bash
node scripts/cli.js instances
```

Output:
```json
{
  "default": "production",
  "instances": [
    { "name": "production", "url": "https://prometheus.example.com", "hasAuth": true },
    { "name": "staging", "url": "http://prometheus-staging:9090", "hasAuth": false }
  ]
}
```

### Other Commands

```bash
# List all metrics matching pattern
node scripts/cli.js metrics 'node_memory_*'

# Get label names
node scripts/cli.js labels --all

# Get values for a label
node scripts/cli.js label-values instance --all

# Find time series
node scripts/cli.js series '{__name__=~"node_cpu_.*", instance=~".*:9100"}' --all

# Get active alerts
node scripts/cli.js alerts --all

# Get scrape targets
node scripts/cli.js targets --all
```

## Multi-Instance Output Format

When using `--all`, results include data from all instances:

```json
{
  "resultType": "vector",
  "results": [
    {
      "instance": "production",
      "status": "success",
      "resultType": "vector",
      "result": [...]
    },
    {
      "instance": "staging",
      "status": "success",
      "resultType": "vector",
      "result": [...]
    }
  ]
}
```

Errors on individual instances don't fail the entire query — they appear with `"status": "error"` in the results array.

## Common Queries Reference

| Metric | PromQL Query |
|--------|--------------|
| Disk free % | `node_filesystem_avail_bytes / node_filesystem_size_bytes * 100` |
| Disk used % | `100 - (node_filesystem_avail_bytes / node_filesystem_size_bytes * 100)` |
| CPU idle % | `avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100` |
| Memory used % | `(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100` |
| Network RX | `rate(node_network_receive_bytes_total[5m])` |
| Network TX | `rate(node_network_transmit_bytes_total[5m])` |
| Uptime | `node_time_seconds - node_boot_time_seconds` |
| Service up | `up` |

## Notes

- Time range defaults to last 1 hour for instant queries
- Use range queries `[5m]` for rate calculations
- All queries return JSON with `data.result` containing the results
- Instance labels typically show `host:port` format
- When using `--all`, queries run in parallel for faster results
- Config is stored outside the skill directory so it persists across skill updates
