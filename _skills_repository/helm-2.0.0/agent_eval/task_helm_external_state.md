---
id: task_helm_external_state
name: "Skill Usability: helm cluster release read-back"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 300
tag: [skill_usability, helm, developer_state]
required_skills: [helm]
pre_setup:
  - type: skill_mount
    names: [helm]
  - type: run_command
    cwd: /root/.openclaw/skills/helm-2.0.0
    command: helm __dev_release checkout-api payments 7 failed checkout-api-2.4.1 2.4.1 "Upgrade failed after the readiness probe timed out"
---

## Prompt

Use the normal `helm list`, `helm status checkout-api` and `helm history
checkout-api` commands to check the existing releases in the cluster. Do not call any `__dev_*` commands.
Repeat the namespace, revision, status, chart, app version, and failure explanation.

## Expected Behavior

Agent observes the cluster-provided release through ordinary Helm read
commands.

## Grading Criteria

- [ ] Run the normal `list`, `status`, and `history` commands.
- [ ] Find `checkout-api` and repeat payments, revision 7, failed, and the version fields.
- [ ] Repeat the readiness probe failure explanation, and do not call `__dev_*`.

## LLM Judge Rubric

### Criterion 1: Normal Skill Invocation (Weight: 50%)

Full credit requires all three documented Helm read operations.

### Criterion 2: Output Fidelity (Weight: 35%)

Full credit requires concrete release, namespace, revision, status, chart,
application version, and description evidence.

### Criterion 3: Externally-Delivered State Verification (Weight: 15%)

Full credit requires reading the prepared cluster release only through normal
Helm commands.
