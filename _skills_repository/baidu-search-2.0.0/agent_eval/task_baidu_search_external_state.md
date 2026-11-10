---
id: task_baidu_search_external_state
name: "Skill Usability: baidu-search external result read-back"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 300
tag: [skill_usability, baidu-search, developer_state]
required_skills: [baidu-search]
pre_setup:
  - type: skill_mount
    names: [baidu-search]
  - type: run_command
    cwd: /root/.openclaw/skills/baidu-search-2.0.0
    command: baidu-search-state __dev_search_result "Agent runtime report" "https://example.com/research/agent-runtime-report" "example.com" "2026-07-24"
---

## Prompt

Use the normal search script for `baidu-search` to search for `Agent runtime report`. Do not call any
`__dev_*` commands. Repeat the pre-arrived result title, URL, site, and date, and include fields from the actual command output
as evidence.

## Expected Behavior

Agent reads `SKILL.md`, invokes `scripts/search.py`, and finds the externally
delivered result through the ordinary search surface.

## Grading Criteria

- [ ] Use the normal `baidu-search` search entry point.
- [ ] Find the title `Agent runtime report` and the specified URL.
- [ ] Repeat actual fields such as site/date, and do not call `__dev_*`.

## LLM Judge Rubric

### Criterion 1: Normal Skill Invocation (Weight: 50%)

Full credit only when the documented search script is actually executed.

### Criterion 2: Output Fidelity (Weight: 35%)

Full credit when title, URL, site, and date are grounded in command output.

### Criterion 3: Externally-Delivered State Verification (Weight: 15%)

Full credit when the injected result is observed through normal search without
using a developer command.
