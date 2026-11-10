# Troubleshooting Guide

This guide covers common issues and solutions when using the bdpan CLI.

---

## Authentication Issues

### Token Expiration

**Symptoms:**
```
Error: Token expired
Error: Token expired
```

**Solution:**
```bash
bdpan logout
bash ${CLAUDE_SKILL_DIR}/scripts/login.sh
```

> For login security restrictions, see the “Security Restrictions” section of [SKILL.md](../SKILL.md).

### WebView Won't Open

**Symptoms:** The browser or WebView window does not appear during login.

**Solution:**
The tool automatically falls back to OOB (Out-of-Band) mode. Follow these steps:

1. Copy the authorization link shown in the console:
   ```
   https://openapi.baidu.com/oauth/...?device_code=xxxxx
   ```

2. Open the link in a browser

3. After authorization is complete, the browser will display an authorization code

4. Copy the authorization code and paste it at the command-line prompt

5. Press Enter to confirm

**Example output:**
```
Open the following link in a browser to authorize:
https://openapi.baidu.com/oauth/2.0/authorize?response_type=device_code&client_id=...&device_code=xxxxx

After authorization succeeds, the browser will display an authorization code. Copy and paste it here:
[Waiting for the user to enter the authorization code...]
```

### Login Fails After Authorization

**Symptoms:** The authorization page completes, but login still fails.

**Solution:**
```bash
# Clear the configuration and try again
rm ~/.config/bdpan/config.json
bash ${CLAUDE_SKILL_DIR}/scripts/login.sh
```

---

## File Operation Issues

### Path Is Outside the Allowed Scope

**Symptoms:**
```
Error: Path is outside the allowed scope
Error: Path not in allowed range
```

**Solutions:**
Ensure all paths are under the `/apps/bdpan/` directory.

Error:
```bash
bdpan ls /my-documents
bdpan upload ./file.txt /other/file.txt
```

Correct:
```bash
bdpan ls my-documents
bdpan upload ./file.txt my-documents/file.txt
```

### Downloads/Uploads Fail Due to Chinese Paths

**Symptoms:**
```
Error: File not found
# The actual cause is using "/My App Data/bdpan/..." instead of "/apps/bdpan/..."
```

**Explanation:**
**"My App Data"** displayed in the Baidu Netdisk interface is a Chinese display name; the actual API path is **`/apps`**. Both directions need to be mapped:
- **When invoking commands**: Chinese path → API path (`My App Data` → `/apps`)
- **When displaying to users**: API path → Chinese path (`/apps` → `My App Data`)

**Path mapping:**
| User-visible name | Actual API path |
|-------------|-------------|
| My App Data | `/apps` |
| My App Data/bdpan | `/apps/bdpan` |

**Solutions:**
Use a relative path or an English API absolute path when invoking commands, and convert it to the Chinese name when displaying it to users:

```bash
# ✅ Use in commands API path
bdpan download report.pdf ./report.pdf

# ✅ Use the Chinese name when displaying to users
# "File uploaded to: My App Data/bdpan/report.pdf"

# ❌ Use a Chinese path in the command
bdpan download /My App Data/bdpan/report.pdf ./report.pdf

# ❌ Expose when displaying to users API path
# "File uploaded to:/apps/bdpan/report.pdf"
```

### File Does Not Exist

**Symptoms:**
```
Error: File not found
Error: File not found
```

**Solutions:**
1. Check whether the local file exists:
   ```bash
   ls -la <Local path>
   ```
2. Check whether the remote file exists:
   ```bash
   bdpan ls
   ```

### Upload/Download Timeout

**Symptoms:** The operation takes too long and times out, or a large file download is interrupted midway.

**Cause:** The Agent's Bash tool has an execution timeout limit (2 minutes by default, 10 minutes maximum). If downloading a large file takes longer than this limit, the process will be terminated.

**Solution:**
1. The agent should follow the **large file download strategy** in SKILL.md: ≤ 50MB download directly; > 50MB use `nohup` to download in the background + poll progress
2. If the background download still fails, suggest that the user run this directly in the terminal:
   ```bash
   bdpan download <Remote path> <Local path>
   ```
3. Check the stability of the network connection
4. For very large files, consider compressing/splitting them first:
   ```bash
   # Compress before uploading
   tar -czf archive.tar.gz large-folder/
   bdpan upload archive.tar.gz backup/archive.tar.gz
   ```

### Transfer Failed

**Symptoms:**
```
Error: Transfer failed
Error: Transfer failed
```

**Common Causes and Solutions:**

1. **The share link has expired**: Contact the sharer to generate a new link
2. **Incorrect extraction code**: Confirm that the extraction code is correct
   ```bash
   # Extraction code accepted -p Pass it in
   bdpan transfer "https://pan.baidu.com/s/1xxxxx" -p abcd
   # or include it in the link
   bdpan transfer "https://pan.baidu.com/s/1xxxxx?pwd=abcd"
   ```
3. **Insufficient cloud drive space**: Clear space in the cloud drive and try again

#### Error code errno=13045 (your own share link)

**Symptoms:**
```
Transfer failed: errno=13045, msg=prohibit transfer self share link
```

**Cause:**
This is a link that you created and shared yourself. The file is already in your cloud drive, so there is no need to transfer it again.

**How to handle it:**
- **Do not show the error to the user**; simply tell them the file is already in the cloud drive
- Use `bdpan ls` to find and display the file
- If needed, provide the share link for others to use

Example response:
```
✅ The file is already in your cloud drive!

File information:
- File name:example.pdf
- Location: My App Data/bdpan/example.pdf
- Size:1.2 MB

No transfer is needed; you can use it directly.
```

### Insufficient Permissions

**Symptoms:**
```
Error: Insufficient permissions
Error: Permission denied
```

**Solution:**
1. Check local file permissions:
   ```bash
   ls -l <Local path>
   ```
2. Make sure you have write permission for the target directory:
   ```bash
   ls -ld <Destination directory>
   ```

---

## Installation Issues

### Command Not Found

**Symptom:** `bdpan: command not found`

**Solution:**
```bash
# Run the installation script again
bash ${CLAUDE_SKILL_DIR}/scripts/install.sh

# or check whether ~/.local/bin is in PATH in
echo $PATH

# If missing, add it to PATH(Add to ~/.zshrc or ~/.bashrc)
export PATH="$HOME/.local/bin:$PATH"
```

### Downloaded the Wrong Architecture

**Symptom:** The binary cannot run or displays "exec format error"

**Solution:**
```bash
# Delete existing binary
rm ~/.local/bin/bdpan

# Reinstall
bash ${CLAUDE_SKILL_DIR}/scripts/install.sh
```

---

## JSON Output Issues

### Invalid JSON Output

**Symptom:** `--json` output cannot be parsed.

**Solution:**
1. Ensure there are no error messages in stdout
2. Check that the output contains only JSON content
3. Validate using `jq`:
   ```bash
   bdpan ls --json | jq .
   ```

---

## Platform-Specific Issues

### macOS

#### Gatekeeper Blocking

**Symptom:** Cannot open the application because it is from an unidentified developer.

**Solution:**
```bash
xattr -d com.apple.quarantine ~/.local/bin/bdpan
```

### Linux

#### Missing Dependencies

**Symptom:** The binary fails to run and reports missing libraries.

**Solution:**
Install the required dependencies (distribution-specific):
```bash
# Debian/Ubuntu
sudo apt-get install libc6

# Fedora/RHEL
sudo dnf install glibc
```

### Windows (WSL)

#### Path Issues

**Symptom:** Windows paths do not work correctly.

**Solution:**
Always use Unix-style paths in WSL:
```bash
# Correct
bdpan upload ./file.txt file.txt

# Error
bdpan upload .\\file.txt file.txt
```

---

## Get Help

### Check Version

```bash
bdpan version
```

### Get Command Help

```bash
bdpan --help
bdpan upload --help
bdpan download --help
```

### Enable Debug Mode

```bash
# Check whether the configuration file exists and its permissions
ls -la ~/.config/bdpan/

# Check the login status and Token Expiration
bdpan whoami
```

> **⛔ Security Warning:** Never use `cat` to view the contents of configuration files. Configuration files contain sensitive credentials such as access_token, and printing them in the terminal or conversation may lead to a leak.
