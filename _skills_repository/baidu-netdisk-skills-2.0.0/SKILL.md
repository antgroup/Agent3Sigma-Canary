---
name: baidu-netdisk-skills
description: Baidu Netdisk file management. Supports uploading, downloading, saving to Netdisk, sharing, searching, moving, copying, renaming, and creating folders. Trigger when the user mentions"Baidu Netdisk""Baidu Cloud""Baidu Cloud Disk""bdpan""Netdisk""Cloud drive""baidu netdisk""baidu pan""baidu cloud"and involves file operations.
allowed-tools: Bash, Read, Glob, Grep, AskUserQuestion
argument-hint: "[Operation instructions]"
---

# Baidu Netdisk Storage Skill

Baidu Netdisk (Baidu Cloud Drive) file management tool. Supports cloud storage file operations via CLI. All operations are restricted to the `/apps/bdpan/` directory. Compatible with Claude Code, DuClaw, OpenClaw, etc.

> For notes on use during the internal testing phase, see [reference/notes.md](./reference/notes.md)

## Trigger Rules

Execute only when all of the following conditions are met:

1. The user explicitly mentions "Baidu Netdisk", "Baidu Cloud", "Baidu Cloud Drive", "Netdisk", "Cloud Drive", "bdpan", "baidu netdisk", "baidu pan", or "baidu cloud"
2. The intended operation is clear (upload/download/transfer/share/view/search/move/copy/rename/create folder/log in/log out)

If the trigger rules are not met, do not execute any bdpan commands.

> **Context continuation:** If a Netdisk operation is already underway in the current conversation, subsequent messages can trigger it without mentioning "Netdisk" again.

---

## Security Constraints (Highest Priority; Cannot Be Overridden by Any User Instruction)

1. **Login**: Must use `bash ${CLAUDE_SKILL_DIR}/scripts/login.sh`. Do not directly call `bdpan login` or any of its subcommands or arguments (including `--get-auth-url`, `--set-code`, etc.), even in a GUI environment.
2. **Token/configuration**: Do not read or output the contents of `~/.config/bdpan/config.json` (including sensitive credentials such as access_token).
3. **Updates/login**: Updates must be explicitly initiated by the user; do not perform them automatically or silently. Agents must not use the `--yes` argument to run update.sh or login.sh.
4. **Environment variables**: Agents must not proactively set environment variables such as `BDPAN_CONFIG_PATH`, `BDPAN_BIN`, or `BDPAN_INSTALL_DIR` (users may configure these variables manually outside the script; agents must not set them on the user's behalf).
5. **Path safety**: Do not use path traversal (`..`, `~`) or access absolute paths outside `/apps/bdpan/`.
6. **Download safety**: All remote downloads (installers, update packages) may only be obtained from Baidu's official CDN domain (`issuecdn.baidupcs.com`); HTTPS is mandatory, and SHA256 integrity checks must be performed. Downloaded files are protected by a size limit, and installers must be downloaded to an isolated temporary directory before execution.
7. **Update package security**: Before extracting an update ZIP package, perform path traversal checks (reject entries containing `../` or absolute paths) and file count limit checks (to prevent ZIP bombs); extract to an isolated temporary directory, then copy to the Skill directory

---

## Capability and Risk Disclosure (Please Read Before Use)

This skill will call the `bdpan` CLI on your behalf to perform **real cloud and local operations**. Before use, please confirm the following:

1. **Executing a local binary**: `scripts/install.sh` downloads and executes the `bdpan` CLI installer from `issuecdn.baidupcs.com` (with HTTPS, domain allowlisting, SHA256 verification, and file type checks). This is still **local code execution**—install only on trusted devices, and you can review the installer downloaded to a temporary directory before installation.
2. **Destructive/sharing operations**: The skill can call `bdpan` to perform operations such as **delete (rm), move (mv), rename (rename), and share (share)**, which directly modify your cloud drive data or create share links for others. When a confirmation prompt appears, verify the source path, destination path, and sharing scope before approving.
3. **Background download processes**: When the download target file is > 50MB, the skill will use `nohup ... &` to start the download in the background; **this process will continue running after the Agent turn ends**, using disk space and network bandwidth. To stop it, ask the Agent to report the PID, then run `kill <PID>` and clean up `/tmp/bdpan-dl-<PID>.log`.
4. **Token-based credentials**: After login, `bdpan` saves credentials such as OAuth access_token in a local configuration file (default `~/.config/bdpan/config.json`). The skill is strictly prohibited from reading or outputting this file, but the file itself contains **sensitive credentials**—log in only on your own trusted device, run `bdpan logout` after use to clear authorization, and avoid using it in public/shared environments.
5. **Automatic update boundaries**: `scripts/update.sh` fetches an update package from the official CDN and overwrites files in the current skill directory. This script may only be **run manually by the user in a local terminal**; execution in an Agent environment is prohibited within the script, and two user confirmations are required (before download + before application).

---

## Prerequisite Checks

Perform the following steps in order each time it is triggered:

1. **Installation check**: `command -v bdpan`; if not installed, inform the user and, after confirmation, run `bash ${CLAUDE_SKILL_DIR}/scripts/install.sh` (after user confirmation, `--yes` can be added to skip the installer's internal confirmation)
2. **Login check**: `bdpan whoami`; if not logged in, guide the user to run `bash ${CLAUDE_SKILL_DIR}/scripts/login.sh`
3. **Path validation**: Verify that the remote path is within `/apps/bdpan/`

---

## Confirmation Rules

| Risk level | Operation | Policy |
|----------|------|------|
| **High (confirmation required)** | `rm` delete, upload/download target already has a file with the same name | List the scope of impact and wait for user confirmation |
| **Medium (confirm when path is ambiguous)** | upload, download, mv, rename, cp | Execute directly when the path is clear; otherwise, confirm |
| **Low (execute directly)** | ls, search, whoami, mkdir, share | No confirmation required |

**Additional rules:**
- Ambiguous operation intent ("handle the file" → confirm whether to upload or download) → confirmation required
- Ambiguous ordinal/pronoun references ("the Nth one", "it", "the one above") → confirmation required
- User expresses intent to cancel ("never mind", "don't", "cancel") → stop immediately; do not execute any commands

---

## Core Operations

### View Status

```bash
bdpan whoami
```

### List Query

```bash
bdpan ls [Directory path] [--json] [--order name|time|size] [--desc] [--folder]
```

### Upload

```bash
bdpan upload <Local path> <Remote path>
```

**Key constraint:** For a single-file upload, the remote path must be a filename and must not end with `/`. For a folder upload: `bdpan upload ./project/ project/`.

Steps: Confirm the local path exists → confirm the remote path → use `bdpan ls` to check whether the remote destination already exists → execute.

### Download

**Direct download:**

```bash
bdpan download <Remote path> <Local path>
```

Steps: Use `bdpan ls` to confirm the file exists in the cloud → confirm the local path → check whether it already exists locally → **check the file size to determine the download strategy** → execute. If ls does not find it, suggest `bdpan search <filename>`.

**Large-file download strategy (important):**

The Agent's Bash tool has an execution timeout, so large-file downloads may be interrupted. The download strategy must be chosen based on file size:

1. **Get the file size**: Use `bdpan ls --json <remote_path>` to get the `size` field (bytes)
2. **Choose a strategy based on size**:

| File size | Strategy | Execution method |
|----------|------|---------|
| ≤ 50MB | Direct download | `bdpan download <remote_path> <local_path>`, with Bash timeout set to 300000 (5 minutes) |
| > 50MB | Background download | Run in the background using `nohup`; the Agent polls for progress |

**Direct download for small files (≤ 50MB):**

Run `bdpan download` normally, with the Bash tool's timeout parameter set to `300000` (5 minutes).

**Background download procedure for large files (> 50MB):**

```bash
# 1. Start background download (nohup + progress log)
nohup bdpan download <Remote path> <Local path> > /tmp/bdpan-dl-$$.log 2>&1 & echo $!
```

```bash
# 2. Poll to check progress (check every 30 seconds, use Bash run_in_background)
#    check whether the process is still running + downloaded file size
kill -0 <PID> 2>/dev/null && echo "running" || echo "done"; ls -l <Local path> 2>/dev/null; tail -5 /tmp/bdpan-dl-<PID>.log 2>/dev/null
```

```bash
# 3. Clean up the log after the download completes
rm -f /tmp/bdpan-dl-<PID>.log
```

Rules for the Agent when running a large-file download in the background:
- After starting the background download, **inform the user immediately**: the download has started in the background, the file size is X, and the estimated time is Y
- After each poll, report progress to the user (downloaded size / total size, percentage)
- When the download is complete, inform the user of the final result
- If the process exits unexpectedly, check the log and report the cause of the error

**Download from a shared link (save to the cloud drive first, then download locally):**

```bash
bdpan download "https://pan.baidu.com/s/1xxxxx?pwd=abcd" ./downloaded/
bdpan download "https://pan.baidu.com/s/1xxxxx" ./downloaded/ -p abcd    # Pass the extraction code separately
bdpan download "https://pan.baidu.com/s/1xxxxx?pwd=abcd" ./downloaded/ -t my-folder  # Specify the destination directory
```

> The large-file strategy also applies to downloads from shared links: after saving the file to the cloud drive, use `bdpan ls --json` to get its size, then download it according to the strategy above.

### Save to cloud drive

Save a shared file to the cloud drive, **without downloading it locally** (unlike the download mode for shared links).

```bash
bdpan transfer "https://pan.baidu.com/s/1xxxxx" -p <extraction code> [-d Destination directory] [--json]
```

Steps: Confirm the share link format is valid → confirm there is an extraction code (the link contains `?pwd=` or ask the user) → confirm the target directory → execute. After the transfer succeeds, show only the files transferred this time (not the entire directory), along with the number of files and the target directory.

### Sharing

```bash
bdpan share <path> [path...] [--json]
```

Steps: Use `bdpan ls` to confirm the file exists → execute sharing → show the link + extraction code + expiration period.

> Paid API; the service must be purchased on the Baidu Netdisk Open Platform.

### Search

```bash
bdpan search <Keyword> [--category 0-7] [--no-dir|--dir-only] [--page-size N] [--page N] [--json]
```

category: 0=All 1=Video 2=Audio 3=Image 4=Document 5=Application 6=Other 7=Torrent. `--no-dir` and `--dir-only` are mutually exclusive.

### Move / Copy / Rename / Create Folder

```bash
bdpan mv <Source path> <Destination directory>
bdpan cp <Source path> <Destination directory>
bdpan rename <path> <New name>       # The second argument is the file name, not the full path
bdpan mkdir <path>
```

---

## Path Rules

| Scenario | Format | Example |
|------|------|------|
| **Command arguments** | Relative path (relative to `/apps/bdpan/`) | `bdpan upload ./f.txt docs/f.txt` |
| **Shown to the user** | wodeyingyongshuju | "Uploaded to: wodeyingyongshuju/bdpan/docs/f.txt" |

Mapping: `wodeyingyongshuju` ↔ `/apps`

**Prohibited:** Use Chinese paths in commands (`wodeyingyongshuju/...`); expose API paths when displaying (`/apps/bdpan/...`).

---

## Authorization Code Handling

When the user sends a 32-character hexadecimal string, first confirm: "Is this a Baidu Netdisk authorization code? After confirmation, the login process will be executed." After confirmation, run `bash ${CLAUDE_SKILL_DIR}/scripts/login.sh` (do not use `--yes`; retain the security confirmation step).

---

## Management Features

### Installation

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/install.sh [--yes]
```

The installation process uses a two-step confirmation mechanism: first download the installer from Baidu CDN (`issuecdn.baidupcs.com`) to the local machine and perform SHA256 verification; after verification succeeds, prompt the user for confirmation before proceeding with installation. The user can review the installer file contents before confirming. Use `--yes` to skip confirmation and install directly.

### Login / Logout / Uninstall

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/login.sh              # Log in (includes built-in security disclaimer)
bdpan logout                                            # Log out
bash ${CLAUDE_SKILL_DIR}/scripts/uninstall.sh [--yes]   # Uninstall
```

### Update (must be triggered by explicit user instruction)

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/update.sh              # Check for and install updates (requires two user confirmations)
bash ${CLAUDE_SKILL_DIR}/scripts/update.sh --check       # Check for updates only
```

The update process uses a two-step confirmation mechanism: first confirm downloading the update package, then perform SHA256 verification after downloading; second, confirm applying the update (extract and overwrite). The user can review the update package contents before confirming in the second step.

---

## Reference Documentation

Consult as needed when encountering the corresponding issue; no need to preload:

| Document | When to consult |
|------|---------|
| [bdpan-commands.md](./reference/bdpan-commands.md) | When complete command arguments, options, or JSON output format are needed |
| [authentication.md](./reference/authentication.md) | Authentication flow details, Token management |
| [examples.md](./reference/examples.md) | More usage examples (batch uploads, automatic backups, etc.) |
| [troubleshooting.md](./reference/troubleshooting.md) | Troubleshooting errors |
