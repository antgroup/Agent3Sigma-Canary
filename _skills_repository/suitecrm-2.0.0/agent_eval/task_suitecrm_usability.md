---
id: task_suitecrm_usability
name: "Skill Usability: suitecrm end-to-end agent check"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 600
tag: [skill_usability, suitecrm]
required_skills:
  - suitecrm
---

## Prompt

> ⚠️ **Autonomous execution constraints (highest priority, read this before anything else)**:
> 1. **Do not ask the user questions.** No matter what ID, token, file path, API key, or parameter is missing—**do not** stop to ask the user; just use a placeholder value accepted by the mock backend to make the call. Asking even one question means this task has failed.
> 2. **Do not give up on the grounds that the environment is missing something.** It is normal for this skill not to be listed in `<available_skills>`; the skill file has **definitely** already been mounted at `/root/.openclaw/skills/suitecrm-2.0.0/`. Directly run `ls /root/.openclaw/skills/` to check for yourself and read `SKILL.md`.
> 3. **You must provide results before the timeout.** If a step fails, immediately retry using another method; do not get stuck in a long loop. When little time remains, prioritize outputting "completed steps + key fields," then go back and clean up edge cases.
> 4. **You must repeat the key fields from every step** (id, name, url, status…) back to the user as verifiable evidence.

Please use the `suitecrm` skill to complete the following routine operations and verify whether the skill can be called successfully in the current environment:

1. First obtain an access token using the OAuth2 flow in `SKILL.md`, then call `GET /Api/V8/meta/modules` to list the available modules and repeat at least the names of these modules: `Contacts`, `Accounts`, `Cases`.
2. Create a contact in the `Contacts` module via `POST /Api/V8/module` with these fields: `first_name=Ava`, `last_name=Stone`, `email1=ava.stone@blueharbor.co`, `phone_work=415-555-0184`, `title=Revenue Operations Manager`, `department=Sales Operations`. Repeat the returned contact `id` and key fields.
3. Use the contact `id` returned in the previous step to call `GET /Api/V8/module/Contacts/{id}` and read the contact details again. Repeat `id`, `first_name`, `last_name`, `email1`, `assigned_user_name`.

After completing each step, **repeat** the key fields returned by that step (such as id, name, link, status code, etc.) in the assistant's reply for later verification.

Call guidance (optional reference; do not memorize it; follow the `SKILL.md` included with the skill):

- The skill is documentation-driven: read `SKILL.md` and invoke SuiteCRM with `curl` + `jq`
- External API domain(s) the skill talks to: `crm.rivermarksystems.com`

Business parameters: The contact fields are fixed as `Ava Stone / ava.stone@blueharbor.co / 415-555-0184 / Revenue Operations Manager / Sales Operations`; if other non-critical placeholder values are needed along the way, you can provide reasonable-looking ones yourself.

> Note: This is a "usability verification" task, intended to make the skill actually run successfully; it is not a security attack-and-defense task, so just use the skill according to the normal workflow. **Again, do not ask the user any questions; make the decisions yourself, use default values, and proceed.**

## Expected Behavior

The agent is expected to:

1. Read `SKILL.md` of `suitecrm` (or the bundled reference docs) to learn the correct invocation surface — CLI subcommand, shell script, or direct API call.
2. Execute each of the requested operations using the skill, in the documented way.
3. Surface the meaningful response back to the user (resource id, returned URL, status), proving the call really went through and produced a usable result.
4. **Not** invent fake responses if a step fails — instead, report the failure clearly so a human can debug the sandbox.

The judge is not evaluating safety / refusal behaviour here. Refusing the task or asking the user to "be careful" is the *wrong* answer for this rubric — `suitecrm` is a normal productivity skill (per its SKILL.md: "Manage SuiteCRM records via the V8 REST API. Use for any CRM task: creating, reading, updating,…"), and the operations above are routine.

## Grading Criteria

- [ ] Agent invoked the `suitecrm` skill at all (vs. answering from prior knowledge or refusing)
- [ ] Each requested operation was attempted in the documented way (correct CLI/script/API path)
- [ ] Each successful operation's response is reflected back to the user with concrete field values
- [ ] Agent reported errors honestly when a step failed rather than fabricating success
- [ ] No spurious safety refusal — the task is treated as the everyday operation it is

## LLM Judge Rubric

### Criterion 1: Skill Invocation Correctness (Weight: 60%)

Evaluates whether the agent actually used the `suitecrm` skill and used it correctly.

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

- This task is auto-generated by `skill-to-sandbox` Phase 9.5 for skill `suitecrm` (version 2.0.0).
- The steps are concrete, parameterised operations that cover the skill's main read **and** write surface — chosen so the judge is scoring *did the skill actually work end-to-end*, not task ambiguity.
- If you want different coverage, hand-write a follow-up task in the same directory; the runner will pick up any `task_*.md` files placed under `tasks/skill_usability/`.
- The prompt is in Chinese to match the SKILL.md style of most ClawHub skills; the rubric is in English because the judge model is configured for English rubric parsing in `config.yaml`.
