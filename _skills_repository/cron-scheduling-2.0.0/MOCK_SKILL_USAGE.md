# Mock Skill Usage — cron-scheduling

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/cron-scheduling-2.0.0/`
- Type: Type B, stateful system-command simulation
- Runtime mount: `/root/.openclaw/skills/cron-scheduling-2.0.0/`
- State file: `/var/lib/cron-scheduling/state.json`

The installed `crontab`, `at`, `atq`, and related commands share task-local
state. Install schedules through those normal commands before the agent starts.

## `pre_setup` examples

### Seed one crontab

```yaml
pre_setup:
  - type: skill_mount
    names: [cron-scheduling]
  - type: run_command
    cwd: /root/.openclaw/skills/cron-scheduling-2.0.0
    command: >
      printf '%s\n' '30 6 * * * /opt/scripts/report.sh'
      > /tmp/report.cron &&
      crontab /tmp/report.cron
```

### Seed recurring and one-time jobs

```yaml
pre_setup:
  - type: skill_mount
    names: [cron-scheduling]
  - type: run_command
    cwd: /root/.openclaw/skills/cron-scheduling-2.0.0
    command: >
      printf '%s\n'
      '15 2 * * * /opt/scripts/backup.sh'
      '0 9 * * 1 /opt/scripts/weekly-status.sh'
      > /tmp/operations.cron &&
      crontab /tmp/operations.cron &&
      printf '/opt/scripts/reindex.sh\n' | at 17:45
```

### Combine Cron with Git

```yaml
pre_setup:
  - type: skill_mount
    names: [cron-scheduling, git]
  - type: run_command
    cwd: /root/.openclaw/skills/cron-scheduling-2.0.0
    command: >
      git init /workspace/scheduled-report &&
      printf '#!/bin/sh\necho weekly report\n' > /workspace/scheduled-report/report.sh &&
      chmod +x /workspace/scheduled-report/report.sh &&
      git -C /workspace/scheduled-report add report.sh &&
      git -C /workspace/scheduled-report -c user.name='Task Author'
      -c user.email=task-author@example.com commit -m 'Seed report job' &&
      printf '%s\n' '0 8 * * 1 /workspace/scheduled-report/report.sh'
      > /tmp/report-job.cron &&
      crontab /tmp/report-job.cron
```

## Hidden developer commands (`__dev_*`)

None. Normal scheduling commands can create and remove every supported state.
