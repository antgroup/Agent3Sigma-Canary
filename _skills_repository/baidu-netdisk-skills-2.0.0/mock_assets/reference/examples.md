# Usage Examples

This document contains detailed usage examples for baidu-netdisk-skills.

---

## Upload and Share

### Example 1: Upload and Share a Single File

```
User: Please upload and share ./report.pdf
AI: [run bdpan upload ./report.pdf report.pdf]
    [run bdpan share report.pdf]

    Uploaded and shared successfully!
    Link: https://pan.baidu.com/s/1xxxxxxx
    extraction code: abcd
    Expiration: 7 days
```

### Example 2: Upload and Share a Folder

```
User: write ./project Upload and share folder
AI: [run bdpan upload ./project/ project/]
    [run bdpan share project]

    Folder uploaded and shared successfully!
    Link: https://pan.baidu.com/s/1xxxxxxx
    extraction code: efgh
    Expiration: 7 days
```

### Example 3: Upload to a Subdirectory

```
User: Upload ./data.tar.gz to backup directory and share
AI: [run bdpan upload ./data.tar.gz backup/data.tar.gz]
    [run bdpan share backup/data.tar.gz]

    Uploaded and shared successfully!
    Link: https://pan.baidu.com/s/1xxxxxxx
    extraction code: ijkl
    Expiration: 7 days
```

---

## Download Files

### Example 4: Download a Single File

```
User: Download from cloud storage report.pdf
AI: [run bdpan download report.pdf ./report.pdf]

    Downloading report.pdf → ./report.pdf ...
    ✓ Download successful
```

### Example 5: Download a Folder

```
User: write backup Download the folder locally
AI: [run bdpan download backup/ ./backup/]

    Downloading backup/ → ./backup/ ...
    ✓ Download successful
```

---

## File List

### Example 6: View Uploaded Files

```
User: See which files I uploaded
AI: [run bdpan ls]

    Type    Size          Modified              Filename
    ------  ------------  --------------------  --------
    directory     -            2026-02-20 10:30:00  backup
    file    1.5 MB        2026-02-25 15:20:00  report.pdf
    file    256 KB        2026-02-24 09:15:00  config.yaml

    Total 3 items
```

### Example 7: View a Subdirectory

```
User: view backup Files in the directory
AI: [run bdpan ls backup]

    Type    Size          Modified              Filename
    ------  ------------  --------------------  --------
    file    2.1 GB        2026-02-19 08:00:00  data-2026-02-19.tar.gz
    file    1.8 GB        2026-02-18 08:00:00  data-2026-02-18.tar.gz

    Total 2 items
```

---

## JSON Output (for Scripts)

### Example 8: File List in JSON Format

```
User: List all filenames (JSON format)
AI: [run bdpan ls --json]

    Output:
    [
      {
        "Name": "report.pdf",
        "IsDir": false,
        "Size": 1536000,
        "Modified": "2026-02-25T15:20:00Z"
      },
      {
        "Name": "backup",
        "IsDir": true,
        "Size": 0,
        "Modified": "2026-02-20T10:30:00Z"
      }
    ]
```

### Example 9: Process Output with jq

```bash
# Extract all filenames
bdpan ls --json | jq -r '.[].Name'

# List files only (exclude directories)
bdpan ls --json | jq '.[] | select(.IsDir == false)'

# Sort by size
bdpan ls --json | jq 'sort_by(.Size) | reverse'

# Check whether a file exists
bdpan ls --json | jq -e '.[] | select(.Name == "target.txt")'
```

---

## Authentication Flow

### Example 10: Log In (Always Use the login.sh Script)

> For login security requirements, see the “Security Requirements” section of [SKILL.md](../SKILL.md).

```
User: Help me log in to Baidu Netdisk
AI: [run bash ${CLAUDE_SKILL_DIR}/scripts/login.sh]

    [Show the security disclaimer]
    I have read the security notice above and confirm that I want to continue logging in? [y/N]

User: y
AI: Getting the authorization link...

    Open the following link in a browser to authorize:
    https://openapi.baidu.com/oauth/2.0/authorize?...

    After authorization succeeds, the browser will display an authorization code. Copy and paste it here:
    [Waiting for user input...]

User: [Paste the authorization code] ca0ee3070f75d0246357e5c74d525bda
AI: [Processing the authorization code]

    ✓ Login successful!
    User: username@baidu.com
```

---

## Save Shared Files to Netdisk

### Example 15: Save a shared link (extraction code in the link)

```
User: Help me save this link to Netdisk https://pan.baidu.com/s/1xxxxx?pwd=abcd
AI: [run bdpan transfer "https://pan.baidu.com/s/1xxxxx?pwd=abcd"]

    ✓ Saved successfully!
    File saved to: My App Data/bdpan/
```

### Example 16: Save to a specified directory

```
User: write https://pan.baidu.com/s/1xxxxx Save to shared directory, extraction code: efgh
AI: [run bdpan transfer "https://pan.baidu.com/s/1xxxxx" -p efgh -d shared/]

    ✓ Saved successfully!
    File saved to: My App Data/bdpan/shared/
```

### Example 17: Save and view the result (JSON)

```bash
bdpan transfer "https://pan.baidu.com/s/1xxxxx?pwd=abcd" --json
# Output:
# {
#   "status": "success",
#   "remote_path": "shared-file.pdf",
#   "share_link": "https://pan.baidu.com/s/1xxxxx",
#   "file_count": 1
# }
```

---

## Search files

### Example 18: Search files

```
User: Search in Netdisk report
AI: [run bdpan search report]

    Find 3 results (page 1 of 1 pages)

    #   Name              Type    Size      Modified
    --- ----------------- ------- --------- ----------------
    1   report.pdf        document    1.5 MB    2026-02-25 15:20
    2   report-draft.docx document    256 KB    2026-02-24 09:15
    3   report-backup     directory    -         2026-02-20 10:30
```

### Example 19: Search by type

```
User: Search for all image files in Netdisk
AI: [run bdpan search "" --category 3 --no-dir]

    Find 5 results (page 1 of 1 pages)

    #   Name              Type    Size      Modified
    --- ----------------- ------- --------- ----------------
    1   photo.jpg         Image    3.2 MB    2026-03-15 14:30
    2   screenshot.png    Image    1.1 MB    2026-03-10 09:20
    ...
```

---

## File management (move/copy/rename/create folder)

### Example 20: Move files

```
User: Move the file in Netdisk named report.pdf to backup directory
AI: [run bdpan mv report.pdf backup]

    Moved report.pdf -> backup
```

### Example 21: Copy files

```
User: Copy report.pdf to archive directory
AI: [run bdpan cp report.pdf archive]

    Copied report.pdf -> archive
```

### Example 22: Rename files

```
User: write draft.pdf Rename to final-report.pdf
AI: [run bdpan rename draft.pdf final-report.pdf]

    Renamed draft.pdf -> final-report.pdf
```

### Example 23: Create a folder

```
User: Create a projects Folder
AI: [run bdpan mkdir projects]

    Folder created: projects
```

### Example 24: Combined operation—create a directory and move files

```
User: Help me create a archive/2026 directory, then old-report.pdf move it there
AI: [run bdpan mkdir archive/2026]
    Folder created: archive/2026

    [run bdpan mv old-report.pdf archive/2026]
    Moved old-report.pdf -> archive/2026
```

---

## Advanced usage

### Example 12: Batch upload

```bash
# Upload everything in the current directory PDF file
for f in *.pdf; do
  bdpan upload "$f" "documents/$f"
done

# Upload and record the results
for f in *.pdf; do
  echo "Upload $f..."
  bdpan upload "$f" "documents/$f" --json | jq '.'
done
```

### Example 13: Automatic backup script

```bash
#!/bin/bash
# Daily Backup Script

DATE=$(date +%Y-%m-%d)
BACKUP_FILE="backup-${DATE}.tar.gz"

# Packaging
tar -czf "/tmp/${BACKUP_FILE}" ~/important-data/

# Upload
bdpan upload "/tmp/${BACKUP_FILE}" "backup/${BACKUP_FILE}"

# Cleanup
rm "/tmp/${BACKUP_FILE}"

echo "Backup completed: ${BACKUP_FILE}"
```

### Example 14: Check upload status

```bash
# Check whether the file has been uploaded
check_uploaded() {
  local file=$1
  bdpan ls --json | jq -e ".[] | select(.Name == \"${file}\")" > /dev/null
}

if check_uploaded "report.pdf"; then
  echo "File already exists"
else
  echo "File does not exist; starting upload..."
  bdpan upload ./report.pdf report.pdf
fi
```
