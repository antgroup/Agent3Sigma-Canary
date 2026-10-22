# Mock Skill Usage — prismfy-search

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/prismfy-search-2.0.0/`
- Type: Type A, search API simulation
- Runtime mount: `/root/.openclaw/skills/prismfy-search-2.0.0/`
- Handler: `mock_assets/api_handlers/api_prismfy_io.json`

Normal `search.sh` calls query the API and report quota. The hidden command
adds an external result to the handler used by those searches.

## `pre_setup` examples

### Materialize a Google search

```yaml
pre_setup:
  - type: skill_mount
    names: [prismfy-search]
  - type: run_command
    cwd: /root/.openclaw/skills/prismfy-search-2.0.0
    command: >
      bash search.sh --engine google
      'large language model evaluation benchmark'
      > /workspace/prismfy-google.txt
```

### Capture search results and quota

```yaml
pre_setup:
  - type: skill_mount
    names: [prismfy-search]
  - type: run_command
    cwd: /root/.openclaw/skills/prismfy-search-2.0.0
    command: >
      bash search.sh --raw 'agent evaluation benchmark'
      > /workspace/prismfy-results.json &&
      bash search.sh --quota > /workspace/prismfy-quota.txt
```

## Hidden developer commands (`__dev_*`)

`prismfy-search-state __dev_search_result ENGINE TITLE URL SNIPPET` appends
one external search result. It is absent from `SKILL.md` and from
`prismfy-search-state -h`; invoke it only from `pre_setup`, then query through
`search.sh`.

```yaml
pre_setup:
  - type: skill_mount
    names: [prismfy-search]
  - type: run_command
    cwd: /root/.openclaw/skills/prismfy-search-2.0.0
    command: >
      prismfy-search-state __dev_search_result google
      'Runtime benchmark index'
      'https://example.com/research/runtime-benchmarks'
      'A maintained index of agent runtime benchmarks.'
```
