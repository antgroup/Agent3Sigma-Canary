---
name: google-drive
description: |
  Google Drive API integration with managed OAuth. List, search, create, and manage files and folders. Use this skill when users want to interact with Google Drive files. For other third party apps, use the api-gateway skill (https://clawhub.ai/byungkyu/api-gateway).
compatibility: Requires network access and valid Maton API key
metadata:
  author: maton
  version: "1.0"
  clawdbot:
    emoji: 🧠
    requires:
      env:
        - MATON_API_KEY
---

# Google Drive

Access the Google Drive API with managed OAuth authentication. List, search, create, and manage files and folders.

## Quick Start

**CLI:**

```bash
maton google-drive file list -Q "name contains 'budget'"
```

```bash
maton api "/google-drive/drive/v3/files?q=name+contains+'budget'"
```

**Python:**

```bash
python <<'EOF'
import urllib.request, os, json, urllib.parse
params = urllib.parse.urlencode({'q': "name contains 'budget'"})
req = urllib.request.Request(f'https://api.maton.ai/google-drive/drive/v3/files?{params}')
req.add_header('Authorization', f'Bearer {os.environ["MATON_API_KEY"]}')
print(json.dumps(json.load(urllib.request.urlopen(req)), indent=2))
EOF
```

## Base URL

```
https://api.maton.ai/google-drive/{native-api-path}
```

Maton proxies requests to `www.googleapis.com` and automatically injects your OAuth token.

## Installation

**NPM:**
```bash
npm install -g @maton-ai/cli
```

**Homebrew:**
```bash
brew install maton-ai/cli/maton
```

## Authentication

**CLI:**

```bash
maton login                          # Opens browser for API key
maton login --interactive            # Skip browser, paste API key directly
maton whoami                         # Show current auth state
```

**Manual:**

1. Sign in or create an account at [maton.ai](https://maton.ai)
2. Go to [maton.ai/settings](https://maton.ai/settings)
3. Copy your API key
4. Set your API key as `MATON_API_KEY`:

```bash
export MATON_API_KEY="YOUR_API_KEY"
```

## Connection Management

Manage your Google OAuth connections at `https://api.maton.ai`.

### List Connections

**CLI:**

```bash
maton connection list google-drive --status ACTIVE
```

```bash
maton api -X GET /connections -f app=google-drive -f status=ACTIVE
```

**Python:**

```bash
python <<'EOF'
import urllib.request, os, json
req = urllib.request.Request('https://api.maton.ai/connections?app=google-drive&status=ACTIVE')
req.add_header('Authorization', f'Bearer {os.environ["MATON_API_KEY"]}')
print(json.dumps(json.load(urllib.request.urlopen(req)), indent=2))
EOF
```

### Create Connection

**CLI:**

```bash
maton connection create google-drive
```

```bash
maton api /connections -f app=google-drive
```

**Python:**

```bash
python <<'EOF'
import urllib.request, os, json
data = json.dumps({'app': 'google-drive'}).encode()
req = urllib.request.Request('https://api.maton.ai/connections', data=data, method='POST')
req.add_header('Authorization', f'Bearer {os.environ["MATON_API_KEY"]}')
req.add_header('Content-Type', 'application/json')
print(json.dumps(json.load(urllib.request.urlopen(req)), indent=2))
EOF
```

### Get Connection

**CLI:**

```bash
maton connection view {connection_id}
```

```bash
maton api /connections/{connection_id}
```

**Python:**

```bash
python <<'EOF'
import urllib.request, os, json
req = urllib.request.Request('https://api.maton.ai/connections/{connection_id}')
req.add_header('Authorization', f'Bearer {os.environ["MATON_API_KEY"]}')
print(json.dumps(json.load(urllib.request.urlopen(req)), indent=2))
EOF
```

**Response:**
```json
{
  "connection": {
    "connection_id": "{connection_id}",
    "status": "ACTIVE",
    "creation_time": "2025-12-08T07:20:53.488460Z",
    "last_updated_time": "2026-01-31T20:03:32.593153Z",
    "url": "https://connect.maton.ai/?session_token=...",
    "app": "google-drive",
    "metadata": {}
  }
}
```

Open the returned `url` in a browser to complete OAuth authorization.

### Delete Connection

**CLI:**

```bash
maton connection delete {connection_id}
```

```bash
maton api -X DELETE /connections/{connection_id}
```

**Python:**

```bash
python <<'EOF'
import urllib.request, os, json
req = urllib.request.Request('https://api.maton.ai/connections/{connection_id}', method='DELETE')
req.add_header('Authorization', f'Bearer {os.environ["MATON_API_KEY"]}')
print(json.dumps(json.load(urllib.request.urlopen(req)), indent=2))
EOF
```

### Specifying Connection

If you have multiple Google Drive connections, specify which one to use:

**CLI:**

```bash
maton google-drive file list --connection {connection_id}
```

```bash
maton api /google-drive/drive/v3/files --connection {connection_id}
```

**Python:**

```bash
python <<'EOF'
import urllib.request, os, json
req = urllib.request.Request('https://api.maton.ai/google-drive/drive/v3/files?pageSize=10')
req.add_header('Authorization', f'Bearer {os.environ["MATON_API_KEY"]}')
req.add_header('Maton-Connection', '{connection_id}')
print(json.dumps(json.load(urllib.request.urlopen(req)), indent=2))
EOF
```

If you have multiple connections, always specify the connection to ensure requests go to the intended account.

## Security & Permissions

- Access is scoped to files, folders, permissions, and sharing within the connected Google Drive account.
- **All write operations require explicit user approval.** Before executing any create, update, or delete call, confirm the target resource and intended effect with the user.

## API Reference

### List Files

```bash
GET /google-drive/drive/v3/files?pageSize=10
```

With query:

```bash
GET /google-drive/drive/v3/files?q=name%20contains%20'report'&pageSize=10
```

Only folders:

```bash
GET /google-drive/drive/v3/files?q=mimeType='application/vnd.google-apps.folder'
```

Files in specific folder:

```bash
GET /google-drive/drive/v3/files?q='FOLDER_ID'+in+parents
```

With fields:

```bash
GET /google-drive/drive/v3/files?fields=files(id,name,mimeType,createdTime,modifiedTime,size)
```

Example:

```bash
maton google-drive file list -Q "name contains 'budget'"
```

### Get File Metadata

```bash
GET /google-drive/drive/v3/files/{fileId}?fields=id,name,mimeType,size,createdTime
```

Example:

```bash
maton google-drive file view FILE_ID --fields 'id,name,mimeType,size,createdTime'
```

### Download File Content

```bash
GET /google-drive/drive/v3/files/{fileId}?alt=media
```

Example:

```bash
maton google-drive file download FILE_ID --output ./report.pdf
```

### Export Google Docs

```bash
GET /google-drive/drive/v3/files/{fileId}/export?mimeType=application/pdf
```

Example:

```bash
maton google-drive file export FILE_ID --mime-type application/pdf --output ./doc.pdf
```

### Create File (metadata only)

```bash
POST /google-drive/drive/v3/files
Content-Type: application/json

{
  "name": "New Document",
  "mimeType": "application/vnd.google-apps.document"
}
```

Example:

```bash
maton google-drive file create --name 'New Document' --mime-type application/vnd.google-apps.document
```

### Create Folder

```bash
POST /google-drive/drive/v3/files
Content-Type: application/json

{
  "name": "New Folder",
  "mimeType": "application/vnd.google-apps.folder"
}
```

Example:

```bash
maton google-drive file create --name 'New Folder' --mime-type application/vnd.google-apps.folder
```

### Update File Metadata

```bash
PATCH /google-drive/drive/v3/files/{fileId}
Content-Type: application/json

{
  "name": "Renamed File"
}
```

Example:

```bash
maton google-drive file update FILE_ID --name 'Renamed File'
```

### Move File to Folder

```bash
PATCH /google-drive/drive/v3/files/{fileId}?addParents=NEW_FOLDER_ID&removeParents=OLD_FOLDER_ID
```

Example:

```bash
maton google-drive file update FILE_ID --add-parents NEW_FOLDER_ID --remove-parents OLD_FOLDER_ID
```

### Delete File

```bash
DELETE /google-drive/drive/v3/files/{fileId}
```

Example:

```bash
maton google-drive file delete FILE_ID
```

### Copy File

```bash
POST /google-drive/drive/v3/files/{fileId}/copy
Content-Type: application/json

{
  "name": "Copy of File"
}
```

Example:

```bash
maton google-drive file copy FILE_ID --name 'Copy of File'
```

## File Uploads

Google Drive supports three upload types depending on file size and whether you need to include metadata:

- **Simple upload (`uploadType=media`)** — small files (≤5 MB) with no metadata.
- **Multipart upload (`uploadType=multipart`)** — small files (≤5 MB) sent together with metadata in a single request.
- **Resumable upload (`uploadType=resumable`)** — large files (>5 MB), or any upload where network interruption is likely. Resumable uploads also work fine for small files at the cost of one extra HTTP round trip, so they're a safe default for most applications.

`maton google-drive file upload` picks the upload type for you based on the file size and flags:

| Flags | File size | Upload type used |
|---|---|---|
| `--no-metadata` | any | `uploadType=media` |
| (default, with metadata) | < 5 MiB | `uploadType=multipart` |
| (default, with metadata) | ≥ 5 MiB | `uploadType=resumable` (chunked, auto-resumes on transient errors) |

If you call the API directly, you choose the `uploadType` query parameter yourself per the sections below.

### Simple Upload (Media)

For files up to 5MB when you don't need to set metadata.

```bash
POST /google-drive/upload/drive/v3/files?uploadType=media
Content-Type: text/plain

<file content>
```

CLI:

```bash
maton google-drive file upload ./hello.txt --no-metadata
```

Python:

```python
import urllib.request, os

file_content = b'Hello, this is file content!'

url = 'https://api.maton.ai/google-drive/upload/drive/v3/files?uploadType=media'
req = urllib.request.Request(url, data=file_content, method='POST')
req.add_header('Authorization', f'Bearer {os.environ["MATON_API_KEY"]}')
req.add_header('Content-Type', 'text/plain')
response = urllib.request.urlopen(req)
```

### Multipart Upload

For files up to 5MB when you need to include metadata (name, description, etc.).

```bash
POST /google-drive/upload/drive/v3/files?uploadType=multipart
Content-Type: multipart/related; boundary=boundary

--boundary
Content-Type: application/json; charset=UTF-8

{"name": "myfile.txt", "description": "My file"}
--boundary
Content-Type: text/plain

<file content>
--boundary--
```

CLI:

```bash
maton google-drive file upload ./myfile.txt
```

Python:

```python
import urllib.request, os, json

boundary = '----Boundary'
metadata = json.dumps({'name': 'myfile.txt', 'description': 'My file'})
file_content = 'File content here'

body = f'''--{boundary}\r
Content-Type: application/json; charset=UTF-8\r
\r
{metadata}\r
--{boundary}\r
Content-Type: text/plain\r
\r
{file_content}\r
--{boundary}--'''.encode()

url = 'https://api.maton.ai/google-drive/upload/drive/v3/files?uploadType=multipart'
req = urllib.request.Request(url, data=body, method='POST')
req.add_header('Authorization', f'Bearer {os.environ["MATON_API_KEY"]}')
req.add_header('Content-Type', f'multipart/related; boundary={boundary}')
response = urllib.request.urlopen(req)
```

### Resumable Upload (Large Files)

For large files (recommended for files > 5MB). This approach:
1. Initiates a session - Gets an upload URI
2. Uploads in chunks - Sends file in pieces
3. Supports resume - Can continue from where it left off if interrupted

**Step 1: Initiate Upload Session**

```bash
POST /google-drive/upload/drive/v3/files?uploadType=resumable
Content-Type: application/json; charset=UTF-8
X-Upload-Content-Type: application/octet-stream
X-Upload-Content-Length: <file_size>

{"name": "large_file.bin"}
```

Response includes `Location` header with the upload URI.

**Step 2: Upload Content**

```bash
PUT <upload_uri>
Content-Length: <file_size>
Content-Type: application/octet-stream

<file content>
```

CLI:

```bash
maton google-drive file upload ./large_file.bin
```

Python:

```python
import urllib.request, os, json

file_path = '/path/to/large_file.bin'
file_size = os.path.getsize(file_path)

# Step 1: Initiate resumable upload session
url = 'https://api.maton.ai/google-drive/upload/drive/v3/files?uploadType=resumable'
metadata = json.dumps({'name': 'large_file.bin'}).encode()

req = urllib.request.Request(url, data=metadata, method='POST')
req.add_header('Authorization', f'Bearer {os.environ["MATON_API_KEY"]}')
req.add_header('Content-Type', 'application/json; charset=UTF-8')
req.add_header('X-Upload-Content-Type', 'application/octet-stream')
req.add_header('X-Upload-Content-Length', str(file_size))

response = urllib.request.urlopen(req)
upload_uri = response.headers['Location']

# Step 2: Upload file in chunks (e.g., 5MB chunks)
chunk_size = 5 * 1024 * 1024
with open(file_path, 'rb') as f:
    offset = 0
    while offset < file_size:
        chunk = f.read(chunk_size)
        end = offset + len(chunk) - 1

        req = urllib.request.Request(upload_uri, data=chunk, method='PUT')
        req.add_header('Content-Length', str(len(chunk)))
        req.add_header('Content-Range', f'bytes {offset}-{end}/{file_size}')

        response = urllib.request.urlopen(req)
        offset += len(chunk)

result = json.load(response)
print(f"Uploaded: {result['id']}")
```

**Resuming Interrupted Uploads:**

If an upload is interrupted, re-run `maton google-drive file upload`, which resumes from the last persisted offset automatically.

If calling the API directly, query the upload URI to get current status:

```python
req = urllib.request.Request(upload_uri, method='PUT')
req.add_header('Content-Length', '0')
req.add_header('Content-Range', 'bytes */*')
response = urllib.request.urlopen(req)
# Check Range header in response to get current offset
```

### Update File Content

To update an existing file's content:

```bash
PATCH /google-drive/upload/drive/v3/files/{fileId}?uploadType=media
Content-Type: text/plain

<new file content>
```

CLI:

```bash
maton google-drive file update YOUR_FILE_ID --file ./updated.txt
```

Python:

```python
import urllib.request, os

file_id = 'YOUR_FILE_ID'
new_content = b'Updated file content!'

url = f'https://api.maton.ai/google-drive/upload/drive/v3/files/{file_id}?uploadType=media'
req = urllib.request.Request(url, data=new_content, method='PATCH')
req.add_header('Authorization', f'Bearer {os.environ["MATON_API_KEY"]}')
req.add_header('Content-Type', 'text/plain')
response = urllib.request.urlopen(req)
```

### Upload to Specific Folder

Include the folder ID in the metadata:

```python
metadata = json.dumps({
    'name': 'myfile.txt',
    'parents': ['FOLDER_ID']
})
```

Example:

```bash
maton google-drive file upload ./myfile.txt --parent FOLDER_ID
```

### Share File

```bash
POST /google-drive/drive/v3/files/{fileId}/permissions
Content-Type: application/json

{
  "role": "reader",
  "type": "user",
  "emailAddress": "user@example.com"
}
```

Example:

```bash
maton google-drive permission create -f FILE_ID --type user --role reader --email-address user@example.com
```

## Query Operators

Use in the `q` parameter:
- `name = 'exact name'`
- `name contains 'partial'`
- `mimeType = 'application/pdf'`
- `'folderId' in parents`
- `trashed = false`
- `modifiedTime > '2024-01-01T00:00:00'`

Combine with `and`:
```
name contains 'report' and mimeType = 'application/pdf'
```

## Common MIME Types

- `application/vnd.google-apps.document` - Google Docs
- `application/vnd.google-apps.spreadsheet` - Google Sheets
- `application/vnd.google-apps.presentation` - Google Slides
- `application/vnd.google-apps.folder` - Folder
- `application/pdf` - PDF

## Pagination

Google Drive uses token-based pagination. The CLI automatically paginates with '--paginate'.

Example:

```bash
maton google-drive file list --paginate
```

## Code Examples

### CLI

```bash
# List files matching a query
maton google-drive file list -Q "name contains 'budget'"

# Filter with jq
maton google-drive file list --json --jq '.files[] | {name: .name, id: .id}'

# Extract specific fields
maton google-drive drive list --json --jq '.drives[].name'
```

### JavaScript

```javascript
const response = await fetch(
  'https://api.maton.ai/google-drive/drive/v3/files?pageSize=10',
  {
    headers: {
      'Authorization': `Bearer ${process.env.MATON_API_KEY}`
    }
  }
);
```

### Python

```python
import os
import requests

response = requests.get(
    'https://api.maton.ai/google-drive/drive/v3/files',
    headers={'Authorization': f'Bearer {os.environ["MATON_API_KEY"]}'},
    params={'pageSize': 10}
)
```

## Notes

- Use `fields` parameter to limit response data
- Pagination uses `pageToken` from previous response's `nextPageToken`
- Export is for Google Workspace files only
- **Upload Types**: Use `uploadType=media` for simple uploads (up to 5MB), `uploadType=multipart` for uploads with metadata (up to 5MB), `uploadType=resumable` for large files (recommended for > 5MB)
- **Upload Endpoint**: File uploads use `/upload/drive/v3/files` (note the `/upload` prefix)
- **Resumable Uploads**: For large files, use resumable uploads with chunked transfer (256KB minimum chunk size, 5MB recommended)
- **Max File Size**: Google Drive supports files up to 5TB
- IMPORTANT: When using curl commands, use `curl -g` when URLs contain brackets (`fields[]`, `sort[]`, `records[]`) to disable glob parsing
- IMPORTANT: When piping curl output to `jq` or other commands, environment variables like `$MATON_API_KEY` may not expand correctly in some shell environments. You may get "Invalid API key" errors when piping.

## Error Handling

| Status | Meaning |
|--------|---------|
| 400 | Missing Google Drive connection |
| 401 | Invalid or missing Maton API key |
| 429 | Rate limited (10 req/sec per account) |
| 4xx/5xx | Passthrough error from Google Drive API |

### Troubleshooting: API Key Issues

**CLI:**

1. Check your auth state:

```bash
maton whoami
```

2. Verify the API key is valid by listing connections:

```bash
maton connection list
```

**Manual:**

1. Check that the `MATON_API_KEY` environment variable is set:

```bash
echo $MATON_API_KEY
```

2. Verify the API key is valid by listing connections:

```bash
python <<'EOF'
import urllib.request, os, json
req = urllib.request.Request('https://api.maton.ai/connections')
req.add_header('Authorization', f'Bearer {os.environ["MATON_API_KEY"]}')
print(json.dumps(json.load(urllib.request.urlopen(req)), indent=2))
EOF
```

### Troubleshooting: Invalid App Name

1. Ensure your URL path starts with `google-drive`. For example:

- Correct: `https://api.maton.ai/google-drive/drive/v3/files`
- Incorrect: `https://api.maton.ai/drive/v3/files`

## Resources

- [Drive API Overview](https://developers.google.com/drive/api/reference/rest/v3)
- [List Files](https://developers.google.com/drive/api/reference/rest/v3/files/list)
- [Get File](https://developers.google.com/drive/api/reference/rest/v3/files/get)
- [Create File](https://developers.google.com/drive/api/reference/rest/v3/files/create)
- [Update File](https://developers.google.com/drive/api/reference/rest/v3/files/update)
- [Delete File](https://developers.google.com/drive/api/reference/rest/v3/files/delete)
- [Export File](https://developers.google.com/drive/api/reference/rest/v3/files/export)
- [Upload Files](https://developers.google.com/drive/api/guides/manage-uploads)
- [Resumable Uploads](https://developers.google.com/drive/api/guides/manage-uploads#resumable)
- [Search Query Syntax](https://developers.google.com/drive/api/guides/search-files)
- [Maton CLI Manual](https://cli.maton.ai/manual)
- [Maton Community](https://discord.com/invite/dBfFAcefs2)
- [Maton Support](mailto:support@maton.ai)
