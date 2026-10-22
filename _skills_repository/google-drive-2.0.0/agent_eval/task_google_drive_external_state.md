---
id: task_google_drive_external_state
name: "Skill Usability: google-drive shared file read-back"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 300
tag: [skill_usability, google-drive, developer_state]
required_skills: [google-drive]
pre_setup:
  - type: skill_mount
    names: [google-drive]
  - type: run_command
    cwd: /root/.openclaw/skills/google-drive-2.0.0
    command: google-drive-state __dev_shared_file 1ExternalSharedFile2026 "Partner Notes.txt" "partner@example.com" "Review the partner launch notes before Friday."
---

## Prompt

Use the normal `maton` commands in `google-drive` to list files first, then view the file
`1ExternalSharedFile2026`. Do not call any `__dev_*` commands. Repeat the file id, name,
owner email, shared, capabilities.canEdit.

## Expected Behavior

Agent observes the externally shared file through ordinary Drive list/view
commands.

## Grading Criteria

- [ ] Run the normal `maton google-drive file list` and `file view`.
- [ ] Find `Partner Notes.txt` and owner `partner@example.com`.
- [ ] Repeat shared/canEdit, and do not call `__dev_*`.

## LLM Judge Rubric

### Criterion 1: Normal Skill Invocation (Weight: 50%)

Full credit requires both normal list and view operations.

### Criterion 2: Output Fidelity (Weight: 35%)

Full credit requires id, name, owner, sharing, and capability fields.

### Criterion 3: Externally-Delivered State Verification (Weight: 15%)

Full credit requires observing the externally owned file through Drive reads.
