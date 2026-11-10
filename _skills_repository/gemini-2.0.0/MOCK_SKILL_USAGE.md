# Mock Skill Usage — gemini

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/gemini-2.0.0/`
- Type: Type A, deterministic generation simulation
- Runtime mount: `/root/.openclaw/skills/gemini-2.0.0/`
- Handler: `mock_assets/api_handlers/api_generativelanguage_googleapis_com.json`

The generated answer depends on the prompt but there is no persistent backend
conversation. Seed a task by materializing source files or prior outputs.

## `pre_setup` examples

### Seed one generated briefing

```yaml
pre_setup:
  - type: skill_mount
    names: [gemini]
  - type: run_command
    cwd: /root/.openclaw/skills/gemini-2.0.0
    command: >
      gemini 'Explain what a vector database is in three sentences'
      > /workspace/vector-database-briefing.txt
```

### Seed source material and its summary

```yaml
pre_setup:
  - type: skill_mount
    names: [gemini]
  - type: run_command
    cwd: /root/.openclaw/skills/gemini-2.0.0
    command: >
      printf 'v2.1 Fix the login timeout issue and add bulk export.\n'
      > /workspace/release-note.txt &&
      gemini 'Summarize the following release notes in one sentence:v2.1 Fix the login timeout issue and add bulk export.'
      > /workspace/release-summary.txt
```

To change the package-wide API response shape, edit the handler fixtures and
rebuild the skill.

## Hidden developer commands (`__dev_*`)

None. This generation surface has no inbound persistent record state.
