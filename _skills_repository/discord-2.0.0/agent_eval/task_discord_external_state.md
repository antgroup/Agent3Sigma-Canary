---
id: task_discord_external_state
name: "Skill Usability: discord inbound message read-back"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 300
tag: [skill_usability, discord, developer_state]
required_skills: [discord]
pre_setup:
  - type: skill_mount
    names: [discord]
  - type: run_command
    cwd: /root/.openclaw/skills/discord-2.0.0
    command: discord-state __dev_inbound_message 1184235687423610001 700000000000000001 release_bot "Deployment finished successfully; smoke checks are green."
---

## Prompt

Use the normal recent-messages operation in `discord` to read the channel
`1184235687423610001`. Do not call any `__dev_*` commands. Find the new message from `release_bot`
and repeat its message id, author id, username, and full content.

## Expected Behavior

Agent uses the documented Discord read surface and observes the externally
delivered channel message.

## Grading Criteria

- [ ] Call the normal Discord recent-messages endpoint.
- [ ] Find the specified message from `release_bot`.
- [ ] Repeat id/author/content, and do not call `__dev_*`.

## LLM Judge Rubric

### Criterion 1: Normal Skill Invocation (Weight: 50%)

Full credit requires a real recent-messages call through the skill.

### Criterion 2: Output Fidelity (Weight: 35%)

Full credit requires concrete message and author fields.

### Criterion 3: Externally-Delivered State Verification (Weight: 15%)

Full credit requires normal-surface read-back of the inbound message.
