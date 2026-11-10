# Skill Usage Guide — Obsidian

> This document is for task authors. The runtime agent receives the original
> `SKILL.md`; this guide explains how to prepare Obsidian state before a task.

## Skill at a glance

- Package: `_skills_repository/obsidian-2.0.0/`
- Conversion mode: whole-CLI replacement with persistent Markdown files
- Runtime mount: `/root/.openclaw/skills/obsidian-2.0.0/`
- Installed command: `obsidian-cli`

## How state works

`obsidian-cli` operates on real `*.md` files below the registered vault
directories. The default vault is `Work Notes`, and
`obsidian-cli print-default --path-only` returns its real filesystem path.
Create, move, delete, name search, and content search all use the same files.
Moves also update matching wikilinks and Markdown links in the other notes.

Task-specific state should be prepared with `run_command` after the skill is
mounted. Use normal commands for notes authored by the operator. Use the
hidden developer commands for notes or vault registrations that arrived from
outside the operator-facing workflow.

## Available operator commands

| Command | Example | Effect |
| --- | --- | --- |
| `print-default` | `obsidian-cli print-default --path-only` | Read the default vault |
| `set-default` | `obsidian-cli set-default "Work Notes"` | Select a registered vault |
| `search` | `obsidian-cli search "Roadmap"` | Search note paths and names |
| `search-content` | `obsidian-cli search-content "milestone"` | Search note contents with line numbers |
| `create` | `obsidian-cli create "Projects/Kickoff" --content "# Kickoff"` | Create a Markdown note |
| `move` | `obsidian-cli move "Projects/Kickoff" "Archive/Kickoff"` | Move a note and update links |
| `delete` | `obsidian-cli delete "Archive/Kickoff"` | Delete a note |

## `pre_setup` examples

### Example 1 — prepare an operator-authored planning note

```yaml
pre_setup:
  - type: skill_mount
    names:
      - obsidian
  - type: run_command
    cwd: /root/.openclaw/skills/obsidian-2.0.0
    command: obsidian-cli create "Projects/Q4 Planning" --content "# Q4 Planning\n\nReview budget on Thursday."
```

### Example 2 — register a vault and synchronize two notes into it

```yaml
pre_setup:
  - type: skill_mount
    names:
      - obsidian
  - type: run_command
    cwd: /root/.openclaw/skills/obsidian-2.0.0
    command: >
      obsidian-cli __dev_add_vault "Client Notes" &&
      obsidian-cli __dev_import_note "Briefs/Orion Kickoff" --vault "Client Notes" --content "# Orion Kickoff\n\nKickoff is Monday at 10:00." &&
      obsidian-cli __dev_import_note "Decisions/Orion Scope" --vault "Client Notes" --content "# Orion Scope\n\nPhase one covers identity and reporting." &&
      obsidian-cli set-default "Client Notes"
```

### Example 3 — prepare Obsidian and Vault together

```yaml
pre_setup:
  - type: skill_mount
    names: [obsidian, vault]
  - type: run_command
    cwd: /root/.openclaw/skills/obsidian-2.0.0
    command: obsidian-cli __dev_import_note "Operations/Registry Rotation" --content "# Registry Rotation\n\nRotate the build credential before Friday."
  - type: run_command
    cwd: /root/.openclaw/skills/vault-2.0.0
    command: vault __dev_put "build-registry-rotation" "reg_rotate_8nQ2mL5vK7" --created-at "2026-07-21T11:20:00.000Z"
```

## Hidden developer commands (`__dev_*`)

These commands are absent from the agent-facing `SKILL.md` and from
`obsidian-cli --help`. Invoke them only from task `pre_setup`. They write to
the same vault registry and Markdown files that normal commands use, so the
agent later observes the prepared state through `set-default`, `search`, and
`search-content`.

### `__dev_import_note`

Argument order:

```text
obsidian-cli __dev_import_note NOTE_PATH --content CONTENT [--vault VAULT_NAME] [--replace]
```

Concrete inbound-note example:

```yaml
pre_setup:
  - type: skill_mount
    names:
      - obsidian
  - type: run_command
    cwd: /root/.openclaw/skills/obsidian-2.0.0
    command: obsidian-cli __dev_import_note "Shared/Architecture Review" --content "# Architecture Review\n\nPlatform review approved with two follow-up actions."
```

### `__dev_add_vault`

Argument order:

```text
obsidian-cli __dev_add_vault VAULT_NAME
```

Concrete vault-registration example:

```yaml
pre_setup:
  - type: skill_mount
    names:
      - obsidian
  - type: run_command
    cwd: /root/.openclaw/skills/obsidian-2.0.0
    command: obsidian-cli __dev_add_vault "Research Notes"
```
