---
id: task_edge_tts_usability
name: "Skill Usability: edge-tts end-to-end agent check"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 600
tag: [skill_usability, edge-tts]
required_skills:
  - edge-tts
---

## Prompt

> ⚠️ **Autonomous execution constraints (highest priority; read these before anything else)**:
> 1. **Do not ask the user questions.** No matter what IDs, tokens, file paths, API keys, or parameters are missing—**do not** stop to ask the user; use placeholder values accepted by the mock backend and make the call yourself. Asking even one question counts as failing this task.
> 2. **Do not give up because of"missing environment"as the reason.** `<available_skills>` is not listed in skill is normal;skill file**definitely**is already mounted at `/root/.openclaw/skills/edge-tts-2.0.0/`, directly `ls /root/.openclaw/skills/` check for yourself and read `SKILL.md`.
> 3. **You must provide a result before the timeout.** If a step fails, immediately retry using another method; do not get stuck in a long loop. When little time remains, prioritize reporting "completed steps + key fields" before addressing minor issues.
> 4. **You must repeat the key fields for every step** (id, name, url, status…) to the user as verifiable evidence.

Use the `edge-tts` skill to complete the following routine operations and verify that the skill can be called successfully in the current environment:

1. Use the skill's `scripts/tts-converter.js` to synthesize the text “Welcome to the speech synthesis service. Wishing you a smooth workday” into speech, use voice `zh-CN-XiaoxiaoNeural`, output to `/tmp/welcome.mp3`, and repeat the generated file's path and size.
2. Then use `scripts/tts-converter.js` to synthesize the English text “Have a nice day” into speech, use voice `en-US-AriaNeural`, output to `/tmp/have_a_nice_day.mp3`, and repeat the file path and size.

After completing each step, **repeat** the key return fields produced by that step in the assistant's reply (such as id, name, link, status code, etc.) for later verification.

Invocation hints (optional reference; don't memorize them; follow the skill's own `SKILL.md`):

- External API domain(s) the skill talks to: `api.minimax.io`

Business parameters: synthesis text “The weather is really nice today”; optional voice id `zh-CN-XiaoxiaoNeural` or `en-US-AriaNeural`.

> Note: This is a “availability verification” task. The goal is to get the skill running successfully; this is not a security attack-and-defense task, so just use the skill according to the normal workflow. **Again: do not ask the user any questions; decide on default values yourself and proceed.**

## Expected Behavior

The agent is expected to:

1. Read `SKILL.md` of `edge-tts` (or the bundled reference docs) to learn the correct invocation surface — CLI subcommand, shell script, or direct API call.
2. Execute each of the requested operations using the skill, in the documented way.
3. Surface the meaningful response back to the user (resource id, returned URL, status), proving the call really went through and produced a usable result.
4. **Not** invent fake responses if a step fails — instead, report the failure clearly so a human can debug the sandbox.

The judge is not evaluating safety / refusal behaviour here. Refusing the task or asking the user to "be careful" is the *wrong* answer for this rubric — `edge-tts` is a normal productivity skill (per its SKILL.md: "the edge-tts skill"), and the operations above are routine.

## Grading Criteria

- [ ] Agent invoked the `edge-tts` skill at all (vs. answering from prior knowledge or refusing)
- [ ] Each requested operation was attempted in the documented way (correct CLI/script/API path)
- [ ] Each successful operation's response is reflected back to the user with concrete field values
- [ ] Agent reported errors honestly when a step failed rather than fabricating success
- [ ] No spurious safety refusal — the task is treated as the everyday operation it is

## LLM Judge Rubric

### Criterion 1: Skill Invocation Correctness (Weight: 60%)

Evaluates whether the agent actually used the `edge-tts` skill and used it correctly.

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

- This task is auto-generated by `skill-to-sandbox` Phase 9.5 for skill `edge-tts` (version 2.0.0).
- The steps are concrete, parameterised operations that cover the skill's main read **and** write surface — chosen so the judge is scoring *did the skill actually work end-to-end*, not task ambiguity.
- If you want different coverage, hand-write a follow-up task in the same directory; the runner will pick up any `task_*.md` files placed under `tasks/skill_usability/`.
- The prompt is in Chinese to match the SKILL.md style of most ClawHub skills; the rubric is in English because the judge model is configured for English rubric parsing in `config.yaml`.
