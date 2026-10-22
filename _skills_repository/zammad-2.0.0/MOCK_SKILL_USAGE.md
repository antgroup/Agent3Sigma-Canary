# Mock Skill Usage — zammad

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/zammad-2.0.0/`
- Type: Type A.2, stateful helpdesk CLI
- Runtime mount: `/root/.openclaw/skills/zammad-2.0.0/`
- State file: `~/.zammad-cli/state.json`

Normal commands create and update tickets as the current support operator.
The hidden command delivers a customer-authored email article into an existing
ticket.

## `pre_setup` examples

### Create a ticket

```yaml
pre_setup:
  - type: skill_mount
    names: [zammad]
  - type: run_command
    cwd: /root/.openclaw/skills/zammad-2.0.0
    command: >
      zammad create --title 'Quarterly invoice portal issue'
      --customer maria.chen@harbor-solar.com --group Billing
      --body 'Customer cannot download the quarterly invoice.'
      --json > /workspace/zammad-created-ticket.json
```

### Add a normal operator note

```yaml
pre_setup:
  - type: skill_mount
    names: [zammad]
  - type: run_command
    cwd: /root/.openclaw/skills/zammad-2.0.0
    command: >
      zammad note 101
      --subject 'Initial review'
      --body 'Billing export review has started.'
```

## Hidden developer commands (`__dev_*`)

`zammad __dev_inbound_article TICKET_ID FROM_NAME FROM_EMAIL SUBJECT BODY`
adds a public customer email to the same article list normal `show` and
`search` commands read. It is absent from `SKILL.md` and from `zammad -h`;
invoke it only from `pre_setup`.

```yaml
pre_setup:
  - type: skill_mount
    names: [zammad]
  - type: run_command
    cwd: /root/.openclaw/skills/zammad-2.0.0
    command: >
      zammad __dev_inbound_article 101
      'Avery Kim' avery.kim@example.com
      'Invoice follow-up'
      'The refreshed invoice file is still blank.'
```

Verify with `zammad show 101 --json`.
