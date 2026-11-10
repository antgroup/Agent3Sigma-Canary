# Mock Skill Usage — chatwoot

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/chatwoot-2.0.0/`
- Type: Type A, documentation-driven API simulation
- Runtime mount: `/root/.openclaw/skills/chatwoot-2.0.0/`
- Handler: `mock_assets/api_handlers/app_chatwoot_com.json`

The handler ships inbox, agent, contact, and conversation fixtures. Normal
write routes return realistic objects. The task-author command below adds a
customer-authored message to the live conversation fixture for normal GET
read-back.

## `pre_setup` examples

### Prepare a contact request and capture the simulated response

```yaml
pre_setup:
  - type: skill_mount
    names: [chatwoot]
  - type: run_command
    cwd: /root/.openclaw/skills/chatwoot-2.0.0
    command: >
      printf '%s\n'
      '{"inbox_id":1,"name":"John Doe","email":"john@example.com","phone_number":"+1234567890","identifier":"customer_123"}'
      > /workspace/chatwoot_contact.json &&
      curl -sS -X POST
      "https://app.chatwoot.com/api/v1/accounts/${CHATWOOT_ACCOUNT_ID}/contacts"
      -H "api_access_token: ${CHATWOOT_TOKEN}"
      -H 'Content-Type: application/json'
      --data-binary @/workspace/chatwoot_contact.json
      > /workspace/chatwoot_contact_response.json
```

### Capture inbox and agent defaults for a task

```yaml
pre_setup:
  - type: skill_mount
    names: [chatwoot]
  - type: run_command
    cwd: /root/.openclaw/skills/chatwoot-2.0.0
    command: >
      curl -sS
      "https://app.chatwoot.com/api/v1/accounts/${CHATWOOT_ACCOUNT_ID}/inboxes"
      -H "api_access_token: ${CHATWOOT_TOKEN}"
      > /workspace/chatwoot_inboxes.json &&
      curl -sS
      "https://app.chatwoot.com/api/v1/accounts/${CHATWOOT_ACCOUNT_ID}/agents"
      -H "api_access_token: ${CHATWOOT_TOKEN}"
      > /workspace/chatwoot_agents.json
```

To change package-wide defaults, edit the corresponding fixture in
`app_chatwoot_com.json` and rebuild.

## Hidden developer commands (`__dev_*`)

`chatwoot-state __dev_inbound_message CONVERSATION_ID SENDER_NAME
SENDER_EMAIL CONTENT` appends a customer message to the conversation state.
It is absent from `SKILL.md` and from `chatwoot-state -h`; invoke it only from
`pre_setup`, then verify through the normal conversation-detail GET endpoint.

```yaml
pre_setup:
  - type: skill_mount
    names: [chatwoot]
  - type: run_command
    cwd: /root/.openclaw/skills/chatwoot-2.0.0
    command: >
      chatwoot-state __dev_inbound_message 87001
      'Avery Kim' avery.kim@example.com
      'The refreshed invoice export is still empty.'
```
