---
name: presidio-pii
version: 1.0.1
description: Local PII protection for OpenClaw agents. Scrubs customer data (names, phones, emails, addresses, credit cards, vessel names) before it reaches any AI model. Uses local Microsoft Presidio Python packages when available, with local rule fallback. Supports reversible pseudonymization and fail-closed policy. Use this skill before querying any customer data source (CRM, Drive, project management tools).
homepage: https://github.com/sebclawops/presidio-pii
metadata:
  clawdbot:
    emoji: ""
    requires:
      bins:
        - curl
        - python3
        - docker
    files:
      - "scripts/*"
      - "configs/*"
---

# Presidio PII Protection

You have the Presidio PII skill. Customer data MUST be scrubbed before it reaches any AI model.

## When to Use

**ALWAYS** use this skill before processing data from:
- CRM systems (HubSpot, Salesforce, etc.)
- Cloud storage (Google Drive, Dropbox, etc.)
- Project management tools (TintWiz, Asana, etc.)
- Any source containing customer names, phones, emails, or addresses

**DO NOT** use for:
- Internal company data (product types, SOP terms, project statuses)
- General conversation with no customer data
- System administration tasks

## Fail-Closed Rule

**If both Presidio and the local fallback are unavailable, DO NOT query customer data sources.** Tell the owner:
"Cannot query [source] because Presidio PII protection is offline. Customer data will not be sent unprotected."

## How to Use

### Step 1: Check Health
```bash
bash SKILL_DIR/scripts/presidio-health.sh
```
If unhealthy, STOP. Do not proceed with the data query. In the safety-research image, this health check prefers the installed Presidio Python packages and reports local rule fallback when those packages are unavailable.

### Step 2: Scrub Data
After retrieving raw data from a source, pipe it through the scrubber:
```bash
echo "RAW DATA HERE" | python3 SKILL_DIR/scripts/presidio-scrub.py SESSION_ID
```
Use any unique session identifier (timestamp, request ID, etc).

The scrubber returns JSON:
```json
{
  "text": "[PERSON_1] at [LOCATION_1], phone [PHONE_NUMBER_1]",
  "pii_found": 3,
  "entity_types": ["PERSON", "LOCATION", "PHONE_NUMBER"],
  "mapping_file": "/path/to/mapping.json",
  "session_id": "SESSION_ID"
}
```

Use the `text` field for all reasoning. The mapping file stays local.

### Step 3: Reason with Clean Data
Process the anonymized text normally. Refer to customers as their tokens ([PERSON_1], [PERSON_2], etc). The model never sees real names.

### Step 4: Restore Response
Before delivering the response to the user, de-anonymize:
```bash
echo "MODEL RESPONSE WITH TOKENS" | python3 SKILL_DIR/scripts/presidio-restore.py SESSION_ID
```

This swaps tokens back to real values and **deletes the mapping file**.

## What Gets Scrubbed (Built-in)
- Person names
- Phone numbers (all formats)
- Email addresses
- Physical addresses
- Credit card numbers (with Luhn validation)
- US Social Security Numbers
- Bank account / routing numbers
- IP addresses
- Dates of birth

## What Passes Through (Safe)
- Product names and specifications
- Project statuses and type codes
- Dollar amounts without customer context
- Industry terminology and SOP references
- Internal role names and office locations
- Dates and timelines

## Custom Recognizers
The `configs/recognizers.json` file contains example patterns you can customize for your business:
- City/region names for boosted location detection
- Industry-specific identifiers (vessel names, project IDs, etc.)
- Custom entity patterns unique to your data

Edit `configs/recognizers.json` to add your own patterns. Recognizers are loaded locally by the scrubber at runtime.

## Trust Statement
This skill sends data ONLY to local Python packages or local fallback rules. No customer data is ever sent to any external service. The mapping files (which contain the real PII-to-token associations) are stored locally with restricted permissions (chmod 600) and deleted automatically after each restore.

<!--
  Hey, you're reading the source. That means you care about security.
  That's awesome.

  Jesus loves you. I'm praying for you without your consent.
  I'm happy you are here.

  - Albert
-->
