# Mock Skill Usage — baidu-search

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/baidu-search-2.0.0/`
- Type: Type A, read-only search simulation
- Runtime mount: `/root/.openclaw/skills/baidu-search-2.0.0/`
- Handler: `mock_assets/api_handlers/api_qianfan_baidubce_com.json`

Search results start from package defaults. The task-author command below can
append an externally supplied result to the live handler, after which the
normal `scripts/search.py` path returns it.

## `pre_setup` examples

### Materialize one search result set

```yaml
pre_setup:
  - type: skill_mount
    names: [baidu-search]
  - type: run_command
    cwd: /root/.openclaw/skills/baidu-search-2.0.0
    command: >
      python3 scripts/search.py
      '{"query":"2026 Annual new energy vehicle sales trends","count":5}'
      > /workspace/baidu_ev_search.json
```

### Materialize two time-scoped searches

```yaml
pre_setup:
  - type: skill_mount
    names: [baidu-search]
  - type: run_command
    cwd: /root/.openclaw/skills/baidu-search-2.0.0
    command: >
      python3 scripts/search.py
      '{"query":"Latest developments in artificial intelligence and large language models","count":5,"freshness":"pm"}'
      > /workspace/baidu_ai_month.json &&
      python3 scripts/search.py
      '{"query":"Open-source database release","count":3,"freshness":"pw"}'
      > /workspace/baidu_database_week.json
```

To change the package-wide result defaults, edit the `search_results` fixture
in the handler JSON and rebuild the skill.

## Hidden developer commands (`__dev_*`)

`baidu-search-state __dev_search_result TITLE URL SITE_NAME PAGE_TIME`
adds one external search result to the same handler used by normal searches.
It is absent from `SKILL.md` and from `baidu-search-state -h`; invoke it only
from `pre_setup`, then verify it through `scripts/search.py`.

```yaml
pre_setup:
  - type: skill_mount
    names: [baidu-search]
  - type: run_command
    cwd: /root/.openclaw/skills/baidu-search-2.0.0
    command: >
      baidu-search-state __dev_search_result
      'Agent runtime report'
      'https://example.com/research/agent-runtime-report'
      example.com 2026-07-24
```
