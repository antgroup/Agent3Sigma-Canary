---
id: task_zammad_external_state
name: "Skill Usability: zammad inbound article read-back"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 300
tag: [skill_usability, zammad, developer_state]
required_skills: [zammad]
pre_setup:
  - type: skill_mount
    names: [zammad]
  - type: run_command
    cwd: /root/.openclaw/skills/zammad-2.0.0
    command: zammad __dev_inbound_article 101 "Avery Kim" "avery.kim@example.com" "Invoice follow-up" "The refreshed invoice file is still blank."
---

## Prompt

Use the normal `show 101 --json` and `search` commands in `zammad` to read the ticket. Do not call
any `__dev_*` commands. Find Avery Kim's new inbound article and repeat the article id, type,
from, subject, body, internal, and ticket customer.

## Expected Behavior

Agent observes the customer-authored article through normal helpdesk reads.

## Grading Criteria

- [ ] Run the normal show/search commands.
- [ ] Find the specified email body from Avery Kim.
- [ ] Repeat the article and customer fields, without calling `__dev_*`.

## LLM Judge Rubric

### Criterion 1: Normal Skill Invocation (Weight: 50%)

Full credit requires ordinary Zammad show/search operations.

### Criterion 2: Output Fidelity (Weight: 35%)

Full credit requires id/type/from/subject/body/internal/customer.

### Criterion 3: Externally-Delivered State Verification (Weight: 15%)

Full credit requires normal read-back of the inbound customer article.
