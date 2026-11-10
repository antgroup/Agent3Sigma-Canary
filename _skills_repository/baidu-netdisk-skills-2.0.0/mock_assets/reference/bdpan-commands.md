# bdpan CLI Command Quick Reference

## Authentication Commands

### login - Log in and authorize

> **⛔ Agents must log in via the login script; directly calling `bdpan login` is prohibited. See the security constraints in [SKILL.md](../SKILL.md).**

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/login.sh
```

The script includes a security disclaimer and a complete OOB authorization flow. Use this script in all environments, whether GUI or non-GUI.

### logout - Log out

```bash
bdpan logout
```

Clear locally stored authentication information (`~/.config/bdpan/config.json`).

### uninstall - Completely uninstall

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/uninstall.sh
```

Completely uninstall the bdpan CLI, automatically performing the following actions:
1. Log out and clear authorization information
2. Delete the configuration directory (`~/.config/bdpan/`)
3. Delete the bdpan binary (`~/.local/bin/bdpan`)

**Options:**
- `--yes, -y` - Skip confirmation prompt (for automated scenarios)

**Environment variables:**
| Environment variable | Description | Default value |
|---------|------|--------|
| `BDPAN_INSTALL_DIR` | Binary installation directory | `~/.local/bin` |
| `BDPAN_CONFIG_DIR` | Configuration file directory | `~/.config/bdpan` |

### whoami - View authentication status

```bash
bdpan whoami
```

Display the current login status, username, and Token expiration information.

**Output when logged in:**
```
Authentication status: Logged in
Username: your_username
Token Expires at: 2026-04-04 10:30:00
```

**Options:**
- `--json` - Output in JSON format

---

## File operation commands

### upload - Upload files

```bash
bdpan upload <local> <remote>
```

| Parameter | Description |
|------|------|
| `local` | Local file or folder path |
| `remote` | Cloud drive destination path (relative to `/apps/bdpan/`) |

**Examples:**
```bash
# Upload a single file
bdpan upload ./report.pdf report.pdf

# Upload a folder
bdpan upload ./project/ project/

# Upload to a subdirectory
bdpan upload ./data.tar.gz backup/data.tar.gz
```

**Options:**
- `--json` - Output upload results in JSON format

### download - Download files

```bash
bdpan download <remote> <local> [Options]
```

| Parameter | Description |
|------|------|
| `remote` | Netdisk file/folder path (relative to `/apps/bdpan/`) **or** Baidu Netdisk share link |
| `local` | Local save path |

**Options:**
| Option | Description |
|------|------|
| `-p` | Extraction code (for share links, if not included in the link) |
| `-t` | Custom save directory (relative paths are automatically prefixed with `/apps/bdpan`; absolute paths are used directly) |
| `--json` | Output download results in JSON format |

**Examples:**
```bash
# Download a single file
bdpan download report.pdf ./downloaded-report.pdf

# Download a folder
bdpan download project/ ./project-restore/

# Download from a sharing link (the link includes the extraction code)
bdpan download "https://pan.baidu.com/s/1xxxxx?pwd=abcd" ./downloaded/

# Use -p Pass the extraction code separately
bdpan download "https://pan.baidu.com/s/1xxxxx" ./downloaded/ -p abcd

# Use -t Specify a custom transfer destination directory
bdpan download "https://pan.baidu.com/s/1xxxxx?pwd=abcd" ./downloaded/ -t my-folder
```

**Share link download notes:**
- Automatically recognizes the share link format `https://pan.baidu.com/s/1{surl}?pwd={pwd}`
- Shared files are first saved to the `/apps/bdpan/{date}/` directory (or the directory specified with `-t`)
- Then downloaded to the specified local path

### transfer - Save shared files to the netdisk (without downloading locally)

```bash
bdpan transfer <sharing link> [Options]
```

| Parameter | Description |
|------|------|
| `Share link` | Baidu Netdisk share link |

**Options:**
| Option | Description |
|------|------|
| `-p` | Extraction code (if not included in the link) |
| `-d` | Destination directory (relative paths are automatically prefixed with `/apps/bdpan`; defaults to the application root directory) |
| `--json` | Output save results in JSON format |

**Examples:**
```bash
# Basic usage - Transfer to the application root directory /apps/bdpan/
bdpan transfer "https://pan.baidu.com/s/1xxxxx" -p abcd

# The extraction code is included in the link
bdpan transfer "https://pan.baidu.com/s/1xxxxx?pwd=abcd"

# Specify the destination directory
bdpan transfer "https://pan.baidu.com/s/1xxxxx" -p abcd -d my-folder/

# JSON Output
bdpan transfer "https://pan.baidu.com/s/1xxxxx" -p abcd --json
```

**Difference from download:**
- `transfer` only transfers shared files to your own cloud drive; it does not download them locally
- `download` transfers the files first, then downloads them to a local path
- Suitable for scenarios where you only need to save files to your cloud drive and do not need local copies

### ls - View file list

```bash
bdpan ls [path]
```

| Parameter | Description | Default |
|------|------|--------|
| `path` | Directory path to view | Root directory |

**Options:**
- `--json` - JSON-formatted output

**Examples:**
```bash
# View the root directory
bdpan ls

# View subdirectories
bdpan ls backup

# JSON Output
bdpan ls --json
```

**Output format:**
```
Type    Size          Modified              Filename
------  ------------  --------------------  --------
directory     -            2026-02-20 10:30:00  documents
file    1.5 MB        2026-02-25 15:20:00  readme.txt
file    256 KB        2026-02-24 09:15:00  config.yaml

Total 3 items
```

### share - Create a sharing link

```bash
bdpan share <path>
```

| Parameter | Description |
|------|------|
| `path` | Path to the file or folder to share |

**Examples:**
```bash
# Share files
bdpan share report.pdf

# Share a folder
bdpan share project

# JSON Output
bdpan share --json report.pdf
```

**Output format:**
```
Share link created successfully!
Link: https://pan.baidu.com/s/1xxxxxxx
extraction code: abcd
Expiration: 7 days
```

### search - Search files

```bash
bdpan search <Keyword> [Options]
```

| Parameter | Description |
|------|------|
| `keyword` | Search keyword (required) |

**Options:**
| Option | Type | Default | Description |
|------|------|--------|------|
| `--category` | int | `0` | File type filter: 1=video, 2=audio, 3=image, 4=document, 5=application, 6=other, 7=torrent |
| `--page-size` | int | `5` | Number of items per page (maximum 50) |
| `--page` | int | `1` | Page number |
| `--no-dir` | bool | `false` | Show files only, excluding folders |
| `--dir-only` | bool | `false` | Show folders only |
| `--json` | - | - | Output in JSON format |

> `--no-dir` and `--dir-only` are mutually exclusive and cannot be used together.

**Example:**
```bash
# Search files
bdpan search report

# Search for image files
bdpan search photo --category 3

# Search files, excluding folders, with 10 items per page
bdpan search data --no-dir --page-size 10

# Turn the page
bdpan search report --page 2

# JSON Output
bdpan search report --json
```

**Output format:**
```
Find 15 results (page 1 of 3 pages)

#   Name              Type    Size      Modified
--- ----------------- ------- --------- ----------------
1   report.pdf        document    1.5 MB    2026-02-25 15:20
2   report-draft.docx document    256 KB    2026-02-24 09:15

Tip: Use --page 2 View the next page
```

### mv - Move files or folders

```bash
bdpan mv <Source path> <Destination directory>
```

| Parameter | Description |
|------|------|
| `Source path` | Path of the file or folder to move (relative to `/apps/bdpan/`) |
| `Target directory` | Path of the target directory (relative to `/apps/bdpan/`) |

**Example:**
```bash
# Move a file to a subdirectory
bdpan mv report.pdf backup

# Move a folder
bdpan mv old-project archive

# JSON Output
bdpan mv report.pdf backup --json
```

**Output format:**
```
Moved report.pdf -> backup
```

### cp - Copy files or folders

```bash
bdpan cp <Source path> <Destination directory>
```

| Parameter | Description |
|------|------|
| `Source path` | Path of the file or folder to copy (relative to `/apps/bdpan/`) |
| `Target directory` | Path of the target directory (relative to `/apps/bdpan/`) |

**Example:**
```bash
# Copy a file to a subdirectory
bdpan cp report.pdf backup

# Copy a folder
bdpan cp project project-copy

# JSON Output
bdpan cp report.pdf backup --json
```

**Output format:**
```
Copied report.pdf -> backup
```

### rename - Rename files or folders

```bash
bdpan rename <path> <New name>
```

| Parameter | Description |
|------|------|
| `Path` | Path of the file or folder to rename (relative to `/apps/bdpan/`) |
| `New name` | New filename (name only, without a path) |

**Example:**
```bash
# Rename file
bdpan rename old-name.pdf new-name.pdf

# Rename a file in a subdirectory
bdpan rename docs/draft.md final.md

# JSON Output
bdpan rename old-name.pdf new-name.pdf --json
```

**Output format:**
```
Renamed old-name.pdf -> new-name.pdf
```

### mkdir - Create a folder

```bash
bdpan mkdir <path>
```

| Parameter | Description |
|------|------|
| `Path` | Path of the folder to create (relative to `/apps/bdpan/`) |

**Example:**
```bash
# Create folder
bdpan mkdir backup

# Create nested directories
bdpan mkdir backup/2026/03

# JSON Output
bdpan mkdir backup --json
```

**Output format:**
```
Folder created: backup
```

---

## Version Management Commands

### update - Automatically Update Skill

> **Use `bash ${CLAUDE_SKILL_DIR}/scripts/update.sh` to update Skill files. CLI updates are managed by `bdpan` itself.**

```bash
# Check for and install updates (interactive; user confirmation required)
bash ${CLAUDE_SKILL_DIR}/scripts/update.sh

# Check for updates only; do not install
bash ${CLAUDE_SKILL_DIR}/scripts/update.sh --check

# Skip confirmation and update automatically (for automation scenarios)
bash ${CLAUDE_SKILL_DIR}/scripts/update.sh --yes
```

**Function description:**
- Get the latest Skill version information through the Baidu configuration interface
- Compare with the local VERSION file to determine whether an update is needed
- Download and extract the zip package to overwrite files, then update the VERSION file
- Supports SHA256 integrity verification (if the configuration includes a checksum)

**Options:**
| Option | Description |
|------|------|
| `--check, -c` | Check for updates only; do not install |
| `--yes, -y` | Skip user confirmation and automatically perform the update |
| `--help` | Display help information |

### version - View Version Information

```bash
# View the current version
bdpan version

# Check for updates
bdpan version --check
```

---

## init - View Installation Information (v3.4.0+)

```bash
bdpan init
```

Display the installation path, configuration file path, and PATH configuration recommendations.

**Output example:**
```
bdpan Installation information
────────────────────────────
Installation path: /home/user/.local/bin/bdpan
Configuration path: /home/user/.config/bdpan/config.json

PATH Configuration recommendation:
  export PATH="$HOME/.local/bin:$PATH"
```

---

## Global Options

| Option | Description |
|------|------|
| `--config-path <path>` | Specify the full path to the configuration file (for AI Agent integration) |
| `--json` | Output in JSON format |
| `--no-check-update` | Disable version update checks |
| `--help` | Display help |
| `--version` | Display version |

---

## JSON Output Format

### ls Command Output

```json
[
  {
    "fs_id": 524080722157776,
    "path": "My App Data/report.pdf",
    "server_filename": "report.pdf",
    "size": 1536000,
    "isdir": false,
    "md5": "a1b2c3d4e5f6...",
    "server_mtime": "2026-02-25T15:20:00+08:00",
    "server_ctime": "2026-02-25T14:00:00+08:00"
  },
  {
    "fs_id": 841873986109404,
    "path": "My App Data/documents",
    "server_filename": "documents",
    "size": 0,
    "isdir": true,
    "md5": "",
    "server_mtime": "2026-02-20T10:30:00+08:00",
    "server_ctime": "2026-02-20T09:00:00+08:00"
  }
]
```

**Field Descriptions:**

| Field | Type | Description |
|------|------|------|
| `fs_id` | number | Unique file ID |
| `path` | string | File path (Chinese display name, such as `Wode Yingyong Shuju/...`) |
| `server_filename` | string | File name |
| `size` | number | File size (bytes); directories are 0 |
| `isdir` | boolean | Whether it is a directory (`true`/`false`; note that Boolean values are lowercase) |
| `md5` | string | File MD5 value; an empty string for directories |
| `server_mtime` | string | Server modification time (ISO 8601 with timezone) |
| `server_ctime` | string | Server creation time (ISO 8601 with timezone) |

> **Note:** The `path` field returns a Chinese display name (`Wode Yingyong Shuju/...`), not an API path (`/apps/bdpan/...`). This path can be used directly when displaying it to users.

### share Command Output

```json
{
  "link": "https://pan.baidu.com/s/1xxxxxxx",
  "short_url": "xxxxxxx",
  "share_id": 25747091668,
  "period": 7,
  "pwd": "abcd"
}
```

### upload/download Command Output

```json
{
  "status": "success",
  "local_path": "./report.pdf",
  "remote_path": "report.pdf"
}
```

### transfer Command Output

```json
{
  "status": "success",
  "remote_path": "my-folder/shared-file.pdf",
  "share_link": "https://pan.baidu.com/s/1xxxxx",
  "file_count": 1
}
```

### search Command Output

```json
{
  "total": 15,
  "page": 1,
  "page_size": 5,
  "results": [
    {
      "fs_id": 524080722157776,
      "path": "My App Data/bdpan/report.pdf",
      "server_filename": "report.pdf",
      "size": 1536000,
      "isdir": false,
      "category": 4,
      "server_mtime": "2026-02-25T15:20:00+08:00"
    }
  ]
}
```

### mv/cp/rename/mkdir Command Output

```json
{
  "status": "ok"
}
```

---

## Path Rules

- All paths are relative to the application root directory `/apps/bdpan/`
- Relative paths are supported: `backup/data.tar.gz`
- Absolute paths are supported: `/apps/bdpan/backup/data.tar.gz`
- Path traversal using `..` is automatically blocked

> **⛔ Bidirectional Path Mapping Rules:** When calling bdpan commands, "Wode Yingyong Shuju" must be converted to `/apps`; when displaying paths to users, `/apps` must be converted to "Wode Yingyong Shuju". See the [Path Rules](../SKILL.md) section for details.

---

## Configuration File Location

```
~/.config/bdpan/config.json
```

**Environment variables:**

| Environment variable | Description | Default value |
|---------|------|--------|
| `BDPAN_CONFIG_PATH` | Full path to the configuration file (highest priority) | None |
| `BDPAN_CONFIG_DIR` | Configuration file directory | `~/.config/bdpan` |
| `BDPAN_INSTALL_DIR` | Binary installation directory | `~/.local/bin` |

**Configuration path priority (v3.4.0+):**
1. `--config-path` command-line argument (highest priority)
2. `BDPAN_CONFIG_PATH` environment variable
3. `BDPAN_CONFIG_DIR` environment variable + `config.json`
4. `~/.config/bdpan/config.json` (default path)

**Usage example:**
```bash
# Specify configuration with a command-line argument
bdpan --config-path /custom/path/config.json ls

# Specify configuration with an environment variable
export BDPAN_CONFIG_PATH=/custom/path/config.json
bdpan ls
```

### AI Agent Integration

When an AI Agent cannot read the configuration through the default path, it can be specified in the following way:

```python
import subprocess
import os

env = os.environ.copy()
env["BDPAN_CONFIG_PATH"] = "/home/user/.config/bdpan/config.json"

result = subprocess.run(
    ["bdpan", "ls", "--json"],
    env=env,
    capture_output=True,
    text=True
)
```

---

## Common Error Codes

| Error | Description | Solution |
|------|------|---------|
| Token expired | Token expired | Log in again |
| Path not allowed | Path is outside the allowed scope | Use a path under /apps/bdpan/ |
| File not found | File does not exist | Check whether the path is correct |
| errno=13045 | Your own share link | The file is already in the cloud drive; use `bdpan ls` to find it directly |

---

## Platform Support

| Feature | macOS | Linux | Windows (WSL) |
|------|-------|-------|---------------|
| Basic features | ✅ | ✅ | ✅ |
| WebView login | ✅ | - | - (WSL has no graphical interface; use OOB mode) |
