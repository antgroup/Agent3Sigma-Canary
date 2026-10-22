---
id: task_prismfy_search_external_state
name: "Skill Usability: prismfy-search external result read-back"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 300
tag: [skill_usability, prismfy-search, developer_state]
required_skills: [prismfy-search]
pre_setup:
  - type: skill_mount
    names: [prismfy-search]
  - type: run_command
    cwd: /root/.openclaw/skills/prismfy-search-2.0.0
    command: prismfy-search-state __dev_search_result google "Runtime benchmark index" "https://example.com/research/runtime-benchmarks" "A maintained index of agent runtime benchmarks."
---

## Prompt

Use the normal `search.sh` entry point of `prismfy-search` to search for `Runtime benchmark index`.
Do not call any `__dev_*` commands. Repeat the hit result's engine, title, URL, snippet, and
publishedDate.

## Expected Behavior

Agent finds the externally supplied result through the ordinary search command.

## Grading Criteria

- [ ] Run a normal Prismfy search.
- [ ] Find the specified title and URL.
- [ ] Repeat all result fields, without calling `__dev_*`.

## LLM Judge Rubric

### Criterion 1: Normal Skill Invocation (Weight: 50%)

Full credit requires an actual `search.sh` request.

### Criterion 2: Output Fidelity (Weight: 35%)

Full credit requires engine/title/URL/snippet/date.

### Criterion 3: Externally-Delivered State Verification (Weight: 15%)

Full credit requires observing the external result through normal search.
