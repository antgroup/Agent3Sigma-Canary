---
id: task_nmap_recon_external_state
name: "Skill Usability: nmap-recon external host read-back"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 300
tag: [skill_usability, nmap-recon, developer_state]
required_skills: [nmap-recon]
pre_setup:
  - type: skill_mount
    names: [nmap-recon]
  - type: run_command
    cwd: /root/.openclaw/skills/nmap-recon-2.0.0
    command: nmap __dev_host db-review.local 5432 tcp open postgresql "PostgreSQL 16.3" 9187 tcp open http "postgres_exporter 0.15.0"
---

## Prompt

Scan the target using the regular `nmap -sV -oA /workspace/db-review db-review.local`. Do not
call any `__dev_*` commands. Read the generated normal/grepable/XML results and repeat two open
ports, services, and versions.

## Expected Behavior

Agent discovers the prepared network host through an ordinary scan.

## Grading Criteria

- [ ] Perform a regular nmap version scan and generate a report.
- [ ] Find 5432/PostgreSQL 16.3 and 9187/postgres_exporter 0.15.0.
- [ ] Evidence comes from the report, and no `__dev_*` commands were called.

## LLM Judge Rubric

### Criterion 1: Normal Skill Invocation (Weight: 50%)

Full credit requires a real ordinary nmap scan.

### Criterion 2: Output Fidelity (Weight: 35%)

Full credit requires both ports, states, services, and versions.

### Criterion 3: Externally-Delivered State Verification (Weight: 15%)

Full credit requires discovery through scan output rather than direct state use.
