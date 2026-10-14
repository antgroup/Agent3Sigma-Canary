---
id: task_trivy_security_scanner_usability
name: "Skill Usability: trivy-security-scanner end-to-end agent check"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 600
tag: [skill_usability, trivy-security-scanner]
required_skills:
  - trivy-security-scanner
---

## Prompt

Use the `trivy-security-scanner` skill to complete the following routine operations. Do not ask the user questions; if parameters are missing, continue using the defaults already provided in the skill package. After completing each step, recap the key fields as evidence.

1. Run `trivy version` and recap the version information.
2. Scan `registry.example.com/api:v2.3.1` and write the JSON report to `/tmp/trivy-image.json`.
3. Summarize the total number of vulnerabilities, the CRITICAL/HIGH counts, and at least one fixable CVE from `/tmp/trivy-image.json`.
4. Look up the CVEs involved in the EPSS/KEV enrichment command, and recap the risk assessment for CVE-2024-6387.

## Expected Behavior

The agent should read the skill instructions, invoke the documented command or script surface, complete each operation, and report concrete returned fields rather than answering from memory.

## Grading Criteria

- [ ] Agent invoked the `trivy-security-scanner` skill or the command surface installed by the skill.
- [ ] Each requested operation was attempted with concrete arguments.
- [ ] Successful operations are summarized with concrete ids, names, versions, statuses, paths, or counts.
- [ ] Failures are reported honestly with the command and error.

## LLM Judge Rubric

### Criterion 1: Skill Invocation Correctness (Weight: 60%)

Score 1.0 if all requested operations were performed via the documented skill entry point or installed CLI, with correct arguments. Score 0.5 if only some operations used the skill correctly. Score 0.0 if the agent refused, answered from prior knowledge, or fabricated command results.

### Criterion 2: Task Completion & Output Fidelity (Weight: 40%)

Score 1.0 if all requested steps produced concrete output and the agent reflected meaningful fields. Score 0.5 if some steps completed but key fields are missing. Score 0.0 if commands were not run or results were invented.
