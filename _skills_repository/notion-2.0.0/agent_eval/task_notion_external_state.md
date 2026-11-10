---
id: task_notion_external_state
name: "Skill Usability: notion collaborator comment read-back"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 300
tag: [skill_usability, notion, developer_state]
required_skills: [notion]
pre_setup:
  - type: skill_mount
    names: [notion]
  - type: run_command
    cwd: /root/.openclaw/skills/notion-2.0.0
    command: notion-state __dev_comment a47f3c91-2e8d-4b56-9c1a-7d4e8f2b0a13 85d10000-0000-0000-0000-000000000001 "Please update the launch date before review."
---

## Prompt

Use the standard comments GET endpoint in the `notion` documentation to read the page
comments for `a47f3c91-2e8d-4b56-9c1a-7d4e8f2b0a13`. Do not call any `__dev_*`
commands. Repeat the comment id, author id, page id, created_time, and plain_text.

## Expected Behavior

Agent observes the collaborator comment through the ordinary Notion API.

## Grading Criteria

- [ ] Read using the standard `GET /v1/comments`.
- [ ] Find the specified text and author/page id.
- [ ] Repeat the comment id/time, and do not call `__dev_*`.

## LLM Judge Rubric

### Criterion 1: Normal Skill Invocation (Weight: 50%)

Full credit requires a documented authenticated Notion GET.

### Criterion 2: Output Fidelity (Weight: 35%)

Full credit requires concrete id, parent, author, time, and text fields.

### Criterion 3: Externally-Delivered State Verification (Weight: 15%)

Full credit requires normal read-back of the collaborator-authored comment.
