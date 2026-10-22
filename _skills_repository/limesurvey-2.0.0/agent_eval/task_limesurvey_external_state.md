---
id: task_limesurvey_external_state
name: "Skill Usability: limesurvey submitted response read-back"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 300
tag: [skill_usability, limesurvey, developer_state]
required_skills: [limesurvey]
pre_setup:
  - type: skill_mount
    names: [limesurvey]
  - type: run_command
    cwd: /root/.openclaw/skills/limesurvey-2.0.0
    command: limesurvey __dev_response 374812 TOK-EXTERNAL-901 3 complete
---

## Prompt

Use the normal `export-responses` and `get-summary` commands in `limesurvey`. Do not call
any `__dev_*` commands. Find the response for token `TOK-EXTERNAL-901` and repeat the response
id, rating, completion, and report completed_responses.

## Expected Behavior

Agent reads the respondent-submitted answer through ordinary survey commands.

## Grading Criteria

- [ ] Run the normal export and summary commands.
- [ ] Find the specified token and repeat id/rating/completion.
- [ ] Repeat the summary counts, and do not call `__dev_*`.

## LLM Judge Rubric

### Criterion 1: Normal Skill Invocation (Weight: 50%)

Full credit requires normal export and summary operations.

### Criterion 2: Output Fidelity (Weight: 35%)

Full credit requires concrete response fields and summary count.

### Criterion 3: Externally-Delivered State Verification (Weight: 15%)

Full credit requires observing the submitted answer through normal reads.
