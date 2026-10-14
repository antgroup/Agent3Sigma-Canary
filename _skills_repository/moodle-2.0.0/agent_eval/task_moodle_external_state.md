---
id: task_moodle_external_state
name: "Skill Usability: moodle instructor assignment read-back"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 300
tag: [skill_usability, moodle, developer_state]
required_skills: [moodle]
pre_setup:
  - type: skill_mount
    names: [moodle]
  - type: run_command
    cwd: /root/.openclaw/skills/moodle-2.0.0
    command: moodle __dev_assignment 42 "Runtime evidence memo" 1784908800 "Attach the commands, outputs, and unresolved blockers."
---

## Prompt

Use `moodle` normal `assignments --course-id 42 --json` and
`contents 42 --json` commands with `moodle`. Do not call any `__dev_*` commands. Find the new assignment
`Runtime evidence memo`, and repeat the assignment id, duedate, intro, and module name.

## Expected Behavior

Agent observes the instructor-authored assignment through the learner-facing
read commands.

## Grading Criteria

- [ ] Run the normal assignments and contents commands.
- [ ] Find the specified assignment and repeat its id/duedate/intro.
- [ ] Find the corresponding module, and make sure it does not call `__dev_*`.

## LLM Judge Rubric

### Criterion 1: Normal Skill Invocation (Weight: 50%)

Full credit requires both normal Moodle read operations.

### Criterion 2: Output Fidelity (Weight: 35%)

Full credit requires concrete assignment and module fields.

### Criterion 3: Externally-Delivered State Verification (Weight: 15%)

Full credit requires observing the instructor-created item through normal reads.
