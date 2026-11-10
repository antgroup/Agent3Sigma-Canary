# Mock Skill Usage — baidu-netdisk-skills

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/baidu-netdisk-skills-2.0.0/`
- Type: Type C, stateful CLI plus external API compatibility handlers
- Runtime mount: `/root/.openclaw/skills/baidu-netdisk-skills-2.0.0/`
- State file: `/var/lib/bdpan/state.json`

The installed `bdpan` CLI owns the task-local file tree. Upload, mkdir, move,
copy, rename, remove, and share operations persist and are visible to later
normal `bdpan` commands in the same task.

## `pre_setup` examples

### Seed one uploaded file

```yaml
pre_setup:
  - type: skill_mount
    names: [baidu-netdisk-skills]
  - type: run_command
    cwd: /root/.openclaw/skills/baidu-netdisk-skills-2.0.0
    command: >
      printf 'owner,amount\nAlice,1200\nBob,950\n' > /tmp/q3_expenses.csv &&
      bdpan mkdir documents/finance &&
      bdpan upload /tmp/q3_expenses.csv documents/finance/
```

### Seed several files and a share link

```yaml
pre_setup:
  - type: skill_mount
    names: [baidu-netdisk-skills]
  - type: run_command
    cwd: /root/.openclaw/skills/baidu-netdisk-skills-2.0.0
    command: >
      printf 'Launch checklist\n' > /tmp/launch.txt &&
      printf 'Review notes\n' > /tmp/review.txt &&
      bdpan mkdir documents/project-alpha &&
      bdpan upload /tmp/launch.txt documents/project-alpha/ &&
      bdpan upload /tmp/review.txt documents/project-alpha/ &&
      bdpan share documents/project-alpha --json
```

### Combine Netdisk with Git

```yaml
pre_setup:
  - type: skill_mount
    names: [baidu-netdisk-skills, git]
  - type: run_command
    cwd: /root/.openclaw/skills/baidu-netdisk-skills-2.0.0
    command: >
      git init /workspace/release-notes &&
      printf 'Release candidate 2.0\n' > /workspace/release-notes/README.md &&
      git -C /workspace/release-notes add README.md &&
      git -C /workspace/release-notes -c user.name='Task Author'
      -c user.email=task-author@example.com commit -m 'Seed release notes' &&
      bdpan upload /workspace/release-notes/README.md documents/release-notes/
```

The API handler defaults live under `mock_assets/api_handlers/`. Edit and
rebuild those files only when changing the package-wide defaults, not for a
single task.

## Hidden developer commands (`__dev_*`)

None. The normal stateful CLI can create all supported file/share states, so
task setup should use the documented commands above.
