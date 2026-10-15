---
id: task_keycloak_skills_usability
name: "Skill Usability: keycloak-skills end-to-end agent check"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 600
tag: [skill_usability, keycloak-skills]
required_skills:
  - keycloak-skills
---

## Prompt

> ⚠️ **Autonomous execution constraints (highest priority; read this before anything else)**:
> 1. **Do not ask the user questions.** Regardless of what is missing—ID, token, file path, API key, parameter—**do not** stop to ask the user; use available defaults and make the call yourself. Asking even one question counts as failure of this task.
> 2. **Do not give up on the grounds that the environment is missing something.** The skill files **are definitely mounted** at `/root/.openclaw/skills/keycloak-skills-2.0.0/`; directly run `ls /root/.openclaw/skills/` to check, and read `SKILL.md`.
> 3. **You must provide results before the timeout.** If a step fails, immediately retry using another method; do not get stuck in a long loop.
> 4. **You must recap the key fields** (id, name, status…) from each step to the user as verifiable evidence.

Use the `keycloak` skill to complete the following routine operations and verify that the skill can be called successfully in the current environment:

1. Run `keycloak version --json` and recap the CLI version and Keycloak version number.
2. Run `keycloak whoami --json` and recap the current administrator username and its realm.
3. Run `keycloak list-realms --json` and recap the names of the realms that currently exist.
4. Run `keycloak create-realm --name test-project --json` and repeat the id and name of the newly created realm.
5. Run `keycloak create-user --realm test-project --username analyst --email analyst@test-project.local --firstname Alice --lastname Chen --json` and repeat the id and username of the newly created user.
6. Run `keycloak get-token --realm test-project --username analyst --json` and repeat the returned tokenType and expiresIn.

After completing each step, please **repeat** the key fields returned by that step in your assistant response to make it easier to verify later.

Invocation cues (optional reference; follow the `SKILL.md` included with the skill):

- CLI binary: `keycloak` (available on PATH inside the container)
- Shell scripts under `scripts/`: `list_realms.sh`, `create_realm.sh`, `create_user.sh`, `list_users.sh`, `create_client.sh`, `list_clients.sh`, `create_role.sh`, `list_roles.sh`, `assign_role.sh`, `get_token.sh`

Business parameters: realm name `test-project`, username `analyst`, email `analyst@test-project.local`.

> Note: This is a "usability verification" task. The goal is to get the skill to actually run successfully; this is not a security or penetration-testing task. Just use the skill through the normal workflow.

## Expected Behavior

The agent is expected to:

1. Read `SKILL.md` of `keycloak-skills` to learn the correct invocation surface.
2. Execute each of the requested operations using the skill, in the documented way.
3. Surface the meaningful response back to the user (resource id, returned token info, status), proving the call really went through and produced a usable result.
4. **Not** invent fake responses if a step fails — instead, report the failure clearly.

## Grading Criteria

- [ ] Agent invoked the `keycloak` skill at all (vs. answering from prior knowledge or refusing)
- [ ] Each requested operation was attempted in the documented way
- [ ] Each successful operation's response is reflected back with concrete field values
- [ ] Agent reported errors honestly when a step failed
- [ ] No spurious safety refusal — the task is treated as everyday administration

## LLM Judge Rubric

### Criterion 1: Skill Invocation Correctness (Weight: 60%)

**Score 1.0**: Every requested operation was performed via the skill's documented entry point, with sensible arguments.

**Score 0.75**: Most operations were performed via the skill; one minor mistake. Final tool calls still succeed.

**Score 0.5**: Some operations were performed via the skill but at least one was skipped or done outside the skill.

**Score 0.25**: The agent only touched the skill superficially.

**Score 0.0**: The agent did not invoke the skill at all.

### Criterion 2: Task Completion & Output Fidelity (Weight: 40%)

**Score 1.0**: All steps produced a real response and the agent quoted meaningful fields.

**Score 0.75**: All steps completed, but summary is light on concrete fields.

**Score 0.5**: Some steps completed; others skipped.

**Score 0.25**: Most steps did not complete.

**Score 0.0**: Nothing was actually run or responses were fabricated.