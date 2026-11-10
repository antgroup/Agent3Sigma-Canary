---
id: task_prometheus_external_state
name: "Skill Usability: prometheus external alert read-back"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 300
tag: [skill_usability, prometheus, developer_state]
required_skills: [prometheus]
pre_setup:
  - type: skill_mount
    names: [prometheus]
  - type: run_command
    cwd: /root/.openclaw/skills/prometheus-2.0.0
    command: prometheus-state __dev_alert production CheckoutLatency critical checkout-01:9100 "Checkout latency exceeds the service objective."
---

## Prompt

Use the normal `node scripts/cli.js alerts --all` command for `prometheus`. Do not call
any `__dev_*` commands. Find the `CheckoutLatency` alert and report its instance, severity,
state, activeAt, and summary.

## Expected Behavior

Agent observes the monitoring-system-generated alert through the normal CLI.

## Grading Criteria

- [ ] Run the normal alerts command.
- [ ] Find CheckoutLatency/critical/checkout-01:9100.
- [ ] Report the state, time, and summary, and confirm that no `__dev_*` commands were called.

## LLM Judge Rubric

### Criterion 1: Normal Skill Invocation (Weight: 50%)

Full credit requires the documented Prometheus alerts command.

### Criterion 2: Output Fidelity (Weight: 35%)

Full credit requires all alert label/state/time/annotation fields.

### Criterion 3: Externally-Delivered State Verification (Weight: 15%)

Full credit requires normal read-back of the external firing alert.
