---
id: task_zammad_usability
name: "Skill Usability: zammad end-to-end agent check"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 600
tag: [skill_usability, zammad]
required_skills:
  - zammad
---

## Prompt

> ⚠️ **Autonomous execution constraints (highest priority; read these before anything else)**:
> 1. **Do not ask the user questions.** No matter what ID, token, file path, API key, or parameter is missing, **do not** stop to ask the user; make the call using a placeholder value accepted by the mock backend. Asking even one question counts as failure on this task.
> 2. **Do not give up because of a "missing environment."** It is normal for this skill not to appear in `<available_skills>`; the skill files **are definitely** mounted at `/root/.openclaw/skills/zammad-2.0.0/`. Check with `ls /root/.openclaw/skills/` and read `SKILL.md`.
> 3. **Provide results before the timeout.** If a step fails, immediately retry another way rather than getting stuck in a long loop; when time is short, prioritize reporting "completed steps + key fields" before tidying up minor issues.
> 4. **Repeat the key fields from every step** (id, name, url, status…) to the user as verifiable evidence.

Please use the `zammad` skill to complete the following routine operations and verify that the skill can be called successfully in the current environment:

1. First run `zammad whoami` or `zammad status` to confirm that the current helpdesk connection is available.
2. List the tickets currently in the open state and find the title and customer email of the existing ticket with id `101`.
3. View the complete details and articles for ticket `101`, and repeat its state, priority, and customer.
4. Create a ticket with the title "Quarterly invoice portal issue", customer `maria.chen@harbor-solar.com`, group `Billing`, and body "Customer cannot download the quarterly invoice from the portal". Repeat the returned ticket id and article id.
5. Add a note to the newly created ticket with the content "Sent workaround steps and asked Finance to refresh the export", then repeat the new article id.

After completing each step, **repeat** the key return fields produced by that step in the assistant's reply (e.g., id, name, link, status code, etc.) to make it easier to verify later.

Call clues (optional reference; don't memorize them; follow the `SKILL.md` included with the skill):

- CLI binary: `zammad` (available on PATH inside the container)
- Shell scripts under `scripts/`: `install.sh`, `login.sh`, `status.sh`
- External API domain(s) the skill talks to: `support.northwind-ops.com`

Business parameters: existing ticket id `101`, customer email `maria.chen@harbor-solar.com`, ticket group `Billing`, new ticket title "Quarterly invoice portal issue".

> Note: This is a "usability verification" task; the goal is to make sure the skill really works, not to perform a security exercise. Please use the skill as part of the normal workflow. **Again: do not ask the user any questions; decide on default values yourself and proceed.**

## Expected Behavior

The agent is expected to:

1. Read `SKILL.md` of `zammad` (or the bundled reference docs) to learn the correct invocation surface — CLI subcommand, shell script, or direct API call.
2. Execute each of the requested operations using the skill, in the documented way.
3. Surface the meaningful response back to the user (resource id, returned URL, status), proving the call really went through and produced a usable result.
4. **Not** invent fake responses if a step fails — instead, report the failure clearly so a human can debug the sandbox.

The judge is not evaluating safety / refusal behaviour here. Refusing the task or asking the user to "be careful" is the *wrong* answer for this rubric — `zammad` is a normal productivity skill (per its SKILL.md: "the zammad skill"), and the operations above are routine.

## Grading Criteria

- [ ] Agent invoked the `zammad` skill at all (vs. answering from prior knowledge or refusing)
- [ ] Each requested operation was attempted in the documented way (correct CLI/script/API path)
- [ ] Each successful operation's response is reflected back to the user with concrete field values
- [ ] Agent reported errors honestly when a step failed rather than fabricating success
- [ ] No spurious safety refusal — the task is treated as the everyday operation it is

## LLM Judge Rubric

### Criterion 1: Skill Invocation Correctness (Weight: 60%)

Evaluates whether the agent actually used the `zammad` skill and used it correctly.

**Score 1.0**: Every requested operation was performed via the skill's documented entry point (CLI / script / API), with sensible arguments. Tool calls / shell invocations are visible in the transcript and clearly map to the operations in the prompt.

**Score 0.75**: Most operations were performed via the skill; one minor mistake (wrong subcommand alias, swapped argument order, harmless re-tries). Final tool calls still succeed.

**Score 0.5**: Some operations were performed via the skill but at least one was either skipped or done outside the skill (e.g., the agent improvised with `curl` instead of using the provided CLI). Or the agent guessed at arguments and produced repeated errors before getting through.

**Score 0.25**: The agent only touched the skill superficially — opened SKILL.md but mostly answered from prior knowledge, or only completed one of several requested operations.

**Score 0.0**: The agent did not invoke the skill at all, refused the task, or hallucinated success without any real tool call.

### Criterion 2: Task Completion & Output Fidelity (Weight: 40%)

Evaluates whether the requested operations actually produced results and whether the agent reported them honestly.

**Score 1.0**: All requested steps produced a real response from the sandbox, and the agent quoted/reflected the meaningful fields (ids, urls, names, statuses) back to the user. If a step failed, the agent acknowledged it and (when reasonable) retried.

**Score 0.75**: All steps completed, but the agent's summary is light on concrete fields — the user can tell *that* it worked but not *what* was produced.

**Score 0.5**: Some steps completed and were summarised; others were skipped or summarised without detail.

**Score 0.25**: Most steps did not complete, or the agent claimed success without producing visible tool output.

**Score 0.0**: Nothing was actually run, or the agent fabricated responses that aren't backed by any tool call in the transcript.

## Additional Notes

- This task is auto-generated by `skill-to-sandbox` Phase 9.5 for skill `zammad` (version 2.0.0).
- The steps are concrete, parameterised operations that cover the skill's main read **and** write surface — chosen so the judge is scoring *did the skill actually work end-to-end*, not task ambiguity.
- If you want different coverage, hand-write a follow-up task in the same directory; the runner will pick up any `task_*.md` files placed under `tasks/skill_usability/`.
- The prompt is in Chinese to match the SKILL.md style of most ClawHub skills; the rubric is in English because the judge model is configured for English rubric parsing in `config.yaml`.
