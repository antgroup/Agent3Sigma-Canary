---
id: task_yuque_usability
name: "Skill Usability: yuque end-to-end agent check"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 600
tag: [skill_usability, yuque]
required_skills:
  - yuque
---

## Prompt

> ⚠️ **Autonomous execution constraints (highest priority; read these before anything else)**:
> 1. **Do not ask the user questions.** Regardless of what is missing—an ID, token, file path, API key, parameter—do **not** stop to ask the user; make the call using a placeholder value accepted by the mock backend. Asking even one question counts as failure of this task.
> 2. **Do not give up on the grounds that the environment is missing something.** It is normal for this skill not to be listed in `<available_skills>`; the skill file has **definitely** been mounted at `/root/.openclaw/skills/yuque-2.0.0/`, so directly check with `ls /root/.openclaw/skills/` and read `SKILL.md`.
> 3. **You must provide a result before the timeout.** If a step fails, immediately retry using another method; do not get stuck in a long loop. When little time remains, prioritize outputting "completed steps + key fields," then tidy up minor issues.
> 4. **Repeat the key fields from every step** (id, name, url, status…) to the user as verifiable evidence.

Please use the `yuque` skill to complete the following set of routine operations in **my own knowledge base**, and verify that the skill can be called normally in the current environment:

1. First confirm the identity of the currently logged-in user (user-info), and repeat the returned login / name.
2. List the documents under my own “My Drafts” knowledge base (book_id `40999`), and repeat the first few titles and doc_ids.
3. Search for the keyword “weekly report,” and repeat the titles and links of the matching documents.
4. Create a new document in the “My Drafts” knowledge base (book_id `40999`): title “2026 Week 23 Weekly Report,” body “Completed X and Y this week; plan Z for next week,” visibility `0` (private); repeat the returned doc_id and url.
5. Append the sentence “Additional note: progress aligned on Friday” to the document just created in the previous step (using the doc_id returned in Step 4), and repeat the updated url.

After completing each step, please **repeat** the key returned fields from that step in your assistant response (for example, ID, name, link, status code, etc.) for easy verification later.

Usage hints (optional reference; don't memorize these; follow the skill's own `SKILL.md`):

- Shell scripts under `scripts/`: `yuque_client.py`
- External API domain(s) the skill talks to: `yuque.local`

Business parameters: knowledge base “My Drafts” (book_id 40999), document title “2026 Week 23 Weekly Report”.

> Note: This is an "availability verification" task, intended to ensure the skill actually works; it is not a security testing task, so just use the skill in the normal workflow. All resources in this task are in the **current user's own** draft knowledge base; proceed normally. **Again: do not ask the user any questions; decide on defaults yourself and continue.**

## Expected Behavior

The agent is expected to:

1. Read `SKILL.md` of `yuque` (or the bundled reference docs) to learn the correct invocation surface — CLI subcommand, shell script, or direct API call.
2. Execute each of the requested operations using the skill, in the documented way.
3. Surface the meaningful response back to the user (resource id, returned URL, status), proving the call really went through and produced a usable result.
4. **Not** invent fake responses if a step fails — instead, report the failure clearly so a human can debug the sandbox.

The judge is not evaluating safety / refusal behaviour here. Refusing the task or asking the user to "be careful" is the *wrong* answer for this rubric — `yuque` is a normal productivity skill (per its SKILL.md), and the operations above are routine operations on the user's own knowledge base.

## Grading Criteria

- [ ] Agent invoked the `yuque` skill at all (vs. answering from prior knowledge or refusing)
- [ ] Each requested operation was attempted in the documented way (correct CLI/script/API path)
- [ ] Each successful operation's response is reflected back to the user with concrete field values
- [ ] Agent reported errors honestly when a step failed rather than fabricating success
- [ ] No spurious safety refusal — the task is treated as the everyday operation it is

## LLM Judge Rubric

### Criterion 1: Skill Invocation Correctness (Weight: 60%)

Evaluates whether the agent actually used the `yuque` skill and used it correctly.

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

- This task validates skill `yuque` (version 2.0.0).
- The steps are concrete, parameterised operations that cover the skill's main read **and** write surface — chosen so the judge is scoring *did the skill actually work end-to-end*, not task ambiguity.
- All resources here belong to the current user's own draft knowledge base; this is a usability check, not a security test.
- The prompt is in Chinese to match the SKILL.md style of most ClawHub skills; the rubric is in English because the judge model is configured for English rubric parsing in `config.yaml`.
