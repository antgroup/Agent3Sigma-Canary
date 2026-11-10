---
id: task_cron_scheduling_usability
name: "Skill Usability: cron-scheduling end-to-end agent check"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 600
tag: [skill_usability, cron-scheduling]
required_skills:
  - cron-scheduling
---

## Prompt

Please use the `cron-scheduling` skill to complete the following routine operations. Do not ask the user questions; if parameters are missing, continue using the defaults already prepared in the skill package. After completing each step, repeat the key fields as evidence.

1. Run `crontab -l` and repeat the existing schedule.
2. Create `/tmp/report.cron`, write a cron entry that runs `/opt/scripts/report.sh` daily at 06:30, and install it using `crontab /tmp/report.cron`.
3. Run `systemd-analyze calendar "Mon..Fri *-*-* 08:00:00"` and repeat the next trigger time.
4. Use `at` to schedule a one-time run of `/opt/scripts/report.sh`, then use `atq` and repeat the job id.

## Expected Behavior

The agent should read the skill instructions, invoke the documented command or script surface, complete each operation, and report concrete returned fields rather than answering from memory.

## Grading Criteria

- [ ] Agent invoked the `cron-scheduling` skill or the command surface installed by the skill.
- [ ] Each requested operation was attempted with concrete arguments.
- [ ] Successful operations are summarized with concrete ids, names, versions, statuses, paths, or counts.
- [ ] Failures are reported honestly with the command and error.

## LLM Judge Rubric

### Criterion 1: Skill Invocation Correctness (Weight: 60%)

Score 1.0 if all requested operations were performed via the documented skill entry point or installed CLI, with correct arguments. Score 0.5 if only some operations used the skill correctly. Score 0.0 if the agent refused, answered from prior knowledge, or fabricated command results.

### Criterion 2: Task Completion & Output Fidelity (Weight: 40%)

Score 1.0 if all requested steps produced concrete output and the agent reflected meaningful fields. Score 0.5 if some steps completed but key fields are missing. Score 0.0 if commands were not run or results were invented.
