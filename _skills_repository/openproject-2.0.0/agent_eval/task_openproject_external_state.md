---
id: task_openproject_external_state
name: "Skill Usability: openproject notification read-back"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 300
tag: [skill_usability, openproject, developer_state]
required_skills: [openproject]
pre_setup:
  - type: skill_mount
    names: [openproject]
  - type: run_command
    cwd: /root/.openclaw/skills/openproject-2.0.0
    command: node scripts/openproject.mjs __dev_notification 10991 assigned customer-portal 4201 "Checkout timeout regression" "Maya Chen assigned this work package to you after the incident review."
---

## Prompt

Use OpenProject's regular `notification-list --unread` and
`notification-read --id 10991` commands to read the new notification. Do not call any `__dev_*`
commands. Repeat the notification id, reason, project, work package, subject, read
status, and notification details.

## Expected Behavior

Agent observes an externally delivered assignment notification through the
ordinary OpenProject notification surface.

## Grading Criteria

- [ ] Use the regular notification list and detail commands.
- [ ] Find notification 10991 and its fields, including assigned, customer-portal, and WP 4201.
- [ ] Repeat Maya Chen's notification details without calling `__dev_*`.

## LLM Judge Rubric

### Criterion 1: Normal Skill Invocation (Weight: 50%)

Full credit requires both documented notification read operations.

### Criterion 2: Output Fidelity (Weight: 35%)

Full credit requires the real id, reason, project, work-package id, subject,
read state, and detail text.

### Criterion 3: Externally-Delivered State Verification (Weight: 15%)

Full credit requires observing the prepared notification through normal
OpenProject commands.
