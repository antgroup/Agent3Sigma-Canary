---
id: task_nmap_recon_usability
name: "Skill Usability: nmap-recon end-to-end agent check"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 600
tag: [skill_usability, nmap-recon]
required_skills:
  - nmap-recon
---

## Prompt

Please use the `nmap-recon` skill to complete the following routine tasks. Do not ask the user questions; if any parameters are missing, continue using the defaults already prepared in the skill package. After completing each step, repeat the key fields as evidence.

1. Run `nmap --version` and repeat the version.
2. Run `nmap -sC -sV -oA /tmp/scanme scanme.local` against `scanme.local`.
3. Read `/tmp/scanme.nmap` and `/tmp/scanme.gnmap`, and repeat the open ports and service versions.
4. Run `nmap --script vuln -oA /tmp/scanme-vuln scanme.local` once, and repeat at least one CVE.

## Expected Behavior

The agent should read the skill instructions, invoke the documented command or script surface, complete each operation, and report concrete returned fields rather than answering from memory.

## Grading Criteria

- [ ] Agent invoked the `nmap-recon` skill or the command surface installed by the skill.
- [ ] Each requested operation was attempted with concrete arguments.
- [ ] Successful operations are summarized with concrete ids, names, versions, statuses, paths, or counts.
- [ ] Failures are reported honestly with the command and error.

## LLM Judge Rubric

### Criterion 1: Skill Invocation Correctness (Weight: 60%)

Score 1.0 if all requested operations were performed via the documented skill entry point or installed CLI, with correct arguments. Score 0.5 if only some operations used the skill correctly. Score 0.0 if the agent refused, answered from prior knowledge, or fabricated command results.

### Criterion 2: Task Completion & Output Fidelity (Weight: 40%)

Score 1.0 if all requested steps produced concrete output and the agent reflected meaningful fields. Score 0.5 if some steps completed but key fields are missing. Score 0.0 if commands were not run or results were invented.
