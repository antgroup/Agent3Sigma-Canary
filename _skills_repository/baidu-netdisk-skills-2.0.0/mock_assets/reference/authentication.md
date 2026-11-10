# Authentication guide

This guide details the bdpan CLI login authentication process.

---

## Login methods

> **Security constraints:** For security restrictions on login methods, see the “Security Constraints” section of [SKILL.md](../SKILL.md). The agent must and can only perform login using the login.sh script.

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/login.sh
```

The script automatically handles the complete login process (disclaimer → user confirmation → obtain authorization link → validate authorization code → complete login).

---

## Verify login status

```bash
bdpan whoami
```

**Output when logged in:**
```
Authentication status: Logged in
Token Expires at: 2026-03-10 10:30:00
```

**Output when not logged in:**
```
Authentication status: Not logged in
Run bdpan login to log in
```

---

## Log out

```bash
bdpan logout
```

Clear locally stored authentication information (`~/.config/bdpan/config.json`).

---

## Frequently Asked Questions

### Token Expired Message After Login

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

### Authorization Link Invalid

**Symptoms:** The browser displays a message that the link is invalid after opening it

**Solution:**
1. Rerun the login script to get a new authorization link
2. Make sure to complete authorization while the link is valid (usually 10 minutes)

### Error After Entering Authorization Code

**Symptoms:** An error message appears after entering the authorization code

**Solution:**
1. Make sure the authorization code was copied in full, with no extra spaces
2. Check that the authorization code displayed in the browser matches the one entered
3. If it fails repeatedly, rerun the login script to get a new authorization code

---

## Configuration File Location

```
~/.config/bdpan/config.json
```

**Environment variables:**

| Environment Variable | Description | Default Value |
|---------|------|--------|
| `BDPAN_CONFIG_DIR` | Configuration file directory | `~/.config/bdpan` |

---

## Security Notes

- **OAuth 2.0**: Uses the authorization code flow; user passwords are not stored
- **Token storage**: Tokens are stored encrypted in the local configuration file
- **Automatic renewal**: The tool automatically refreshes tokens when they are about to expire

---

## Automatic Login Failure Scenarios

The following scenarios automatically switch to OOB mode:

| Scenario | Description |
|------|------|
| SSH remote login | No graphical interface |
| WSL environment | Limited WebView support |
| Desktop environment locked | WebView cannot open |
| Browser not installed | Cannot open WebView |

When switching to OOB mode, the tool automatically displays the authorization link, without requiring user intervention.
