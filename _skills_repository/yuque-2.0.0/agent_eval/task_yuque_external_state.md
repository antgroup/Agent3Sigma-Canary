---
id: task_yuque_external_state
name: "Skill Usability: yuque colleague document read-back"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 300
tag: [skill_usability, yuque, developer_state]
required_skills: [yuque]
pre_setup:
  - type: skill_mount
    names: [yuque]
  - type: run_command
    cwd: /root/.openclaw/skills/yuque-2.0.0
    command: yuque-state __dev_doc 40999 "Wang Lei" "Release checklist" "Complete the rollback drill and verify monitoring before release." "release check"
---

## Prompt

Use the normal Python client for `yuque` to search for `Publishing Checklist`, then read the returned document details.
Do not call any `__dev_*` commands. Repeat the doc id, book id/name, title, author, URL
and body.

## Expected Behavior

Agent observes the colleague-authored document through normal Yuque search and
detail commands.

## Grading Criteria

- [ ] Perform a normal search and doc-detail.
- [ ] Find `Publishing Checklist`, author `Wang Lei`, and the specified body.
- [ ] Repeat the id/book/URL, and do not call `__dev_*`.

## LLM Judge Rubric

### Criterion 1: Normal Skill Invocation (Weight: 50%)

Full credit requires both normal Yuque search and document detail calls.

### Criterion 2: Output Fidelity (Weight: 35%)

Full credit requires concrete document, book, author, URL, and body fields.

### Criterion 3: Externally-Delivered State Verification (Weight: 15%)

Full credit requires normal read-back of the colleague-authored document.
