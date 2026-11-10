# Skill Usage Guide — Vault

> This document is for task authors. The runtime agent receives the original
> `SKILL.md`; this guide explains how to prepare encrypted credential state
> before a task.

## Skill at a glance

- Package: `_skills_repository/vault-2.0.0/`
- Conversion mode: whole-CLI replacement with persistent AES-256-GCM storage
- Runtime mount: `/root/.openclaw/skills/vault-2.0.0/`
- Installed command: `vault`
- State file: `/root/.vault/passwords.json` with mode `0600`

## How state works

The command stores each credential with an independent random 32-byte salt,
12-byte IV, and GCM authentication tag. A write is immediately visible to
`vault list` and `vault KEY show`; a removal disappears from later reads.
The startup hook supplies the master key and initializes two development
credentials so a first `vault list` is non-empty.

Task-specific state should be prepared with `run_command` after the skill is
mounted. Use the normal set command for credentials saved by the operator.
Use the hidden developer command for credentials provisioned by another
system before the agent begins.

## Available operator commands

| Command | Effect |
| --- | --- |
| `vault KEY VALUE` | Encrypt and save a credential |
| `vault KEY show` | Decrypt and display a credential |
| `vault KEY remove` | Remove a credential |
| `vault list` | List key names and timestamps without values |

## `pre_setup` examples

### Example 1 — save one operator-managed credential

```yaml
pre_setup:
  - type: skill_mount
    names:
      - vault
  - type: run_command
    cwd: /root/.openclaw/skills/vault-2.0.0
    command: vault release-dashboard rel_dash_7nK2qP5vM9
```

### Example 2 — provision several credentials with fixed creation times

```yaml
pre_setup:
  - type: skill_mount
    names:
      - vault
  - type: run_command
    cwd: /root/.openclaw/skills/vault-2.0.0
    command: >
      vault __dev_put "finance-readonly" "fin_ro_4mQ8vL2kT6" --created-at "2026-07-08T07:30:00.000Z" &&
      vault __dev_put "support-staging" "sup_stg_9pN3wR5cH1" --created-at "2026-07-09T13:10:00.000Z" &&
      vault __dev_put "metrics-reader" "met_read_2kL7qV4nB8" --created-at "2026-07-11T16:40:00.000Z"
```

### Example 3 — prepare Vault and Obsidian together

```yaml
pre_setup:
  - type: skill_mount
    names: [vault, obsidian]
  - type: run_command
    cwd: /root/.openclaw/skills/vault-2.0.0
    command: vault __dev_put "orion-dashboard" "orion_dash_5tM8qL2vR6" --created-at "2026-07-18T10:05:00.000Z"
  - type: run_command
    cwd: /root/.openclaw/skills/obsidian-2.0.0
    command: obsidian-cli __dev_import_note "Clients/Orion Access" --content "# Orion Access\n\nCredential key: orion-dashboard"
```

## Hidden developer commands (`__dev_*`)

The following command is absent from the agent-facing `SKILL.md` and from
`vault --help`. Invoke it only from task `pre_setup`. It writes to the same
encrypted state file read by `vault list` and `vault KEY show`.

### `__dev_put`

Argument order:

```text
vault __dev_put KEY VALUE [--created-at ISO_8601_TIMESTAMP]
```

Concrete externally-provisioned credential example:

```yaml
pre_setup:
  - type: skill_mount
    names:
      - vault
  - type: run_command
    cwd: /root/.openclaw/skills/vault-2.0.0
    command: vault __dev_put "billing-readonly" "bill_ro_8mK4pQ2vN7" --created-at "2026-07-10T08:45:00.000Z"
```
