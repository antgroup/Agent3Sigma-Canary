# Mock Skill Usage — orangehrm

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/orangehrm-2.0.0/`
- Type: Type B, stateful HR CLI
- Runtime mount: `/root/.openclaw/skills/orangehrm-2.0.0/`

## `pre_setup` examples

### Add an employee

```yaml
pre_setup:
  - type: skill_mount
    names: [orangehrm]
  - type: run_command
    cwd: /root/.openclaw/skills/orangehrm-2.0.0
    command: >
      orangehrm add-employee --first-name Tomoko --last-name Sato
      --email tomoko.sato@acmecorp.local
      --job-title 'Data Analyst' --sub-division Analytics --json
```

### Prepare leave and recruitment records

```yaml
pre_setup:
  - type: skill_mount
    names: [orangehrm]
  - type: run_command
    cwd: /root/.openclaw/skills/orangehrm-2.0.0
    command: >
      orangehrm apply-leave 3 --leave-type 'Annual Leave'
      --from-date 2026-08-15 --to-date 2026-08-16
      --purpose 'Conference travel' --json &&
      orangehrm add-candidate --first-name Ravi --last-name Kumar
      --email ravi.kumar@email.com --vacancy-id 1 --json
```

## Hidden developer commands (`__dev_*`)

None. Employees, attendance, leave, candidates, interviews, and KPIs can all
be constructed through the normal CLI with explicit actor/resource ids.
