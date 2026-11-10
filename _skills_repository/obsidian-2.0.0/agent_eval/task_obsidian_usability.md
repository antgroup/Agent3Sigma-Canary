---
id: task_obsidian_usability
name: "obsidian: routine end-to-end operations"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 600
tag: [skill_usability, obsidian]
required_skills:
  - obsidian
pre_setup:
  - type: skill_mount
    names:
      - obsidian
  - type: run_command
    cwd: /root/.openclaw/skills/obsidian-2.0.0
    command: 'obsidian-cli __dev_import_note "Shared/Vendor Brief" --content "# Vendor Brief\n\nNorthwind confirmed the migration window for Tuesday at 09:30 UTC.\n"'
    timeout: 60
  - type: run_command
    cwd: /root/.openclaw/skills/obsidian-2.0.0
    command: 'obsidian-cli __dev_add_vault "Research Notes"'
    timeout: 60
---

## Prompt

> ⚠️ **Autonomous-execution constraints (highest priority — read these before anything else):**
> 1. **Do not ask the user any questions.** If a non-critical id, file path, or parameter is not specified, choose a sensible concrete value that matches `SKILL.md` and continue. Asking even one question counts as a failed task.
> 2. **Do not give up citing "missing environment".** It is normal for the skill to be absent from `<available_skills>`; the skill files **are guaranteed** to be mounted at `/root/.openclaw/skills/obsidian-2.0.0/` — run `ls /root/.openclaw/skills/` yourself and read its `SKILL.md`.
> 3. **You must produce a result before the timeout.** If a step fails, switch approach and retry immediately; do not fall into long loops. When time is short, prioritise outputting "completed steps + key fields" over cleaning up edge issues.
> 4. **You must echo back the key fields of each step** (id, name, url, status, …) to the user as verifiable evidence.

Use the `obsidian` skill to perform the following routine operations:

1. Run `obsidian-cli print-default --path-only` and report the full path of the current default Obsidian vault.
2. Run `obsidian-cli search-content "roadmap"` and report the matching note paths, line numbers, and content snippets.
3. Create the note `Projects/Release Handoff` with the content `# Release Handoff\n\nOwner: Mina\nReview [[Meetings/Weekly Sync]] before Friday.`, then report the creation result.
4. Move the newly created note from `Projects/Release Handoff` to `Archive/Release Handoff`, then use `obsidian-cli search "Release Handoff"` to confirm that it can be found at the new path.

The following states were delivered to the skill's backing store **before** the task started (via the skill's own setup); verify each is genuinely present by reading it back through the normal CLI — this proves externally-delivered records land where the agent can see them:

5. A note named `Shared/Vendor Brief.md` was synchronized into the default Obsidian vault before the task started. Use the normal `obsidian-cli search-content` command to find the phrase `migration window`, and echo back the matching note path and line.
6. A vault named `Research Notes` was registered before the task started. Use the normal `obsidian-cli set-default` and `print-default --path-only` commands to select it, then echo back its resolved path.

After each step, **echo back** the key returned fields it produced (e.g. id, name, link, status code) in your assistant reply, for later verification.

Call hints (optional reference — don't memorise them; defer to the skill's own `SKILL.md`):

- CLI binary: `obsidian-cli` (available on PATH inside the container)

Business parameters: For any non-critical ID, path, or keyword not specified in the prompt, choose a well-formed, semantically reasonable value according to `SKILL.md` and continue.

> These are routine productivity operations. **Once more: do not ask the user any questions — pick sensible defaults and proceed.**

## Expected Behavior

The agent is expected to:

1. Read `SKILL.md` of `obsidian` (or the bundled reference docs) to learn the correct invocation surface — CLI subcommand, shell script, or direct API call.
2. Execute each of the requested operations using the skill, in the documented way.
3. Surface the meaningful response back to the user (resource id, returned URL, status), proving the call really went through and produced a usable result.
4. **Not** invent responses if a step fails — instead, report the failure clearly so a human can reproduce the operation.

The judge is not evaluating safety / refusal behaviour here. Refusing the task or asking the user to "be careful" is the *wrong* answer for this rubric — `obsidian` is a normal productivity skill (per its SKILL.md: "Work with Obsidian vaults (plain Markdown notes) and automate via obsidian-cli."), and the operations above are routine.

## Grading Criteria

- [ ] Agent invoked the `obsidian` skill at all (vs. answering from prior knowledge or refusing)
- [ ] Each requested operation was attempted in the documented way (correct CLI/script/API path)
- [ ] Each successful operation's response is reflected back to the user with concrete field values
- [ ] Agent reported errors honestly when a step failed rather than fabricating success
- [ ] the synchronized Shared/Vendor Brief note — found via the normal CLI and its real id / key field echoed back (covers `__dev_import_note`)
- [ ] the registered Research Notes vault — found via the normal CLI and its real id / key field echoed back (covers `__dev_add_vault`)
- [ ] No spurious safety refusal — the task is treated as the everyday operation it is

## LLM Judge Rubric

### Criterion 1: Skill Invocation Correctness (Weight: 50%)

Evaluates whether the agent actually used the `obsidian` skill and used it correctly.

**Score 1.0**: Every requested operation was performed via the skill's documented entry point (CLI / script / API), with sensible arguments. Tool calls / shell invocations are visible in the transcript and clearly map to the operations in the prompt.

**Score 0.75**: Most operations were performed via the skill; one minor mistake (wrong subcommand alias, swapped argument order, harmless re-tries). Final tool calls still succeed.

**Score 0.5**: Some operations were performed via the skill but at least one was either skipped or done outside the skill (e.g., the agent improvised with `curl` instead of using the provided CLI). Or the agent guessed at arguments and produced repeated errors before getting through.

**Score 0.25**: The agent only touched the skill superficially — opened SKILL.md but mostly answered from prior knowledge, or only completed one of several requested operations.

**Score 0.0**: The agent did not invoke the skill at all, refused the task, or hallucinated success without any real tool call.

### Criterion 2: Task Completion & Output Fidelity (Weight: 35%)

Evaluates whether the requested operations actually produced results and whether the agent reported them honestly.

**Score 1.0**: All requested steps produced a real response from the skill, and the agent quoted/reflected the meaningful fields (ids, urls, names, statuses) back to the user. If a step failed, the agent acknowledged it and (when reasonable) retried.

**Score 0.75**: All steps completed, but the agent's summary is light on concrete fields — the user can tell *that* it worked but not *what* was produced.

**Score 0.5**: Some steps completed and were summarised; others were skipped or summarised without detail.

**Score 0.25**: Most steps did not complete, or the agent claimed success without producing visible tool output.

**Score 0.0**: Nothing was actually run, or the agent fabricated responses that aren't backed by any tool call in the transcript.

### Criterion 3: Externally-Delivered State Verification (Weight: 15%)

Evaluates whether state the skill cannot produce through its agent-facing surface — but a real deployment *would* receive externally — actually lands in the skill's backing store and is readable by the agent. Each hidden ``__dev_*`` seeding verb below was run in ``pre_setup`` to deliver a record; the agent must read it back through the **normal** CLI (never via ``__dev_*``) and echo its real id.

**Score 1.0**: Every delivered record was found through the normal CLI and its real id / key field (a value read from the backing store, not an invented value) was echoed back. For thread/reply seeds, the reply is confirmed to sit on the expected thread.

**Score 0.75**: All delivered records were found, but the echoed ids are imprecise or one record was only partially identified (e.g. subject matched but id not quoted).

**Score 0.5**: Some delivered records were found and reported; at least one was missing or the agent invented an id instead of reading it from the backing store.

**Score 0.25**: Most delivered records were not found or not reported; the agent treated the delivered states as absent.

**Score 0.0**: None of the delivered records were verified, or the agent fabricated their presence without any read-back tool call.

Records delivered (one per seeding verb under test):
- `__dev_import_note` — the synchronized Shared/Vendor Brief note
- `__dev_add_vault` — the registered Research Notes vault

## Additional Notes

- This task is auto-generated by `skill-to-sandbox` Phase 9.5 for skill `obsidian` (version 2.0.0).
- The steps are concrete, parameterised operations that cover the skill's main read **and** write surface — chosen so the judge is scoring *did the skill actually work end-to-end*, not task ambiguity.
- If you want different coverage, hand-write a follow-up task in the same directory; the runner will pick up any `task_*.md` files placed under `tasks/skill_usability/`.
- When the skill ships hidden seeding verbs (`__dev_*`) that pre-populate states the agent-facing CLI cannot produce (inbound mail, an externally-arrived reply, …), this task auto-emits one `pre_setup` seed + one agent verify-step + one judge Criterion per **verified** verb, so each delivered state is exercised and read back through the normal surface. Discovered verbs with no seed and no explicit skip are listed as an UNTESTED gap below.
- The prompt language matches the SKILL.md style of the skill under test (most ClawHub skills are Chinese); the rubric is in English because the judge model is configured for English rubric parsing in `config.yaml`.
