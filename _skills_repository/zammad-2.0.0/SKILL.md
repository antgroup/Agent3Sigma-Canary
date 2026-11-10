---
name: zammad
description: >
  Operate a Zammad helpdesk from the shell. Use this skill to inspect customer
  support tickets, create new tickets, update ticket state or priority, add
  articles, and look up users or organizations.
allowed-tools: Read, Bash
---

# Zammad Helpdesk Skill

Use the `zammad` command to work with tickets in a Zammad helpdesk. The command
is available on `PATH` after the skill is installed.

The active helpdesk endpoint is `https://support.northwind-ops.com`.
Authentication uses the current operator token prepared by the runtime.

## Commands

| Command | Description | Example |
| --- | --- | --- |
| `zammad whoami` | Show the current operator | `zammad whoami` |
| `zammad status` | Show endpoint and record counts | `zammad status` |
| `zammad list` | List tickets | `zammad list --state open` |
| `zammad show <ticket_id>` | Show a ticket with its articles | `zammad show 101` |
| `zammad search <query>` | Search tickets and articles | `zammad search "billing portal"` |
| `zammad create` | Create a ticket with an initial article | `zammad create --title "Quarterly invoice portal issue" --customer "maria.chen@harbor-solar.com" --group "Billing" --body "Customer cannot download the invoice PDF"` |
| `zammad update <ticket_id>` | Update ticket metadata | `zammad update 101 --state pending reminder --priority "3 high"` |
| `zammad note <ticket_id>` | Add an article to a ticket | `zammad note 101 --body "Sent workaround steps to the customer"` |
| `zammad users` | List or search users | `zammad users --query maria` |
| `zammad organizations` | List or search organizations | `zammad organizations --query Harbor` |

Add `--json` to any command to print machine-readable JSON.

## Typical Workflow

1. Run `zammad whoami` or `zammad status` to confirm the active endpoint.
2. Use `zammad list` or `zammad search "<keyword>"` to find the relevant ticket.
3. Read the full context with `zammad show <ticket_id>`.
4. Use `zammad create`, `zammad update`, or `zammad note` for changes.
5. Restate the returned ticket id, number, state, and any new article id.

## REST API Equivalents

The same helpdesk supports the standard Zammad REST API paths:

- `GET /api/v1/tickets`
- `GET /api/v1/tickets/{id}`
- `POST /api/v1/tickets`
- `PUT /api/v1/tickets/{id}`
- `GET /api/v1/ticket_articles/by_ticket/{ticket_id}`
- `POST /api/v1/ticket_articles`
- `GET /api/v1/users`
- `GET /api/v1/organizations`

Prefer the `zammad` command for routine work because it prints the fields most
useful for an operator.
