# summarize-account-activity

Before jumping on a call with a customer, pull everything the CRM remembers about them into a single plain-text brief — recent meetings, open opportunities, last note, unresolved cases.

The script takes an **account name** (or substring) and returns a short summary.

## Usage

```bash
bash run.sh "Acme"
```

Expected output:

```
=== Acme Corp ===
Industry: Technology   Phone: 555-0300   Owner: admin

Open opportunities (2):
  - Q2 Expansion      $45,000   Negotiation/Review   close 2026-06-15
  - Renewal 2026      $18,000   Proposal/Price Quote close 2026-05-01

Last 5 activities:
  2026-04-20  meeting  Held      "Pricing walk-through"
  2026-04-12  call     Held      "Intro with new CTO"
  2026-03-30  task     Completed "Send updated SOW"
  2026-03-18  note              "Asked about SSO options"
  2026-03-10  meeting  Held      "Quarterly review"

Open cases (1):
  - [High] Login issue   status=New   opened 2026-04-22
```

## run.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

NAME="${1:?usage: bash run.sh <account name or substring>}"
: "${SUITECRM_URL:?set SUITECRM_URL}"

TOKEN=$(curl -s -X POST "$SUITECRM_URL/Api/access_token" \
  -d "grant_type=password" \
  -d "client_id=$SUITECRM_CLIENT_ID" \
  -d "client_secret=$SUITECRM_CLIENT_SECRET" \
  -d "username=$SUITECRM_USER" \
  -d "password=$SUITECRM_PASS" | jq -r '.access_token')

auth=(-H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.api+json")

# 1. Find the account (first match wins)
ACCT=$(curl -s "${auth[@]}" \
  "$SUITECRM_URL/Api/V8/module/Accounts?filter[name][eq]=$NAME&page[size]=1" \
  | jq -r '.data[0] // empty')

if [[ -z "$ACCT" ]]; then
  echo "No account matching '$NAME'"; exit 1
fi

ACCT_ID=$(jq -r '.id'                      <<<"$ACCT")
ACCT_NAME=$(jq -r '.attributes.name'       <<<"$ACCT")
INDUSTRY=$(jq -r '.attributes.industry'    <<<"$ACCT")
PHONE=$(jq -r '.attributes.phone_office'   <<<"$ACCT")

echo "=== $ACCT_NAME ==="
echo "Industry: $INDUSTRY   Phone: $PHONE"
echo

# 2. Open opportunities
echo "Open opportunities:"
curl -s "${auth[@]}" \
  "$SUITECRM_URL/Api/V8/module/Accounts/$ACCT_ID/relationships/opportunities" \
  | jq -r '.data[] | "  - \(.attributes.name)  $\(.attributes.amount)  \(.attributes.sales_stage)  close \(.attributes.date_closed)"'
echo

# 3. Recent activities across meetings, calls, tasks, notes
echo "Last 5 activities:"
for rel in meetings calls tasks notes; do
  curl -s "${auth[@]}" \
    "$SUITECRM_URL/Api/V8/module/Accounts/$ACCT_ID/relationships/$rel" \
    | jq -r --arg t "$rel" '.data[] | "\(.attributes.date_entered // .attributes.date_start // "")|\($t)|\(.attributes.status // "")|\(.attributes.name // "")"'
done | sort -r | head -5 | awk -F'|' '{printf "  %s  %-8s %-9s \"%s\"\n", substr($1,1,10), $2, $3, $4}'
echo

# 4. Open cases
echo "Open cases:"
curl -s "${auth[@]}" \
  "$SUITECRM_URL/Api/V8/module/Accounts/$ACCT_ID/relationships/cases" \
  | jq -r '.data[] | select(.attributes.state=="Open") | "  - [\(.attributes.priority)] \(.attributes.name)   status=\(.attributes.status)   opened \(.attributes.date_entered[:10])"'
```

## Why this is useful

The brief you get out is the same thing an account manager would assemble by hand — clicking through five tabs in the CRM UI. With the skill wired up, an agent can build this on demand, as part of a bigger "prep me for my 3pm" prompt, without a single click.

## Variations to try

- Swap `filter[name][eq]` for `filter[name][like]` to fuzzy-match when the exact name isn't known.
- Join to **Contacts** by adding a loop over `Accounts/$ACCT_ID/relationships/contacts` and listing primary contact names + titles.
- Emit JSON instead of plain text (`--arg` into a single `jq` object) so the output can feed another agent step.
