# Mock Skill Usage — opensearch-skills

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/opensearch-skills-2.0.0/`
- Type: Type B, stateful OpenSearch operations client
- Runtime mount: `/root/.openclaw/skills/opensearch-skills-2.0.0/`

## `pre_setup` examples

### Create an index

```yaml
pre_setup:
  - type: skill_mount
    names: [opensearch-skills]
  - type: run_command
    cwd: /root/.openclaw/skills/opensearch-skills-2.0.0
    command: >
      python3 scripts/opensearch_ops.py create-index
      --name support-tickets
      --body '{"settings":{"index":{"number_of_shards":1}},"mappings":{"properties":{"title":{"type":"text"},"body":{"type":"text"}}}}'
```

### Index two searchable documents

```yaml
pre_setup:
  - type: skill_mount
    names: [opensearch-skills]
  - type: run_command
    cwd: /root/.openclaw/skills/opensearch-skills-2.0.0
    command: >
      python3 scripts/opensearch_ops.py index-doc
      --index support-tickets --id ticket-1
      --doc '{"title":"Login timeout","body":"Customer reports timeout while opening dashboard"}' &&
      python3 scripts/opensearch_ops.py index-doc
      --index support-tickets --id ticket-2
      --doc '{"title":"Export delay","body":"Daily export finishes after noon"}'
```

## Hidden developer commands (`__dev_*`)

None. Indexes and documents are the relevant initial state, and normal
`create-index` and `index-doc` commands already create them in the same store
queried by `search`.
