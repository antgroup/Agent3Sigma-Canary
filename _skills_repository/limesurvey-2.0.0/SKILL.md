---
name: limesurvey
description: "Automate LimeSurvey operations via RemoteControl 2 API. Use when: (1) managing surveys, questions, groups, or participants, (2) exporting responses or statistics, (3) sending invitations or reminders, (4) importing surveys or questions, (5) batch operations on survey data. Supports JSON-RPC API with full CRUD operations for surveys, participants, responses, questions, and groups. **REQUIRED ENVIRONMENT VARIABLES:** LIMESURVEY_URL (your RemoteControl endpoint), LIMESURVEY_USER, LIMESURVEY_PASSWORD (use least-privilege service account, never full admin credentials)."
metadata:
  openclaw:
    requires:
      env:
        - LIMESURVEY_URL
        - LIMESURVEY_USER
        - LIMESURVEY_PASSWORD
    credentials:
      - name: limesurvey-service-account
        description: "LimeSurvey RemoteControl service account (least-privilege recommended)"
        env: LIMESURVEY_USER,LIMESURVEY_PASSWORD
    homepage: "https://github.com/olegantonov/limesurvey-openclaw-skill"
version: "1.2.1"
author: "Daniel Marques"
license: "MIT"
---

# LimeSurvey RemoteControl 2 API

Automate LimeSurvey survey management via the RemoteControl 2 JSON-RPC API.

## Prerequisites

**Required Environment Variables:**
- `LIMESURVEY_URL` — Full URL to RemoteControl endpoint (e.g., `https://survey.example.com/index.php/admin/remotecontrol`)
- `LIMESURVEY_USER` — Service account username
- `LIMESURVEY_PASSWORD` — Service account password

**Security Recommendations:**
1. **Use a least-privilege service account**, not your full admin credentials
2. Create a dedicated LimeSurvey user with minimal required permissions (survey management only, no system administration)
3. Use a strong, unique password; rotate periodically after initial use
4. Never commit credentials to version control — use environment variables or secure vaults only
5. Verify the RemoteControl API is accessible only from trusted networks

**Setup:**
```bash
export LIMESURVEY_URL='https://survey.example.com/index.php/admin/remotecontrol'
export LIMESURVEY_USER='service_account_username'
export LIMESURVEY_PASSWORD='secure_service_password'
```

## Quick Start

### Setup

Set environment variables:

```bash
export LIMESURVEY_URL='https://survey.example.com/index.php/admin/remotecontrol'
export LIMESURVEY_USER='admin'
export LIMESURVEY_PASSWORD='your_password'
```

### CLI Usage

```bash
# List all surveys
python3 scripts/limesurvey.py list-surveys

# Export responses
python3 scripts/limesurvey.py export-responses 123456 --format csv -o responses.csv

# List participants
python3 scripts/limesurvey.py list-participants 123456 --limit 100

# Add participants from JSON
python3 scripts/limesurvey.py add-participants 123456 --file participants.json

# Send invitations
python3 scripts/limesurvey.py invite-participants 123456

# Activate survey
python3 scripts/limesurvey.py activate-survey 123456

# Get survey statistics
python3 scripts/limesurvey.py get-summary 123456
```

### Python API Usage

```python
from scripts.limesurvey_client import LimeSurveySession

url = 'https://survey.example.com/index.php/admin/remotecontrol'

with LimeSurveySession(url, 'admin', 'password') as client:
    # List surveys
    surveys = client.call('list_surveys', client.session_key)
    
    # Export responses
    encoded = client.call('export_responses', client.session_key, 
                         survey_id, 'csv')
    csv_data = client.decode_base64(encoded)
```

## Common Workflows

### Survey Management

**List all surveys:**
```python
surveys = client.call('list_surveys', client.session_key)
```

**Activate a survey:**
```python
result = client.call('activate_survey', client.session_key, survey_id)
```

**Get survey statistics:**
```python
stats = client.call('get_summary', client.session_key, survey_id, 'all')
# Returns: completed_responses, incomplete_responses, token_count, etc.
```

**Copy a survey:**
```python
result = client.call('copy_survey', client.session_key, 
                    source_id, "New Survey Name")
new_id = result['newsid']
```

### Participant Management

**Initialize participant table:**
```python
# Create table with custom attributes
client.call('activate_tokens', client.session_key, survey_id, [1, 2, 3])
```

**Add participants:**
```python
participants = [
    {"email": "user@example.com", "firstname": "John", "lastname": "Doe"},
    {"email": "user2@example.com", "firstname": "Jane", "lastname": "Smith"}
]
result = client.call('add_participants', client.session_key, 
                    survey_id, participants, True)
```

**Send invitations:**
```python
# Send to specific tokens
token_ids = [1, 2, 3]
result = client.call('invite_participants', client.session_key, 
                    survey_id, token_ids)

# Or send to all pending
result = client.call('invite_participants', client.session_key, 
                    survey_id, None)
```

**List participants with filters:**
```python
# Find unused tokens
participants = client.call('list_participants', client.session_key,
                          survey_id, 0, 100, True)

# Find by custom attribute
participants = client.call('list_participants', client.session_key,
                          survey_id, 0, 1000, False, False,
                          {'attribute_1': 'ACME Corp'})
```

### Response Operations

**Export all responses:**
```python
encoded = client.call('export_responses', client.session_key,
                     survey_id, 'csv')
csv_data = client.decode_base64(encoded)

with open('responses.csv', 'w') as f:
    f.write(csv_data)
```

**Export only completed responses:**
```python
encoded = client.call('export_responses', client.session_key,
                     survey_id, 'csv', None, 'complete')
```

**Export by token:**
```python
encoded = client.call('export_responses_by_token', client.session_key,
                     survey_id, 'json', ['token1', 'token2'])
```

**Add a response programmatically:**
```python
response_data = {
    'G1Q1': 'Answer text',
    'G1Q2': '3',  # Multiple choice value
    'token': 'xyz123'
}
response_id = client.call('add_response', client.session_key, 
                         survey_id, response_data)
```

### Question & Group Operations

**List groups:**
```python
groups = client.call('list_groups', client.session_key, survey_id)
```

**Add a question group:**
```python
group_id = client.call('add_group', client.session_key, survey_id,
                      'Demographics', 'Basic information')
```

**List questions:**
```python
# All questions in survey
questions = client.call('list_questions', client.session_key, survey_id)

# Questions in specific group
questions = client.call('list_questions', client.session_key, 
                       survey_id, group_id)
```

**Get question details:**
```python
props = client.call('get_question_properties', client.session_key,
                   question_id, ['question', 'type', 'mandatory'])
```

### Export & Reporting

**Generate statistics PDF:**
```python
encoded = client.call('export_statistics', client.session_key,
                     survey_id, 'pdf', None, '1')  # With graphs

import base64
pdf_data = base64.b64decode(encoded)

with open('stats.pdf', 'wb') as f:
    f.write(pdf_data)
```

**Get submission timeline:**
```python
timeline = client.call('export_timeline', client.session_key,
                      survey_id, 'day', '2024-01-01', '2024-12-31')

for entry in timeline:
    print(f"{entry['period']}: {entry['count']} submissions")
```

**Get survey fieldmap:**
```python
fieldmap = client.call('get_fieldmap', client.session_key, survey_id)
# Maps question codes to metadata
```

## Error Handling

All API functions return status objects on error:

```python
result = client.call('activate_survey', client.session_key, survey_id)

if isinstance(result, dict) and 'status' in result:
    print(f"Error: {result['status']}")
    # Common errors:
    # - Invalid session key
    # - No permission
    # - Invalid survey ID
    # - Survey already active
else:
    print("Success!")
```

Use try/except for connection errors:

```python
from scripts.limesurvey_client import LimeSurveyError

try:
    with LimeSurveySession(url, username, password) as client:
        result = client.call('list_surveys', client.session_key)
except LimeSurveyError as e:
    print(f"API error: {e}")
```

## Reference Documentation

- **[API Reference](references/api_reference.md)** - Complete function reference with parameters and return values
- **[Examples](references/examples.md)** - Practical code examples for common tasks

## Available Functions

### Session
- `get_session_key(username, password)` - Create session
- `release_session_key(session_key)` - Close session

### Surveys
- `list_surveys(session_key)` - List all surveys
- `get_survey_properties(session_key, survey_id, properties)` - Get properties
- `set_survey_properties(session_key, survey_id, properties)` - Update properties
- `activate_survey(session_key, survey_id)` - Activate survey
- `delete_survey(session_key, survey_id)` - Delete survey
- `copy_survey(session_key, source_id, new_name)` - Duplicate survey
- `import_survey(session_key, data, type)` - Import from file
- `get_summary(session_key, survey_id, stat)` - Get statistics

### Participants
- `activate_tokens(session_key, survey_id, attributes)` - Initialize table
- `list_participants(session_key, survey_id, start, limit, unused, attributes, conditions)` - List participants
- `add_participants(session_key, survey_id, data, create_token)` - Add participants
- `delete_participants(session_key, survey_id, token_ids)` - Delete participants
- `get_participant_properties(session_key, survey_id, query, properties)` - Get properties
- `set_participant_properties(session_key, survey_id, query, properties)` - Update properties
- `invite_participants(session_key, survey_id, token_ids)` - Send invitations
- `remind_participants(session_key, survey_id, token_ids)` - Send reminders

### Responses
- `export_responses(session_key, survey_id, format, ...)` - Export responses
- `export_responses_by_token(session_key, survey_id, format, tokens)` - Export by token
- `add_response(session_key, survey_id, data)` - Add response
- `update_response(session_key, survey_id, data)` - Update response
- `delete_response(session_key, survey_id, response_id)` - Delete response
- `get_response_ids(session_key, survey_id, token)` - Find response IDs

### Questions & Groups
- `list_groups(session_key, survey_id)` - List groups
- `add_group(session_key, survey_id, title, description)` - Create group
- `delete_group(session_key, survey_id, group_id)` - Delete group
- `get_group_properties(session_key, group_id, properties)` - Get properties
- `set_group_properties(session_key, group_id, properties)` - Update properties
- `list_questions(session_key, survey_id, group_id)` - List questions
- `get_question_properties(session_key, question_id, properties)` - Get properties
- `set_question_properties(session_key, question_id, properties)` - Update properties
- `import_question(session_key, survey_id, group_id, data, type)` - Import question
- `delete_question(session_key, question_id)` - Delete question

### Export & Reporting
- `export_statistics(session_key, survey_id, doc_type, language, graph)` - Export statistics
- `export_timeline(session_key, survey_id, type, start, end)` - Submission timeline
- `get_fieldmap(session_key, survey_id)` - Get question codes

## Notes

- **Session management**: Always close sessions with `release_session_key` or use `LimeSurveySession` context manager
- **Base64 encoding**: Export functions return base64-encoded data — use `client.decode_base64()` or `base64.b64decode()`
- **Permissions**: API calls respect user permissions — same as logging into admin interface
- **Rate limiting**: LimeSurvey has brute-force protection on authentication
- **JSON-RPC**: Content-Type must be `application/json` (handled automatically by client)

## Full API Documentation

Official LimeSurvey API: https://api.limesurvey.org/classes/remotecontrol-handle.html

Manual: https://www.limesurvey.org/manual/RemoteControl_2_API
