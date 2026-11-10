---
id: task_openproject_usability
name: "Skill Usability: openproject end-to-end agent check"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 600
tag: [skill_usability, openproject]
required_skills:
  - openproject
pre_setup:
  - type: skill_copy
    source_path_dir: _skills_repository/openproject-2.0.0
    target_path_dir: openproject-2.0.0
---

## Prompt

> Autonomous execution constraints:
> 1. Do not ask the user questions; if a token, project name, or path is missing, proceed directly using the skill documentation and default project.
> 2. Do not stop because of missing environment variables or dependencies; first read `skills/openproject-2.0.0/SKILL.md`, then execute the commands in it.
> 3. Repeat the key fields at every step: project identifier, work package id, subject, status, comment id, URL.

Use the `openproject` skill to complete the following set of routine project management operations:

1. List the projects and confirm the name and identifier of the `customer-portal` project.
2. List the work packages in `customer-portal` whose status is `open`, and repeat the id and subject of at least one work package.
3. Create a work package: project=`customer-portal`, type=`Task`, subject=`Audit API token rotation`, description=`Review current rotation checklist`; repeat the returned id and URL.
4. Add a comment to the work package created in step 3: `Initial review scheduled`; repeat the comment id.
5. Update the status of the work package created in step 3 to `In progress`, then read its details and repeat the id, subject, and status.

Recommended command format:

```bash
node skills/openproject-2.0.0/scripts/openproject.mjs project-list
node skills/openproject-2.0.0/scripts/openproject.mjs wp-list --project customer-portal --status open
node skills/openproject-2.0.0/scripts/openproject.mjs wp-create --project customer-portal --type Task --subject "Audit API token rotation" --description "Review current rotation checklist"
```

## Expected Behavior

The agent should invoke the OpenProject skill through its documented command-line entry point, complete each step, and report concrete fields from the command output. It should not fabricate ids or URLs; if a command fails, it should retry with the skill's bundled script path.

## Grading Criteria

- [ ] The agent read or invoked the `openproject` skill rather than answering from memory.
- [ ] The agent listed projects and identified `customer-portal`.
- [ ] The agent listed existing work packages for `customer-portal`.
- [ ] The agent created a new work package and reported its id and URL.
- [ ] The agent added a comment and reported the comment id.
- [ ] The agent updated/read back the created work package and reported status `In progress`.

## LLM Judge Rubric

### Criterion 1: Skill Invocation Correctness (Weight: 60%)

**Score 1.0**: All operations are performed through the OpenProject skill's command-line script, with sensible arguments and visible command output.

**Score 0.75**: Most operations use the skill; one minor retry or argument correction is needed.

**Score 0.5**: Some operations use the skill, but at least one required operation is skipped or done outside the skill.

**Score 0.25**: The agent only inspects the skill superficially and mostly answers without running commands.

**Score 0.0**: The agent does not invoke the skill, refuses the task, or fabricates success.

### Criterion 2: Task Completion & Output Fidelity (Weight: 40%)

**Score 1.0**: All requested steps complete, and the final answer includes concrete project/work-package/comment fields from the outputs.

**Score 0.75**: All steps complete, but the summary omits one or two useful fields.

**Score 0.5**: Some steps complete, but one important create/update/read-back step is missing.

**Score 0.25**: Most operations fail or are not attempted.

**Score 0.0**: No real command output backs the answer.
