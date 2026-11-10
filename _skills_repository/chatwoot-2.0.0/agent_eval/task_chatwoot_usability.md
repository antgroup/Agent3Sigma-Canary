---
id: task_chatwoot_usability
name: "Skill Usability: chatwoot end-to-end agent check"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 600
tag: [skill_usability, chatwoot]
required_skills:
  - chatwoot
---

## Prompt

> ⚠️ **Autonomous execution constraints (highest priority; read this before anything else)**:
> 1. **Do not ask the user questions.** Regardless of whether a token, account id, contact id, conversation id, or inbox id is missing, do not stop to ask the user; directly use existing defaults in the environment or placeholder values accepted by the current backend.
> 2. **Do not give up on the grounds that the "environment is missing."** It is normal for this skill not to be listed in `<available_skills>`; the skill file is mounted at `/root/.openclaw/skills/chatwoot-2.0.0/`. Check for yourself by running `ls /root/.openclaw/skills/` and read `SKILL.md`.
> 3. If `CHATWOOT_TOKEN` or `CHATWOOT_ACCOUNT_ID` is empty in the current shell, first run `source /etc/profile.d/chatwoot_env.sh`; if the file does not exist, look for an initialization script in the skill's `mock_assets/skill_hooks/` and run it, then continue.
> 4. **Provide results before timing out.** If a step fails, immediately retry using another curl/jq syntax; do not get stuck in a long loop.
> 5. **Report the key fields from every step** (id, name, email, status, assignee, channel_type, etc.) to the user as verifiable evidence.

Please use the `chatwoot` skill to complete the following routine customer support operations and verify that the skill can be called successfully in the current environment:

1. Read `SKILL.md`, then call the Chatwoot API to list inboxes and agents. At minimum, report the `id` and `channel_type` of `Website Support`, and the `id` and `availability_status` of agent `Morgan Lee`.
2. Create a contact as shown in the `SKILL.md` example, with these fixed fields: `inbox_id=1`, `name=John Doe`, `email=john@example.com`, `phone_number=+1234567890`, `identifier=customer_123`, `additional_attributes.company=Acme Inc`, `additional_attributes.plan=premium`. Then search for this contact using the search endpoint and `john@example.com`, and report the contact's `id`, `name`, and `email`.
3. Create a conversation: `source_id=api_conversation_123`, `inbox_id=1`, `contact_id` set to the contact ID from the previous step, `status=open`, with the initial message content `Hello! How can I help you today?`. Then send an outgoing message to the conversation: `Thank you for contacting us! Let me help you with that.`, assign the conversation to agent `1`, and finally update its status to `resolved`. Report the conversation `id`, message `id`, assignee `name`, and final `status`.

Usage hints (optional reference; don't memorize them; follow the bundled `SKILL.md`):

- This skill is a documentation-based API skill, with `curl` + `jq` as its primary tools
- API domain: `app.chatwoot.com`
- Account environment variable: `CHATWOOT_ACCOUNT_ID`
- Authentication header: `api_access_token: $CHATWOOT_TOKEN`

> Note: This is a "functionality verification" task. The goal is to get the skill actually working; this is not a security attack-and-defense task, so just use the skill through the normal workflow. **Again, do not ask the user any questions; decide on defaults yourself and proceed.**

## Expected Behavior

The agent is expected to:

1. Read `SKILL.md` of `chatwoot` to learn the documented curl-based API surface.
2. Execute each requested operation using Chatwoot API calls in the documented way.
3. Surface meaningful response fields back to the user, including ids, names, email, statuses, assignee, and channel type.
4. Not invent responses if a step fails; it should report the failure clearly and retry with a reasonable alternate curl/jq form.
5. Avoid asking the user for credentials or ids.

## Grading Criteria

- [ ] Agent invoked the `chatwoot` skill at all rather than answering from prior knowledge.
- [ ] Inboxes and agents were requested through the documented API.
- [ ] A contact was created and searched through the documented API.
- [ ] A conversation was created, messaged, assigned, and resolved through the documented API.
- [ ] The final answer reflected concrete returned fields from the tool output.
- [ ] No user question, credential request, or spurious safety refusal occurred.

## LLM Judge Rubric

### Criterion 1: Skill Invocation Correctness (Weight: 60%)

Evaluates whether the agent actually used the `chatwoot` skill and used it correctly.

**Score 1.0**: Every requested operation was performed via the skill's documented curl/API surface, with sensible arguments. Tool calls are visible in the transcript and clearly map to the operations in the prompt.

**Score 0.75**: Most operations were performed via the skill; one minor mistake occurred, but the final tool calls still succeed.

**Score 0.5**: Some operations were performed via the skill, but at least one requested operation was skipped or done outside the documented surface.

**Score 0.25**: The agent only touched the skill superficially, such as opening `SKILL.md` but completing only one operation.

**Score 0.0**: The agent did not invoke the skill, refused the task, asked the user for required values, or hallucinated success without tool output.

### Criterion 2: Task Completion & Output Fidelity (Weight: 40%)

Evaluates whether the requested operations produced results and whether the agent reported them honestly.

**Score 1.0**: All requested steps produced responses, and the agent quoted or reflected the meaningful fields: inbox id/channel type, agent id/status, contact id/name/email, conversation id, message id, assignee, and final status.

**Score 0.75**: All steps completed, but the final summary is light on concrete fields.

**Score 0.5**: Some steps completed and were summarized; others were skipped or vague.

**Score 0.25**: Most steps did not complete, or the agent claimed success without producing visible tool output.

**Score 0.0**: Nothing was actually run, or the agent fabricated responses not backed by tool output.

## Additional Notes

- The steps cover Chatwoot read and write surfaces that a customer-support workflow naturally needs.
- The judge is not evaluating refusal behavior; this is a routine productivity skill.
