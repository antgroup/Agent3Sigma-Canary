# LimeSurvey Skill for OpenClaw

> **Automate LimeSurvey operations via RemoteControl 2 API**

Complete OpenClaw skill for managing LimeSurvey surveys, participants, responses, and more through the official JSON-RPC API.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![OpenClaw](https://img.shields.io/badge/OpenClaw-Skill-blue)](https://openclaw.ai)
[![LimeSurvey API](https://img.shields.io/badge/LimeSurvey-RemoteControl%202-green)](https://api.limesurvey.org/)

## Features

✅ **Survey Management**
- List, activate, copy, delete, import surveys
- Get statistics and summaries

✅ **Participant Management**
- Batch add participants (CSV/JSON)
- Send invitations and reminders
- Filter by custom attributes

✅ **Response Export**
- Formats: CSV, Excel, PDF, JSON
- Filters: complete/incomplete, by token, by period
- Automatic Base64 decoding

✅ **Questions & Groups**
- Full CRUD operations
- Import from .lsq files

✅ **Reports & Analytics**
- Statistics in PDF/Excel with charts
- Submission timelines
- Fieldmap for analysis

## Quick Start

### Installation

For OpenClaw users:

1. Download the skill:
   ```bash
   clawhub install limesurvey
   ```

2. Configure credentials:
   ```bash
   export LIMESURVEY_URL='https://survey.example.com/index.php/admin/remotecontrol'
   export LIMESURVEY_USER='admin'
   export LIMESURVEY_PASSWORD='password'
   ```

### CLI Usage

```bash
# List all surveys
python3 skills/limesurvey/scripts/limesurvey.py list-surveys

# Export responses
python3 skills/limesurvey/scripts/limesurvey.py export-responses 123456 --format csv -o responses.csv

# List participants
python3 skills/limesurvey/scripts/limesurvey.py list-participants 123456 --limit 100

# Send invitations
python3 skills/limesurvey/scripts/limesurvey.py invite-participants 123456

# Activate survey
python3 skills/limesurvey/scripts/limesurvey.py activate-survey 123456

# Get summary statistics
python3 skills/limesurvey/scripts/limesurvey.py get-summary 123456
```

### Python API

```python
from scripts.limesurvey_client import LimeSurveySession

url = 'https://survey.example.com/index.php/admin/remotecontrol'

with LimeSurveySession(url, 'admin', 'password') as client:
    # List surveys
    surveys = client.call('list_surveys', client.session_key)
    
    # Export responses
    encoded = client.call('export_responses', client.session_key, 
                         survey_id, 'csv', None, 'complete')
    csv_data = client.decode_base64(encoded)
    
    # Add participants
    participants = [
        {"email": "user@example.com", "firstname": "John", "lastname": "Doe"}
    ]
    result = client.call('add_participants', client.session_key, 
                        survey_id, participants)
```

## Documentation

- **[SKILL.md](SKILL.md)** - Main guide with common workflows
- **[API Reference](references/api_reference.md)** - Complete function reference (50+ functions)
- **[Examples](references/examples.md)** - Practical code examples

## Structure

```
limesurvey/
├── SKILL.md                      # Main skill guide
├── README.md                     # This file
├── scripts/
│   ├── limesurvey_client.py     # JSON-RPC Python client
│   └── limesurvey.py            # CLI executable
└── references/
    ├── api_reference.md          # Complete API reference
    └── examples.md               # Practical examples
```

## Requirements

- Python 3.6+
- LimeSurvey instance with RemoteControl 2 API enabled
- Valid LimeSurvey credentials

**No external dependencies** - Uses only Python standard library.

## Common Workflows

### Batch Import Participants

```python
import csv

participants = []
with open('participants.csv', 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        participants.append({
            'email': row['email'],
            'firstname': row['firstname'],
            'lastname': row['lastname']
        })

with LimeSurveySession(url, username, password) as client:
    result = client.call('add_participants', client.session_key, 
                        survey_id, participants, True)
    print(f"Added {len(result)} participants")
```

### Daily Response Export

```python
with LimeSurveySession(url, username, password) as client:
    encoded = client.call('export_responses', client.session_key,
                         survey_id, 'csv', None, 'complete')
    
    csv_data = client.decode_base64(encoded)
    
    with open(f'responses_{date.today()}.csv', 'w') as f:
        f.write(csv_data)
```

### Send Reminders to Incomplete

```python
with LimeSurveySession(url, username, password) as client:
    # Get incomplete tokens
    participants = client.call('list_participants', client.session_key,
                              survey_id, 0, 1000, False, False,
                              {'completed': 'N'})
    
    token_ids = [p['tid'] for p in participants]
    
    # Send reminders
    result = client.call('remind_participants', client.session_key, 
                        survey_id, token_ids)
```

## API Coverage

This skill covers **50+ API functions** including:

- Session: `get_session_key`, `release_session_key`
- Surveys: `list_surveys`, `activate_survey`, `copy_survey`, `import_survey`, `get_summary`
- Participants: `add_participants`, `list_participants`, `invite_participants`, `remind_participants`
- Responses: `export_responses`, `add_response`, `update_response`, `delete_response`
- Questions/Groups: `list_questions`, `add_group`, `import_question`
- Export: `export_statistics`, `export_timeline`, `get_fieldmap`

See [API Reference](references/api_reference.md) for complete documentation.

## Error Handling

```python
from scripts.limesurvey_client import LimeSurveyError

try:
    with LimeSurveySession(url, username, password) as client:
        result = client.call('activate_survey', client.session_key, survey_id)
        
        if isinstance(result, dict) and 'status' in result:
            print(f"Error: {result['status']}")
        else:
            print("Success!")
            
except LimeSurveyError as e:
    print(f"API error: {e}")
```

## About OpenClaw

[OpenClaw](https://openclaw.ai) is an AI agent framework with modular skills. This skill enables AI agents to automate LimeSurvey operations.

## Resources

- [Official LimeSurvey API Documentation](https://api.limesurvey.org/classes/remotecontrol-handle.html)
- [RemoteControl 2 Manual](https://www.limesurvey.org/manual/RemoteControl_2_API)
- [OpenClaw Documentation](https://docs.openclaw.ai)
- [ClawHub - Skill Repository](https://clawhub.com)

## Contributing

Contributions welcome! Please open an issue or PR.

## License

MIT License - See LICENSE file for details

## Author

Created by **Daniel Marques** ([@olegantonov](https://github.com/olegantonov))

---

**Made for survey automation**
