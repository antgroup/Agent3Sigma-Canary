# draft-followup-from-case-note

For a given support case, read the latest note (usually the most recent update from the engineer working it) and draft a follow-up email to the case's primary contact. The agent writes the draft — this recipe just assembles the inputs.

## Usage

```bash
bash run.sh <case-id>
```

Expected output:

```
Case:     [CASE-1042] Login issue (High, status=Pending Input)
Contact:  Jane Smith <jane@acme.com>
Latest note (2026-04-22):
  Tried a password reset, confirmed 2FA is enabled. Customer to
  provide browser version and a screenshot of the error screen.

--- draft ---
To: jane@acme.com
Subject: Re: [CASE-1042] Login issue — next step

Hi Jane,

Quick follow-up on the login issue you reported. We tried a password
reset on our end and confirmed 2FA is enabled on your account. To
narrow it down, could you send over:

  - your browser name and version
  - a screenshot of the error screen

Once we have those, we can usually resolve this same-day.

Thanks,
Aakeeo Support
```

The draft is templated here — in a real agent run, Claude writes the body from the note content. This example shows the shape of the inputs it needs.

## run.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

CASE_ID="${1:?usage: bash run.sh <case-id>}"
: "${SUITECRM_URL:?set SUITECRM_URL}"

TOKEN=$(curl -s -X POST "$SUITECRM_URL/Api/access_token" \
  -d "grant_type=password" \
  -d "client_id=$SUITECRM_CLIENT_ID" \
  -d "client_secret=$SUITECRM_CLIENT_SECRET" \
  -d "username=$SUITECRM_USER" \
  -d "password=$SUITECRM_PASS" | jq -r '.access_token')

auth=(-H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.api+json")

# 1. Case core fields
CASE=$(curl -s "${auth[@]}" "$SUITECRM_URL/Api/V8/module/Cases/$CASE_ID" | jq '.data')
CASE_NAME=$(jq -r '.attributes.name'     <<<"$CASE")
CASE_NUM=$(jq -r '.attributes.case_number' <<<"$CASE")
CASE_STATUS=$(jq -r '.attributes.status'  <<<"$CASE")
CASE_PRIO=$(jq -r '.attributes.priority'  <<<"$CASE")

# 2. Latest note on the case
NOTE=$(curl -s "${auth[@]}" \
  "$SUITECRM_URL/Api/V8/module/Cases/$CASE_ID/relationships/notes?sort=-date_entered&page[size]=1" \
  | jq '.data[0] // empty')
NOTE_DATE=$(jq -r '.attributes.date_entered[:10] // ""' <<<"$NOTE")
NOTE_BODY=$(jq -r '.attributes.description // ""'       <<<"$NOTE")

# 3. Primary contact (first linked contact wins)
CONTACT=$(curl -s "${auth[@]}" \
  "$SUITECRM_URL/Api/V8/module/Cases/$CASE_ID/relationships/contacts?page[size]=1" \
  | jq '.data[0] // empty')
CONTACT_NAME=$(jq -r '.attributes.first_name + " " + .attributes.last_name' <<<"$CONTACT")
CONTACT_EMAIL=$(jq -r '.attributes.email1' <<<"$CONTACT")

cat <<OUT
Case:     [CASE-$CASE_NUM] $CASE_NAME ($CASE_PRIO, status=$CASE_STATUS)
Contact:  $CONTACT_NAME <$CONTACT_EMAIL>
Latest note ($NOTE_DATE):
  $(echo "$NOTE_BODY" | fold -s -w 66 | sed 's/^/  /')

--- draft ---
To: $CONTACT_EMAIL
Subject: Re: [CASE-$CASE_NUM] $CASE_NAME — next step

Hi ${CONTACT_NAME%% *},

[Agent writes body here from the note above. Keep it under
120 words, ask for any missing info, give a next-step
commitment.]

Thanks,
Aakeeo Support
OUT
```

## Why this is useful

Support teams burn 15–20 minutes per case on context-switching: open the case, read the thread, find the contact, draft a reply. This assembles the whole packet in a single API round-trip. The agent (or a human) then writes the actual body.

## Variations to try

- Pull the **last 3 notes**, not just 1, so the draft can acknowledge the full thread.
- Add the customer's **account name** (via `Cases/$CASE_ID/relationships/accounts`) so the email can reference their company context.
- Save the draft back into SuiteCRM as an Email record in `draft` status so it shows up in the CRM outbox for a human to approve-and-send.
