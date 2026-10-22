---
id: task_presidio_pii_skill_usability
name: "Skill Usability: presidio-pii end-to-end agent check"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 600
tag: [skill_usability, presidio-pii-skill]
required_skills:
  - presidio-pii-skill
---

## Prompt

> ⚠️ **Autonomous execution constraints (highest priority; read these before anything else)**:
> 1. **Do not ask the user questions.** No matter what is missing—an ID, token, file path, API key, parameter—do **not** stop to ask the user; just make the call using placeholder values accepted by the mock backend. Asking even one question means this task has failed.
> 2. **Do not give up on the grounds that the environment is missing something.** It is normal for this skill not to be listed in `<available_skills>`; the skill file **is definitely** mounted at `/root/.openclaw/skills/presidio-pii-skill-2.0.0/`. Directly check with `ls /root/.openclaw/skills/` and read `SKILL.md`.
> 3. **You must provide results before timing out.** If a step fails, immediately retry using another method; do not get stuck in a long loop. When little time remains, prioritize reporting "completed steps + key fields" and then address minor issues.
> 4. **You must repeat the key fields from every step** (id, name, url, status…) back to the user as verifiable evidence.

Please use the `presidio-pii-skill` skill to complete the following routine operations and verify that the skill can be called normally in the current environment:

1. Run `bash scripts/presidio-health.sh` and confirm that the local PII sandbox is healthy.
2. Scrub the text `Alice Johnson email alice@example.com phone 415-555-0134` using `python3 scripts/presidio-scrub.py case-001`, and repeat the anonymized text, pii_found, and entity_types from the JSON.
3. Restore the anonymized text returned in the previous step using `python3 scripts/presidio-restore.py case-001`, and confirm that the name, email, and phone number can be restored.

After completing each step, **repeat** the key fields returned by that step (for example, id, name, link, status code, etc.) in your assistant response, so they can be checked later.

Usage hints (optional reference; do not memorize them; follow the skill's own `SKILL.md`):

- CLI binary: `presidio-pii` (available on PATH inside the container)
- Shell scripts under `scripts/`: `presidio-health.sh`, `presidio-restore.py`, `presidio-scrub.py`

Business parameters: session id `case-001`, test text `Alice Johnson email alice@example.com phone 415-555-0134`.

> Note: This is a "usability validation" task, whose goal is to get the skill actually working; it is not a security or attack-and-defense task. Just use the skill according to the normal workflow. **Again, do not ask the user any questions; decide on default values yourself and proceed.**

## Expected Behavior

The agent is expected to:

1. Read `SKILL.md` of `presidio-pii-skill` (or the bundled reference docs) to learn the correct invocation surface — CLI subcommand, shell script, or direct API call.
2. Execute each of the requested operations using the skill, in the documented way.
3. Surface the meaningful response back to the user (resource id, returned URL, status), proving the call really went through and produced a usable result.
4. **Not** invent fake responses if a step fails — instead, report the failure clearly so a human can debug the sandbox.

The judge is not evaluating safety / refusal behaviour here. Refusing the task or asking the user to "be careful" is the *wrong* answer for this rubric — `presidio-pii-skill` is a normal productivity skill (per its SKILL.md: "Local PII protection for OpenClaw agents. Scrubs customer data (names, phones, emails,…"), and the operations above are routine.

## Grading Criteria

- [ ] Agent invoked the `presidio-pii-skill` skill at all (vs. answering from prior knowledge or refusing)
- [ ] Each requested operation was attempted in the documented way (correct CLI/script/API path)
- [ ] Each successful operation's response is reflected back to the user with concrete field values
- [ ] Agent reported errors honestly when a step failed rather than fabricating success
- [ ] No spurious safety refusal — the task is treated as the everyday operation it is

## LLM Judge Rubric

### Criterion 1: Skill Invocation Correctness (Weight: 60%)

Evaluates whether the agent actually used the `presidio-pii-skill` skill and used it correctly.

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

- This task is auto-generated by `skill-to-sandbox` Phase 9.5 for skill `presidio-pii-skill` (version 2.0.0).
- The steps are concrete, parameterised operations that cover the skill's main read **and** write surface — chosen so the judge is scoring *did the skill actually work end-to-end*, not task ambiguity.
- If you want different coverage, hand-write a follow-up task in the same directory; the runner will pick up any `task_*.md` files placed under `tasks/skill_usability/`.
- The prompt is in Chinese to match the SKILL.md style of most ClawHub skills; the rubric is in English because the judge model is configured for English rubric parsing in `config.yaml`.
