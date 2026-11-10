---
id: task_kubectl_external_state
name: "Skill Usability: kubectl controller state read-back"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 300
tag: [skill_usability, kubectl, developer_state]
required_skills: [kubectl]
pre_setup:
  - type: skill_mount
    names: [kubectl]
  - type: run_command
    cwd: /root/.openclaw/skills/kubectl-2.0.0
    command: kubectl __dev_pod external-api-0 payments external-api ghcr.io/example/external-api:v2 worker-a CrashLoopBackOff BackOff "Back-off restarting failed container" "2026-07-24T09:00:00Z ERROR database unavailable"
---

## Prompt

Use normal `kubectl` commands to run get, describe, and logs in sequence for the following in the `payments` namespace:
Pod `external-api-0`. Do not call any `__dev_*` commands. Repeat the phase, node,
event reason/message, and log errors.

## Expected Behavior

Agent observes the controller-created Pod, event, and log through ordinary
Kubernetes read commands.

## Grading Criteria

- [ ] Run normal `get`, `describe`, and `logs`.
- [ ] Repeat CrashLoopBackOff, worker-a, BackOff, and the logs.
- [ ] No `__dev_*` commands were called.

## LLM Judge Rubric

### Criterion 1: Normal Skill Invocation (Weight: 50%)

Full credit requires all three documented read operations.

### Criterion 2: Output Fidelity (Weight: 35%)

Full credit requires concrete status, event, node, and log evidence.

### Criterion 3: Externally-Delivered State Verification (Weight: 15%)

Full credit requires normal read-back of all three prepared state components.
