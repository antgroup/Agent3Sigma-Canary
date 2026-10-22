# Mock Skill Usage — ssh-essentials

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/ssh-essentials-2.0.0/`
- Type: Type C, real local SSH services and standard clients
- Runtime mount: `/root/.openclaw/skills/ssh-essentials-2.0.0/`
- Host aliases: `ssh-workstation`, `ssh-root`, `bastion`, `internal-target`

## `pre_setup` examples

### Prepare remote files

```yaml
pre_setup:
  - type: skill_mount
    names: [ssh-essentials]
  - type: run_command
    cwd: /root/.openclaw/skills/ssh-essentials-2.0.0
    command: >
      ssh ssh-workstation
      'mkdir -p ~/incoming && printf "%s\n" "release candidate 2026-07-24" > ~/incoming/release.txt'
```

### Upload a review payload through the normal client

```yaml
pre_setup:
  - type: skill_mount
    names: [ssh-essentials]
  - type: run_command
    cwd: /root/.openclaw/skills/ssh-essentials-2.0.0
    command: >
      printf '%s\n' 'Rivermark SSH transfer check 2026-07-24'
      > /workspace/ssh-review.txt &&
      scp /workspace/ssh-review.txt
      ssh-workstation:~/incoming/ssh-review.txt
```

## Hidden developer commands (`__dev_*`)

None. Remote files, users, keys, tunnels, and transferred artifacts can all be
prepared through standard SSH commands against the same services the agent
uses.
