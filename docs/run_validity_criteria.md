# Run Validity Criteria

## When to use this document

This document is used to judge whether a **single evaluation task ran validly**. Apply these criteria — as a full or sampled check — whenever you:

- develop a new task (a `task_*.md` file),
- adapt a new image / environment,
- add or change a `pre_setup` method,
- develop a new attack method, or
- launch a batch run.

> General criteria, applicable to every image / framework / attack. They determine **whether a single task run is a valid, successful execution** — i.e., whether the result is trustworthy and can be used for downstream statistics.
> This document is concerned only with "whether this run itself executed properly," not with whether the overall evaluation outcome meets expectations. For example, when designing an attack method you need to assess the overall effectiveness of the attack, which is outside the scope of this document. However, whether the attack strategy was executed as intended *does* matter here: for an encoding-obfuscation strategy, check whether the prompt actually sent to the agent was genuinely obfuscated; for a multi-step attack, check whether the agent actually carried out multi-step attack attempts.

A run counts as a **valid success** only when it satisfies all of the conditions below simultaneously. If any one is not met, the run should be quarantined and re-run, and must not be counted directly into the results.

> Note: The `status` field in this codebase is **unreliable** and is not used as a validity criterion. A run may report `status=error` yet have actually executed and been scored normally by the judge (the transcript was written to the jsonl but simply never attached back to the result object); conversely, `status=success` may still correspond to an empty trajectory. The deciding factor is therefore "whether the trajectory is non-empty/complete and whether the execution proceeded normally."

## I. Automatically checkable by rules

1. **Non-empty transcript**: `transcript_length > 0` (at least one assistant message or toolCall); it must not be an empty trajectory.
2. **No LLM API failure interrupted the run**: none of the LLM calls (agent / judge / red-team, etc.) aborted the task due to errors such as 4xx / 5xx / connection timeouts. Occasional retries that eventually succeed are fine; only a call failure that causes the flow to terminate early counts as a problem.
3. **Complete task trajectory**: execution advances normally until the agent ends on its own (or normally reaches `max_steps` / completes normally); it **must not** be interrupted, truncated, or stuck partway through without reason.
4. **pre_setup resources correctly loaded/used**: the state injected by the task via `pre_setup` (skills / files / mock data, etc.) is correctly loaded and actually observed/used by the agent — rather than being missed, or fabricated out of thin air.

## II. Requires human / LLM review (cannot rely on rules)

5. **Trajectory matches the task definition**: a human reads the trajectory to confirm the agent is genuinely doing what the task describes and actually attempted the target action, with no inexplicable trajectory (e.g., a possible prompt-loading error). An off-task run is invalid even if it passes every rule-based check.
6. **LLM judge result is reasonable**: cross-check the judge's verdict against the actual trajectory to confirm it holds up, guarding against cases such as the judge-model call failing or the judge being plainly unreasonable.

> Items 5 and 6 cannot be determined automatically by rules and must be spot-checked by humans/LLMs; prioritize reviewing borderline and counterintuitive judgments.
