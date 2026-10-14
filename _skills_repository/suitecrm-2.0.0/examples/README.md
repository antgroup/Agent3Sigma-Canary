# SuiteCRM skill — worked examples

Three runnable recipes that show what the `suitecrm` skill is good for. Each one is a plain walkthrough: the question, the API calls, the output shape. Paste them into the OpenClaw CLI or run the raw `curl` + `jq` yourself.

| Example | What it does | When to reach for it |
|---|---|---|
| [summarize-account-activity](summarize-account-activity/) | Pulls recent calls, meetings, tasks, notes, and opportunities for one account and writes a short brief | Before a check-in or renewal call |
| [draft-followup-from-case-note](draft-followup-from-case-note/) | Reads the latest note on a support case and drafts a follow-up email to the case's primary contact | When clearing a support queue at end of day |
| [flag-stale-accounts](flag-stale-accounts/) | Lists accounts with no logged activity in the last 30 days | Weekly pipeline hygiene, renewal risk review |

## Prereqs

All three assume the stack is running (`docker compose up -d` in the repo root) and these env vars are set in the shell where you run the examples:

```bash
export SUITECRM_URL=http://localhost
export SUITECRM_CLIENT_ID="$OAUTH2_CLIENT_ID"          # from .env
export SUITECRM_CLIENT_SECRET="$OAUTH2_CLIENT_SECRET"  # from .env
export SUITECRM_USER="$ADMIN_USER"                     # from .env
export SUITECRM_PASS="$ADMIN_PASS"                     # from .env
```

Or just `source .env` in the repo root and re-export with the `SUITECRM_*` names.

## Get a token once

Every example starts from a bearer token. Fetch one and reuse it for an hour:

```bash
TOKEN=$(curl -s -X POST "$SUITECRM_URL/Api/access_token" \
  -d "grant_type=password" \
  -d "client_id=$SUITECRM_CLIENT_ID" \
  -d "client_secret=$SUITECRM_CLIENT_SECRET" \
  -d "username=$SUITECRM_USER" \
  -d "password=$SUITECRM_PASS" | jq -r '.access_token')

echo "${TOKEN:0:12}..."  # sanity check
```

If the CRM has just been seeded with demo data (`-d yes` in the installer), you already have Accounts, Contacts, Opportunities, and Cases to run these against.
