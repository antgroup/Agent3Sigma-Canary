# LimeSurvey Common Examples

Practical code examples for common tasks.

## Setup

All examples assume the client is already initialized:

```python
from limesurvey_client import LimeSurveySession

url = 'https://survey.example.com/index.php/admin/remotecontrol'
username = 'admin'
password = 'password'

with LimeSurveySession(url, username, password) as client:
    # Your code here
    pass
```

---

## Survey Management

### List all surveys

```python
with LimeSurveySession(url, username, password) as client:
    surveys = client.call('list_surveys', client.session_key)
    
    for survey in surveys:
        print(f"{survey['sid']}: {survey['surveyls_title']} (Active: {survey['active']})")
```

### Activate a survey

```python
with LimeSurveySession(url, username, password) as client:
    result = client.call('activate_survey', client.session_key, survey_id)
    
    if isinstance(result, dict) and 'status' in result:
        print(f"Activation result: {result['status']}")
    else:
        print("Survey activated successfully")
```

### Get survey statistics

```python
with LimeSurveySession(url, username, password) as client:
    stats = client.call('get_summary', client.session_key, survey_id, 'all')
    
    print(f"Completed: {stats.get('completed_responses')}")
    print(f"Incomplete: {stats.get('incomplete_responses')}")
    print(f"Total tokens: {stats.get('token_count')}")
```

### Copy a survey

```python
with LimeSurveySession(url, username, password) as client:
    result = client.call('copy_survey', client.session_key, 
                        source_survey_id, 
                        "Copy of Survey", 
                        new_survey_id)  # Optional
    
    new_id = result.get('newsid')
    print(f"New survey ID: {new_id}")
```

---

## Participant Management

### Initialize participant table

```python
with LimeSurveySession(url, username, password) as client:
    # Create table with 5 custom attributes
    result = client.call('activate_tokens', client.session_key, survey_id, [1, 2, 3, 4, 5])
    print(result)  # {'status': 'OK'}
```

### Add participants from CSV data

```python
import csv

participants = []
with open('participants.csv', 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        participants.append({
            'email': row['email'],
            'firstname': row['firstname'],
            'lastname': row['lastname'],
            'attribute_1': row.get('company', '')
        })

with LimeSurveySession(url, username, password) as client:
    result = client.call('add_participants', client.session_key, 
                        survey_id, participants, True)
    
    print(f"Added {len(result)} participants")
    for p in result:
        print(f"  {p['email']}: {p['token']}")
```

### Send invitations to specific participants

```python
with LimeSurveySession(url, username, password) as client:
    # Get participants without sent invitations
    participants = client.call('list_participants', client.session_key, 
                              survey_id, 0, 1000, False, False,
                              {'sent': 'N'})
    
    token_ids = [p['tid'] for p in participants]
    
    # Send invitations
    result = client.call('invite_participants', client.session_key, 
                        survey_id, token_ids)
    
    for r in result:
        print(f"Token {r['tid']}: {r['status']}")
```

### Find participants by custom attribute

```python
with LimeSurveySession(url, username, password) as client:
    # Find all participants from "ACME Corp"
    participants = client.call('list_participants', client.session_key,
                              survey_id, 0, 1000, False, ['attribute_1'],
                              {'attribute_1': 'ACME Corp'})
    
    for p in participants:
        info = p['participant_info']
        print(f"{info['firstname']} {info['lastname']}: {info['email']}")
```

### Update participant email

```python
with LimeSurveySession(url, username, password) as client:
    result = client.call('set_participant_properties', 
                        client.session_key, survey_id,
                        {'tid': 123},  # Query by token ID
                        {'email': 'newemail@example.com'})
    
    print(result)
```

---

## Response Management

### Export all responses as CSV

```python
with LimeSurveySession(url, username, password) as client:
    # Get base64-encoded CSV
    encoded = client.call('export_responses', client.session_key, 
                         survey_id, 'csv')
    
    # Decode and save
    csv_data = client.decode_base64(encoded)
    
    with open('responses.csv', 'w', encoding='utf-8') as f:
        f.write(csv_data)
    
    print("Exported to responses.csv")
```

### Export only completed responses as Excel

```python
with LimeSurveySession(url, username, password) as client:
    encoded = client.call('export_responses', client.session_key,
                         survey_id, 'xls', None, 'complete')
    
    import base64
    xls_data = base64.b64decode(encoded)
    
    with open('completed.xls', 'wb') as f:
        f.write(xls_data)
```

### Export responses for specific participants

```python
with LimeSurveySession(url, username, password) as client:
    tokens = ['abc123', 'def456', 'ghi789']
    
    encoded = client.call('export_responses_by_token',
                         client.session_key, survey_id, 'csv', tokens)
    
    csv_data = client.decode_base64(encoded)
    print(csv_data)
```

### Add a response programmatically

```python
with LimeSurveySession(url, username, password) as client:
    # Get fieldmap to know question codes
    fieldmap = client.call('get_fieldmap', client.session_key, survey_id)
    
    # Build response
    response_data = {
        'G1Q1': 'John',           # Text answer
        'G1Q2': 'Doe',
        'G2Q1': '3',              # Multiple choice (value)
        'G2Q2A1': 'Y',            # Array question subquestion
        'token': 'xyz123'         # Optional: link to participant
    }
    
    response_id = client.call('add_response', client.session_key, 
                             survey_id, response_data)
    
    print(f"Created response ID: {response_id}")
```

### Get all responses for a token

```python
with LimeSurveySession(url, username, password) as client:
    token = 'abc123'
    
    # Find response IDs
    response_ids = client.call('get_response_ids', client.session_key, 
                              survey_id, token)
    
    if response_ids:
        print(f"Token {token} has {len(response_ids)} response(s)")
        
        # Export just these responses
        encoded = client.call('export_responses', client.session_key,
                            survey_id, 'json', None, 'all', 'code', 'short',
                            min(response_ids), max(response_ids))
        
        json_data = client.decode_base64(encoded)
        print(json_data)
```

---

## Question & Group Management

### List all questions in a survey

```python
with LimeSurveySession(url, username, password) as client:
    questions = client.call('list_questions', client.session_key, survey_id)
    
    for q in questions:
        print(f"[{q['title']}] {q['question']} (Type: {q['type']})")
```

### Create a new question group

```python
with LimeSurveySession(url, username, password) as client:
    group_id = client.call('add_group', client.session_key, survey_id,
                          'Demographics', 
                          'Basic participant information')
    
    print(f"Created group ID: {group_id}")
```

### Get question details including subquestions

```python
with LimeSurveySession(url, username, password) as client:
    props = client.call('get_question_properties', client.session_key,
                       question_id, 
                       ['question', 'type', 'subquestions', 'answeroptions'])
    
    print(f"Question: {props['question']}")
    print(f"Type: {props['type']}")
    
    if props.get('subquestions'):
        print("Subquestions:")
        for sq in props['subquestions'].values():
            print(f"  - {sq['title']}: {sq['question']}")
```

### Update question properties

```python
with LimeSurveySession(url, username, password) as client:
    result = client.call('set_question_properties', client.session_key,
                        question_id, {
                            'question': 'Updated question text',
                            'mandatory': 'Y',
                            'help': 'New help text'
                        })
    
    print(result)
```

---

## Export & Reporting

### Generate PDF statistics report

```python
with LimeSurveySession(url, username, password) as client:
    encoded = client.call('export_statistics', client.session_key,
                         survey_id, 'pdf', None, '1')  # With graphs
    
    import base64
    pdf_data = base64.b64decode(encoded)
    
    with open('statistics.pdf', 'wb') as f:
        f.write(pdf_data)
    
    print("Statistics saved to statistics.pdf")
```

### Get submission timeline (daily)

```python
with LimeSurveySession(url, username, password) as client:
    timeline = client.call('export_timeline', client.session_key,
                          survey_id, 'day', '2024-01-01', '2024-12-31')
    
    for entry in timeline:
        print(f"{entry['period']}: {entry['count']} submissions")
```

### Get survey fieldmap for analysis

```python
with LimeSurveySession(url, username, password) as client:
    fieldmap = client.call('get_fieldmap', client.session_key, survey_id)
    
    print("Question codes:")
    for code, info in fieldmap.items():
        print(f"  {code}: {info.get('qid')} - {info.get('title')}")
```

---

## Batch Operations

### Import survey from file

```python
import base64

with open('survey.lss', 'rb') as f:
    encoded = base64.b64encode(f.read()).decode()

with LimeSurveySession(url, username, password) as client:
    new_id = client.call('import_survey', client.session_key,
                        encoded, 'lss', 'Imported Survey')
    
    print(f"Imported survey ID: {new_id}")
```

### Delete old incomplete responses

```python
with LimeSurveySession(url, username, password) as client:
    # Export incomplete to get IDs
    encoded = client.call('export_responses', client.session_key,
                         survey_id, 'json', None, 'incomplete')
    
    import json
    responses = json.loads(client.decode_base64(encoded))
    
    # Delete old ones (example: before 2024)
    deleted = 0
    for resp in responses['responses']:
        submit_date = resp.get('submitdate')
        if submit_date and submit_date < '2024-01-01':
            result = client.call('delete_response', client.session_key,
                               survey_id, resp['id'])
            deleted += 1
    
    print(f"Deleted {deleted} old incomplete responses")
```

---

## Error Handling

### Robust error handling

```python
from limesurvey_client import LimeSurveyError

try:
    with LimeSurveySession(url, username, password) as client:
        result = client.call('activate_survey', client.session_key, survey_id)
        
        # Check for API-level errors
        if isinstance(result, dict) and 'status' in result:
            if 'already active' in result['status'].lower():
                print("Survey is already active")
            else:
                print(f"Error: {result['status']}")
        else:
            print("Success!")
            
except LimeSurveyError as e:
    print(f"LimeSurvey API error: {e}")
except Exception as e:
    print(f"Unexpected error: {e}")
```
