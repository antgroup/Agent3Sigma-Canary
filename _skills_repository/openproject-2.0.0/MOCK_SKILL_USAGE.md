# Mock Skill Usage — openproject

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/openproject-2.0.0/`
- Type: Type B, stateful project-management client
- Runtime mount: `/root/.openclaw/skills/openproject-2.0.0/`
- Default project: `customer-portal`

## `pre_setup` examples

### Create a work package

```yaml
pre_setup:
  - type: skill_mount
    names: [openproject]
  - type: run_command
    cwd: /root/.openclaw/skills/openproject-2.0.0
    command: >
      node scripts/openproject.mjs wp-create
      --project customer-portal --type Task
      --subject 'Audit API token rotation'
      --description 'Review current rotation checklist'
      > /workspace/openproject-work-package.json
```

### Capture projects and open work packages

```yaml
pre_setup:
  - type: skill_mount
    names: [openproject]
  - type: run_command
    cwd: /root/.openclaw/skills/openproject-2.0.0
    command: >
      node scripts/openproject.mjs project-list
      > /workspace/openproject-projects.json &&
      node scripts/openproject.mjs wp-list
      --project customer-portal --status open
      > /workspace/openproject-open-items.json
```

## Hidden developer commands (`__dev_*`)

`node scripts/openproject.mjs __dev_notification ID REASON PROJECT WP_ID SUBJECT DETAILS`
adds an externally delivered notification to the same state used by normal
`notification-list` and `notification-read` commands. It is absent from
`SKILL.md` and from the script's help; invoke it only from `pre_setup`.

```yaml
pre_setup:
  - type: skill_mount
    names: [openproject]
  - type: run_command
    cwd: /root/.openclaw/skills/openproject-2.0.0
    command: >
      node scripts/openproject.mjs __dev_notification
      10991 assigned customer-portal 4201
      'Checkout timeout regression'
      'Maya Chen assigned this work package to you after the incident review.'
```
