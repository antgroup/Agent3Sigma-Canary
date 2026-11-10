---
id: task_xiaohongshu_mcp_external_state
name: "Skill Usability: xiaohongshu-mcp external feed read-back"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 300
tag: [skill_usability, xiaohongshu-mcp, developer_state]
required_skills: [xiaohongshu-mcp]
pre_setup:
  - type: skill_mount
    names: [xiaohongshu-mcp]
  - type: run_command
    cwd: /root/.openclaw/skills/xiaohongshu-mcp-2.0.0
    command: xhs-state __dev_feed 66aa00000000000000000001 TOKEN_EXT_20260724 "Hangzhou weekend hiking routes" "Shanye Jiluyuan" "Three weekend hiking routes suitable for beginners." "Is the second route easy to reach by public transportation?"
---

## Prompt

Use the normal `search`, `feeds`, and `detail` commands of `xiaohongshu-mcp` to read newly arrived
notes. Do not call any `__dev_*` commands. Repeat the feed id, token, title, author,
description, and comment content.

## Expected Behavior

Agent observes the externally authored feed and detail through the normal
Python client.

## Grading Criteria

- [ ] Execute normal search/feeds/detail.
- [ ] Find `Hangzhou Weekend Hiking Routes` and author `Shanye Jilu Yuan`.
- [ ] Repeat the id/token/body/comments, and do not call `__dev_*`.

## LLM Judge Rubric

### Criterion 1: Normal Skill Invocation (Weight: 50%)

Full credit requires normal client reads, including detail.

### Criterion 2: Output Fidelity (Weight: 35%)

Full credit requires all requested feed and detail fields.

### Criterion 3: Externally-Delivered State Verification (Weight: 15%)

Full credit requires normal read-back of the external feed.
