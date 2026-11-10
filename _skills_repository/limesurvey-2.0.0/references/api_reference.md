# LimeSurvey RemoteControl 2 API Reference

Quick reference for the most commonly used API functions.

## Table of Contents

- Session Management
- Survey Operations
- Participant Management
- Response Management
- Question & Group Operations
- Export Operations

## Session Management

### get_session_key(username, password, plugin='Authdb')

Create a new session key. **Mandatory for all API calls.**

**Returns:** Session key string

**Example:**
```python
session_key = client.get_session_key('admin', 'password')
```

### release_session_key(session_key)

Close the RPC session.

**Returns:** 'OK'

---

## Survey Operations

### list_surveys(session_key, username=None)

List surveys accessible to the user.

**Returns:** Array of survey objects with `sid`, `surveyls_title`, `active`, `startdate`, `expires`

### get_survey_properties(session_key, survey_id, properties=None)

Get survey properties. If `properties` is None, returns all.

**Available properties:** sid, active, admin, adminname, adminemail, language, format, template, etc.

### set_survey_properties(session_key, survey_id, properties)

Update survey properties.

**Parameters:**
- `properties`: Dictionary with property names and new values

### activate_survey(session_key, survey_id, settings=[])

Activate a survey (create response table).

**Returns:** Status object

### delete_survey(session_key, survey_id)

Permanently delete a survey.

**Returns:** Status object

### copy_survey(session_key, source_survey_id, new_name, dest_survey_id=None)

Duplicate a survey.

**Returns:** New survey ID in `newsid` key

### import_survey(session_key, import_data, import_type, new_name=None, dest_id=None)

Import survey from BASE64-encoded file.

**Supported formats:** lss, csv, txt, lsa

**Example:**
```python
with open('survey.lss', 'rb') as f:
    encoded = base64.b64encode(f.read()).decode()
new_id = client.call('import_survey', session_key, encoded, 'lss', 'My Survey')
```

### get_summary(session_key, survey_id, stat_name='all')

Get survey statistics.

**Available stats:**
- `completed_responses` - Number of completed responses
- `incomplete_responses` - Number of incomplete responses
- `full_responses` - Total responses
- `token_count` - Total tokens
- `token_sent` - Tokens with sent invitations
- `token_completed` - Tokens with completed responses
- `token_opted_out` - Opted-out tokens

---

## Participant Management

### activate_tokens(session_key, survey_id, attribute_fields=[])

Initialize the participant table for a survey.

**Parameters:**
- `attribute_fields`: Array of integers for additional attribute fields

### list_participants(session_key, survey_id, start=0, limit=10, unused=False, attributes=False, conditions=[])

List survey participants.

**Parameters:**
- `start`: Start index (pagination)
- `limit`: Max results to return
- `unused`: If True, return only unused tokens
- `attributes`: Array of additional attributes to include
- `conditions`: Filter conditions (see examples below)

**Condition examples:**
```python
# Simple equality
conditions = {'email': 'user@example.com'}

# Operators
conditions = {'validuntil': ['>', '2024-01-01 00:00:00']}

# IN operator
conditions = {'tid': ['IN', '1', '3', '26']}
```

**Returns:** Array with `tid`, `token`, `participant_info` (firstname, lastname, email)

### add_participants(session_key, survey_id, participant_data, create_token=True)

Add participants to survey.

**Parameters:**
- `participant_data`: Array of participant objects
- `create_token`: Auto-generate token if True

**Participant object:**
```python
{
    "email": "user@example.com",
    "firstname": "John",
    "lastname": "Doe",
    "attribute_1": "custom_value"  # Optional custom attributes
}
```

**Returns:** Inserted data including token IDs and token strings

### delete_participants(session_key, survey_id, token_ids)

Delete multiple participants.

**Parameters:**
- `token_ids`: Array of token IDs to delete

### get_participant_properties(session_key, survey_id, query, properties=None)

Get participant details.

**Parameters:**
- `query`: Token ID (int) or dict with search criteria
- `properties`: Array of properties to fetch (None = all)

### set_participant_properties(session_key, survey_id, token_query, properties)

Update participant properties.

**Example:**
```python
client.call('set_participant_properties', session_key, survey_id, 
            {'tid': 123}, 
            {'email': 'newemail@example.com', 'validuntil': '2025-12-31'})
```

### invite_participants(session_key, survey_id, token_ids=None, email=True, continue_on_error=False)

Send invitation emails.

**Parameters:**
- `token_ids`: Array of token IDs (None = all pending)
- `email`: True for pending invites, False to resend
- `continue_on_error`: Don't stop on first invalid token

### remind_participants(session_key, survey_id, token_ids=None)

Send reminder emails to participants who haven't completed.

---

## Response Management

### export_responses(session_key, survey_id, format, language=None, completion='all', heading='code', response='short', from_id=None, to_id=None, fields=None)

Export survey responses as BASE64-encoded file.

**Parameters:**
- `format`: csv, pdf, xls, doc, json
- `completion`: all, complete, incomplete
- `heading`: code, full, abbreviated
- `response`: short, long
- `from_id`, `to_id`: Response ID range
- `fields`: Array of field names to export

**Returns:** Base64-encoded string (decode before use)

### export_responses_by_token(session_key, survey_id, format, tokens, language=None, ...)

Export responses for specific tokens.

**Parameters:**
- `tokens`: String or array of token values

### add_response(session_key, survey_id, response_data)

Add a response programmatically.

**Parameters:**
- `response_data`: Dict with question codes as keys

**Example:**
```python
response = {
    'G01Q01': 'Answer text',
    'G01Q02': '3',  # Multiple choice value
    'token': 'xyz123'  # Optional
}
result = client.call('add_response', session_key, survey_id, response)
```

**Returns:** Response ID

### update_response(session_key, survey_id, response_data)

Update an existing response.

**Note:** Must include response `id` in `response_data`

### delete_response(session_key, survey_id, response_id)

Delete a response.

### get_response_ids(session_key, survey_id, token)

Find response IDs for a given token.

**Returns:** Array of response IDs

---

## Question & Group Operations

### list_groups(session_key, survey_id, language=None)

List all question groups in a survey.

**Returns:** Array with `gid`, `group_name`, `group_order`, `description`

### add_group(session_key, survey_id, title, description='')

Create a new question group.

**Returns:** New group ID

### delete_group(session_key, survey_id, group_id)

Delete a question group and all its questions.

### get_group_properties(session_key, group_id, settings=None, language=None)

Get group properties.

### set_group_properties(session_key, group_id, properties)

Update group properties.

**Example:**
```python
client.call('set_group_properties', session_key, group_id, {
    'group_name': 'Demographics',
    'description': 'Basic information'
})
```

### list_questions(session_key, survey_id, group_id=None, language=None)

List questions in a survey or group.

**Returns:** Array with `qid`, `title`, `question`, `type`, `gid`, `question_order`

### get_question_properties(session_key, question_id, settings=None, language=None)

Get question properties.

**Additional properties:** `available_answers`, `subquestions`, `attributes`, `defaultvalue`

### import_question(session_key, survey_id, group_id, import_data, format, mandatory='N', title=None, text=None, help=None)

Import a question from BASE64-encoded .lsq file.

### delete_question(session_key, question_id)

Delete a question.

---

## Export Operations

### export_statistics(session_key, survey_id, doc_type='pdf', language=None, graph='0', group_ids=None)

Export statistics report.

**Parameters:**
- `doc_type`: pdf, xls, html
- `graph`: '0' or '1' to include graphs
- `group_ids`: Array of group IDs to include

**Returns:** Base64-encoded file

### export_timeline(session_key, survey_id, type, start, end)

Export submission timeline.

**Parameters:**
- `type`: 'day' or 'hour'
- `start`: Date string (YYYY-MM-DD)
- `end`: Date string

**Returns:** Array with count and period

### get_fieldmap(session_key, survey_id, language=None)

Get survey fieldmap (question codes and metadata).

**Returns:** Dictionary mapping field names to question metadata

---

## Common Error Handling

All functions return status arrays on error:

```python
{'status': 'Invalid session key'}
{'status': 'No permission'}
{'status': 'Invalid survey ID'}
```

Always check for `status` key in responses.

---

## Complete API Documentation

Full API reference: https://api.limesurvey.org/classes/remotecontrol-handle.html
