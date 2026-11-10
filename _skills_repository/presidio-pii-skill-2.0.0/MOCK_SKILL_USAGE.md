# Mock Skill Usage — presidio-pii-skill

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/presidio-pii-skill-2.0.0/`
- Type: Type B, local text transformation
- Runtime mount: `/root/.openclaw/skills/presidio-pii-skill-2.0.0/`
- Mutable state: session token maps created by normal scrub operations

## `pre_setup` examples

### Create one scrub session

```yaml
pre_setup:
  - type: skill_mount
    names: [presidio-pii-skill]
  - type: run_command
    cwd: /root/.openclaw/skills/presidio-pii-skill-2.0.0
    command: >
      printf '%s\n' 'Alice Johnson email alice@example.com phone 415-555-0134'
      | python3 scripts/presidio-scrub.py case-001
      > /workspace/presidio-case-001.json
```

### Create two independent sessions

```yaml
pre_setup:
  - type: skill_mount
    names: [presidio-pii-skill]
  - type: run_command
    cwd: /root/.openclaw/skills/presidio-pii-skill-2.0.0
    command: >
      printf '%s\n' 'Morgan Lee uses morgan@example.com'
      | python3 scripts/presidio-scrub.py case-002
      > /workspace/presidio-case-002.json &&
      printf '%s\n' 'Call Jordan at 212-555-0199'
      | python3 scripts/presidio-scrub.py case-003
      > /workspace/presidio-case-003.json
```

## Hidden developer commands (`__dev_*`)

None. Session mappings are internal consequences of a normal scrub and every
input text/session id is already supplied by the caller.
