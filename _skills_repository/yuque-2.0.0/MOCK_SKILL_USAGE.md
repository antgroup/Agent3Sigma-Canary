# Mock Skill Usage — yuque

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/yuque-2.0.0/`
- Type: Type C, local Yuque service plus Python client
- Runtime mount: `/root/.openclaw/skills/yuque-2.0.0/`
- Current user: Lin Tao (`lintao`)

Normal client calls create and update documents as the current user. The hidden
command adds a document authored by a colleague to the same in-process service.

## `pre_setup` examples

### Create a current-user draft

```yaml
pre_setup:
  - type: skill_mount
    names: [yuque]
  - type: run_command
    cwd: /root/.openclaw/skills/yuque-2.0.0
    command: >
      python3 scripts/yuque_client.py doc-create 40999
      'Complete API integration testing this week; conduct load testing next week.'
      --title '2026 Week 30 weekly report' --public 0
```

### Capture a search and book listing

```yaml
pre_setup:
  - type: skill_mount
    names: [yuque]
  - type: run_command
    cwd: /root/.openclaw/skills/yuque-2.0.0
    command: >
      python3 scripts/yuque_client.py search 'weekly report' --json
      > /workspace/yuque-search.json &&
      python3 scripts/yuque_client.py doc-list 40999 --json
      > /workspace/yuque-drafts.json
```

## Hidden developer commands (`__dev_*`)

`yuque-state __dev_doc BOOK_ID AUTHOR TITLE BODY KEYWORD` adds an
externally authored document and registers its search keyword. It is absent
from `SKILL.md` and from `yuque-state -h`; invoke it only from `pre_setup`,
then verify through normal `search` and `doc-detail`.

```yaml
pre_setup:
  - type: skill_mount
    names: [yuque]
  - type: run_command
    cwd: /root/.openclaw/skills/yuque-2.0.0
    command: >
      yuque-state __dev_doc 40999 'Wang Lei'
      'Release checklist' 'Complete the rollback drill and verify monitoring before release.'
      'release check'
```
