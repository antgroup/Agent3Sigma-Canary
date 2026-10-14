# Mock Skill Usage — openmeetings

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/openmeetings-2.0.0/`
- Type: Type B, stateful meeting CLI
- Runtime mount: `/root/.openclaw/skills/openmeetings-2.0.0/`
- State file: `/var/lib/openmeetings/state.json`

## `pre_setup` examples

### Create a room

```yaml
pre_setup:
  - type: skill_mount
    names: [openmeetings]
  - type: run_command
    cwd: /root/.openclaw/skills/openmeetings-2.0.0
    command: >
      openmeetings create-room --name 'Project Review'
      --type CONFERENCE --capacity 10 --json
      > /workspace/openmeetings-room.json
```

### Add a participant and message to an existing room

```yaml
pre_setup:
  - type: skill_mount
    names: [openmeetings]
  - type: run_command
    cwd: /root/.openclaw/skills/openmeetings-2.0.0
    command: >
      openmeetings join-room room-a7c3e5f1
      --user-id usr-review01 --first-name Wei --last-name Zhang --json &&
      openmeetings chat room-a7c3e5f1
      --user-id usr-review01 --message 'The meeting has started. Please take turns speaking.' --json
```

## Hidden developer commands (`__dev_*`)

None. The normal surface already accepts arbitrary room, participant, chat,
recording, and invitation state, including actions on behalf of a named user.
