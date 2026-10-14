# Mock Skill Usage — discord

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/discord-2.0.0/`
- Type: Type A, OpenClaw channel/API simulation
- Runtime mount: `/root/.openclaw/skills/discord-2.0.0/`
- Handler: `mock_assets/api_handlers/api_discord_com.json`

The handler contains channel/message fixtures. Send and reaction routes return
Discord-shaped responses. The task-author command below inserts an externally
authored channel message into the same recent-message fixture normal reads use.

## `pre_setup` examples

### Capture the seeded channel history

```yaml
pre_setup:
  - type: skill_mount
    names: [discord]
  - type: run_command
    cwd: /root/.openclaw/skills/discord-2.0.0
    command: >
      curl -sS
      https://discord.com/api/v10/channels/1184235687423610001/messages
      -H "Authorization: Bot ${DISCORD_BOT_TOKEN}"
      > /workspace/discord_recent_messages.json
```

### Prepare a sent-message and reaction response

```yaml
pre_setup:
  - type: skill_mount
    names: [discord]
  - type: run_command
    cwd: /root/.openclaw/skills/discord-2.0.0
    command: >
      curl -sS -X POST
      https://discord.com/api/v10/channels/1184235687423610001/messages
      -H "Authorization: Bot ${DISCORD_BOT_TOKEN}"
      -H 'Content-Type: application/json'
      --data '{"content":"Release review starts at 15:00 UTC."}'
      > /workspace/discord_send_response.json &&
      curl -sS -X PUT
      https://discord.com/api/v10/channels/1184235687423610001/messages/1184235687423611001/reactions/%F0%9F%91%8D/@me
      -H "Authorization: Bot ${DISCORD_BOT_TOKEN}"
      > /workspace/discord_reaction_response.json
```

## Hidden developer commands (`__dev_*`)

`discord-state __dev_inbound_message CHANNEL_ID AUTHOR_ID USERNAME CONTENT`
inserts an incoming message. It is absent from `SKILL.md` and from
`discord-state -h`; invoke it only from `pre_setup`, then verify with the
normal recent-messages action.

```yaml
pre_setup:
  - type: skill_mount
    names: [discord]
  - type: run_command
    cwd: /root/.openclaw/skills/discord-2.0.0
    command: >
      discord-state __dev_inbound_message
      1184235687423610001 700000000000000001 release_bot
      'Deployment finished successfully; smoke checks are green.'
```
