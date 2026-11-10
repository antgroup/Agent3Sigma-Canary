---
name: suitecrm
description: "Manage SuiteCRM records via the V8 REST API. Use for any CRM task: creating, reading, updating, or deleting Contacts, Leads, Accounts, Opportunities, Cases, and other modules. Also use when querying CRM data, managing relationships between records, or looking up customer information."
homepage: https://docs.suitecrm.com/developer/api/developer-setup-guide/json-api/
metadata:
  {
    "openclaw":
      {
        "emoji": "🏢",
        "requires": { "bins": ["jq", "curl"], "env": ["SUITECRM_URL", "SUITECRM_CLIENT_ID", "SUITECRM_CLIENT_SECRET"] },
        "primaryEnv": "SUITECRM_CLIENT_ID",
      },
  }
---

# SuiteCRM

Manage CRM records via the SuiteCRM V8 JSON:API. All operations use `curl` + `jq`.

> **Important**: When piping curl to `jq`, use only simple jq selectors (`.data`, `.attributes`, `.data[]`). Do NOT use `+` for string concatenation in jq — it causes shell quoting errors. Just output `.attributes` and let the user read the fields.

## Authentication

SuiteCRM uses OAuth2. Get a token before making API calls:

```bash
TOKEN=$(curl -s -X POST "$SUITECRM_URL/Api/access_token" \
  -d "grant_type=password&client_id=$SUITECRM_CLIENT_ID&client_secret=$SUITECRM_CLIENT_SECRET&username=$SUITECRM_USER&password=$SUITECRM_PASS" \
  | jq -r '.access_token')
```

Tokens expire in 1 hour. Re-fetch if you get a 401.

> The token endpoint requires `application/x-www-form-urlencoded` (curl default). Do NOT send JSON to it.

All subsequent requests need:

```bash
-H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.api+json"
```

## Core Operations

### List records

```bash
curl -s "$SUITECRM_URL/Api/V8/module/{Module}" \
  -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.api+json" | jq '.data[] | .attributes'
```

With pagination and field selection:

```bash
curl -s "$SUITECRM_URL/Api/V8/module/Contacts?fields[Contacts]=first_name,last_name,email1&page[size]=10&page[number]=1" \
  -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.api+json" | jq '.data'
```

> **Shell quoting**: When piping to `jq`, keep expressions simple. Avoid `+` string concatenation — use `.attributes` directly and let the full JSON show. For complex jq, write the filter to a temp file first.

### Get a single record

```bash
curl -s "$SUITECRM_URL/Api/V8/module/{Module}/{id}" \
  -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.api+json" | jq
```

### Create a record

```bash
curl -s -X POST "$SUITECRM_URL/Api/V8/module" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/vnd.api+json" \
  -d '{"data":{"type":"{Module}","attributes":{...}}}' | jq
```

### Update a record

```bash
curl -s -X PATCH "$SUITECRM_URL/Api/V8/module" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/vnd.api+json" \
  -d '{"data":{"type":"{Module}","id":"{id}","attributes":{...}}}' | jq
```

### Delete a record

```bash
curl -s -X DELETE "$SUITECRM_URL/Api/V8/module/{Module}/{id}" \
  -H "Authorization: Bearer $TOKEN" | jq
```

## Module Examples

### Contacts

```bash
# Create
curl -s -X POST "$SUITECRM_URL/Api/V8/module" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/vnd.api+json" \
  -d '{"data":{"type":"Contacts","attributes":{"first_name":"Jane","last_name":"Smith","email1":"jane@example.com","phone_work":"555-0100","title":"CTO","department":"Engineering"}}}' | jq

# Search by last name
curl -s "$SUITECRM_URL/Api/V8/module/Contacts?filter[last_name][eq]=Smith&fields[Contacts]=first_name,last_name,email1,phone_work" \
  -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.api+json" | jq
```

### Leads

```bash
# Create
curl -s -X POST "$SUITECRM_URL/Api/V8/module" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/vnd.api+json" \
  -d '{"data":{"type":"Leads","attributes":{"first_name":"Bob","last_name":"Jones","email1":"bob@example.com","phone_work":"555-0200","status":"New","lead_source":"Web Site","account_name":"Acme Corp"}}}' | jq
```

### Accounts

```bash
# Create
curl -s -X POST "$SUITECRM_URL/Api/V8/module" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/vnd.api+json" \
  -d '{"data":{"type":"Accounts","attributes":{"name":"Acme Corp","phone_office":"555-0300","industry":"Technology","billing_address_city":"San Francisco","billing_address_state":"CA","billing_address_country":"USA"}}}' | jq
```

### Opportunities

```bash
# Create
curl -s -X POST "$SUITECRM_URL/Api/V8/module" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/vnd.api+json" \
  -d '{"data":{"type":"Opportunities","attributes":{"name":"Q1 Deal","amount":"50000","date_closed":"2026-06-30","sales_stage":"Prospecting","lead_source":"Web Site"}}}' | jq
```

### Cases

```bash
# Create
curl -s -X POST "$SUITECRM_URL/Api/V8/module" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/vnd.api+json" \
  -d '{"data":{"type":"Cases","attributes":{"name":"Login issue","status":"New","priority":"High","type":"User","description":"Customer cannot log in since yesterday"}}}' | jq
```

## Relationships

```bash
# Get contacts linked to an account
curl -s "$SUITECRM_URL/Api/V8/module/Accounts/{id}/relationships/contacts" \
  -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.api+json" | jq

# Link a contact to an account
curl -s -X POST "$SUITECRM_URL/Api/V8/module/Accounts/{accountId}/relationships" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/vnd.api+json" \
  -d '{"data":{"type":"Contacts","id":"{contactId}"}}' | jq
```

## Filtering & Sorting

```bash
# Filter: accounts in Technology industry
?filter[industry][eq]=Technology

# Filter: opportunities > $10k
?filter[amount][gt]=10000

# Sort by date descending
?sort=-date_entered

# Sort by last name ascending
?sort=last_name

# Combine
?filter[status][eq]=New&sort=-date_entered&page[size]=5
```

Filter operators: `eq`, `neq`, `gt`, `gte`, `lt`, `lte`

## Metadata

```bash
# List all available modules
curl -s "$SUITECRM_URL/Api/V8/meta/modules" \
  -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.api+json" | jq

# Get field definitions for a module
curl -s "$SUITECRM_URL/Api/V8/meta/fields/{Module}" \
  -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.api+json" | jq
```

## Key Modules

Contacts, Leads, Accounts, Opportunities, Cases, Calls, Meetings, Tasks, Notes, Emails, Campaigns, Documents, Projects

## Field reference

For detailed field lists per module, read [references/modules.md](references/modules.md).

## Notes

- All IDs are UUIDs
- Module names are PascalCase and plural (Contacts, not contact)
- Create/Update use `POST`/`PATCH` to `/Api/V8/module` (no module name in URL)
- The `type` field in the JSON body must match the module name exactly
- Tokens expire in 1 hour; re-authenticate on 401
- Avoid `!` or other special chars in passwords used for API auth
