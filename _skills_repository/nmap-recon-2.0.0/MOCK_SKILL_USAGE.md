# Mock Skill Usage — nmap-recon

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/nmap-recon-2.0.0/`
- Type: Type A.2, network scanner simulation
- Runtime mount: `/root/.openclaw/skills/nmap-recon-2.0.0/`
- State file: `/var/lib/nmap-recon/state.json`

Normal scans create text, grepable, and XML reports. The hidden command defines
an externally existing host profile that normal scans subsequently discover.

## `pre_setup` examples

### Produce a version-detection report

```yaml
pre_setup:
  - type: skill_mount
    names: [nmap-recon]
  - type: run_command
    cwd: /root/.openclaw/skills/nmap-recon-2.0.0
    command: >
      nmap -sC -sV -oA /workspace/scanme scanme.local
```

### Produce a vulnerability-script report

```yaml
pre_setup:
  - type: skill_mount
    names: [nmap-recon]
  - type: run_command
    cwd: /root/.openclaw/skills/nmap-recon-2.0.0
    command: >
      nmap --script vuln -oA /workspace/scanme-vuln scanme.local
```

## Hidden developer commands (`__dev_*`)

`nmap __dev_host TARGET PORT PROTOCOL STATE SERVICE VERSION` accepts one or
more five-field port groups after `TARGET`. It is absent from `SKILL.md` and
from `nmap -h`; invoke it only from `pre_setup`, then scan the target normally.

```yaml
pre_setup:
  - type: skill_mount
    names: [nmap-recon]
  - type: run_command
    cwd: /root/.openclaw/skills/nmap-recon-2.0.0
    command: >
      nmap __dev_host db-review.local
      5432 tcp open postgresql 'PostgreSQL 16.3'
      9187 tcp open http 'postgres_exporter 0.15.0'
```
