---
id: task_chatwoot_external_state
name: "Skill Usability: chatwoot inbound message read-back"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 300
tag: [skill_usability, chatwoot, developer_state]
required_skills: [chatwoot]
pre_setup:
  - type: skill_mount
    names: [chatwoot]
  - type: run_command
    cwd: /root/.openclaw/skills/chatwoot-2.0.0
    command: chatwoot-state __dev_inbound_message 87001 "Avery Kim" "avery.kim@example.com" "The refreshed invoice export is still empty."
---

## Prompt

Use the normal conversation-detail GET endpoint documented in `chatwoot` to read conversation `87001`.
Do not call any `__dev_*` commands. Find the newly arrived message from customer Avery Kim and report the message
id, sender email, message_type, and content.

## Expected Behavior

Agent uses the documented Chatwoot API and observes the inbound message in the
normal conversation response.

## Grading Criteria

- [ ] Read the conversation using the normal Chatwoot GET endpoint.
- [ ] Find Avery Kim and the full message content.
- [ ] Report the message id/type/email, without calling `__dev_*`.

## LLM Judge Rubric

### Criterion 1: Normal Skill Invocation (Weight: 50%)

Full credit requires a documented authenticated conversation GET.

### Criterion 2: Output Fidelity (Weight: 35%)

Full credit requires concrete sender, id, type, and content fields.

### Criterion 3: Externally-Delivered State Verification (Weight: 15%)

Full credit requires reading the customer-authored message through the normal
API surface.
