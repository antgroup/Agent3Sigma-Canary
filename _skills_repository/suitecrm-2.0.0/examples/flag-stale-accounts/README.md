# flag-stale-accounts

Find every account where nothing has happened — no calls, meetings, tasks, or notes logged — in the last 30 days. Output a ranked list, worst offenders first.

Useful for weekly pipeline hygiene, QBR prep, and spotting accounts drifting toward renewal risk.

## Usage

```bash
bash run.sh          # default: 30-day window
bash run.sh 60       # 60-day window
```

Expected output:

```
Accounts with no activity in the last 30 days (15 of 42):

  Days silent  Account                 Owner      Open deals
  ----------   ----------------------  --------   -----------
  184          Globex Systems          admin      1 ($22k)
  121          Initech Finance         alice      0
   97          Acme Renewables         admin      2 ($88k)
   72          Umbrella Health         bob        0
   ...
```

Ordering by days-silent, with deal value so the biggest at-risk dollars are at the top.

## run.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

DAYS="${1:-30}"
: "${SUITECRM_URL:?set SUITECRM_URL}"

TOKEN=$(curl -s -X POST "$SUITECRM_URL/Api/access_token" \
  -d "grant_type=password" \
  -d "client_id=$SUITECRM_CLIENT_ID" \
  -d "client_secret=$SUITECRM_CLIENT_SECRET" \
  -d "username=$SUITECRM_USER" \
  -d "password=$SUITECRM_PASS" | jq -r '.access_token')

auth=(-H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.api+json")
CUTOFF=$(date -u -d "$DAYS days ago" +%Y-%m-%d)
TODAY_EPOCH=$(date -u +%s)

# 1. Get all accounts (paged — bump size for larger tenants)
curl -s "${auth[@]}" \
  "$SUITECRM_URL/Api/V8/module/Accounts?fields[Accounts]=name,assigned_user_id&page[size]=500" \
  | jq -c '.data[]' \
  | while read -r row; do
      ACCT_ID=$(jq -r '.id' <<<"$row")
      ACCT_NAME=$(jq -r '.attributes.name' <<<"$row")
      OWNER=$(jq -r '.attributes.assigned_user_id' <<<"$row")

      # Most recent activity across meetings/calls/tasks/notes
      LATEST=""
      for rel in meetings calls tasks notes; do
        D=$(curl -s "${auth[@]}" \
          "$SUITECRM_URL/Api/V8/module/Accounts/$ACCT_ID/relationships/$rel?sort=-date_entered&page[size]=1" \
          | jq -r '.data[0].attributes.date_entered[:10] // empty')
        if [[ -n "$D" && "$D" > "$LATEST" ]]; then LATEST="$D"; fi
      done

      # Silent if no activity OR latest activity is before cutoff
      if [[ -z "$LATEST" || "$LATEST" < "$CUTOFF" ]]; then
        if [[ -z "$LATEST" ]]; then
          DAYS_SILENT=9999
        else
          LATEST_EPOCH=$(date -u -d "$LATEST" +%s)
          DAYS_SILENT=$(( (TODAY_EPOCH - LATEST_EPOCH) / 86400 ))
        fi

        # Open deal count + total amount
        DEALS=$(curl -s "${auth[@]}" \
          "$SUITECRM_URL/Api/V8/module/Accounts/$ACCT_ID/relationships/opportunities" \
          | jq '[.data[] | select(.attributes.sales_stage != "Closed Won" and .attributes.sales_stage != "Closed Lost")] | {count: length, total: (map(.attributes.amount | tonumber? // 0) | add)}')
        DEAL_CT=$(jq -r '.count' <<<"$DEALS")
        DEAL_SUM=$(jq -r '.total' <<<"$DEALS")

        printf "%6d|%s|%s|%d|%d\n" "$DAYS_SILENT" "$ACCT_NAME" "$OWNER" "$DEAL_CT" "$DEAL_SUM"
      fi
    done \
  | sort -t'|' -k1 -nr \
  | awk -F'|' 'BEGIN {
      printf "\nAccounts silent longer than '"$DAYS"' days:\n\n"
      printf "  %-11s %-24s %-10s %s\n", "Days silent", "Account", "Owner", "Open deals"
      printf "  %-11s %-24s %-10s %s\n", "-----------", "----------------------", "----------", "----------"
    }
    { deals = ($4 > 0) ? sprintf("%d ($%dk)", $4, $5/1000) : "0"
      printf "  %-11s %-24s %-10s %s\n", $1, substr($2,1,24), substr($3,1,10), deals }'
```

## Why this is useful

Most CRMs have a "stale accounts" report built in, but it's usually hidden behind three menus and doesn't let you slice by deal value, owner, or custom time window. This runs on demand, composes with other skills (e.g., pipe the list into an agent prompt that drafts a re-engagement email), and can be scheduled as a weekly cron without any SuiteCRM customisation.

## Variations to try

- Add **`filter[assigned_user_id][eq]`** to scope to one rep.
- Swap `sort -k1 -nr` for `sort -t'|' -k5 -nr` to sort by deal value at risk instead of time silent.
- Emit CSV (`--output csv`) so the output can be pasted into a sheet or loaded into a BI tool.
- Wrap in a cron that posts the top 10 to Slack every Monday morning.
