---
name: vault
description: Secure local password storage tool with AES-256-GCM encryption. Store, retrieve, and manage passwords with CLI commands.
version: 1.1.2
author: zuiho-kai
homepage: https://github.com/zuiho-kai/openclaw-vault
tags: [password, vault, security, credentials, password-manager, cli, encryption]
metadata:
  openclaw:
    requires:
      bins: [node, npm]
      env: [VAULT_MASTER_KEY]
---

# vault

**Use when** you need secure local storage for passwords, API keys, or credentials.

🔒 **AES-256-GCM encryption** - This plugin stores passwords encrypted using industry-standard AES-256-GCM encryption with a master key.

## Features

- 🔒 AES-256-GCM encryption for all stored passwords
- 📝 Simple command-line interface
- 🗂️ Key management and listing
- 💾 JSON-based local storage (encrypted)
- 🕐 Automatic timestamp tracking
- 🔑 Master key protection

## Installation

```bash
clawhub install vault
```

## Usage

### Set a password

```bash
vault gemini sk-abc123xyz
```

### Show a password

```bash
vault gemini show
```

### Remove a password

```bash
vault gemini remove
```

### List all keys

```bash
vault list
```

## Configuration

### Master Key (Required)

Set your master encryption key via environment variable:

```bash
export VAULT_MASTER_KEY="your-secure-master-key-here"
```

Or in your OpenClaw config:

```json
{
  "plugins": {
    "vault": {
      "masterKey": "your-secure-master-key-here",
      "storageFile": ".vault/passwords.json"
    }
  }
}
```

**Options:**
- `masterKey` - Master encryption key (can also use VAULT_MASTER_KEY env var)
- `storageFile` (default: `.vault/passwords.json`) - Storage file path relative to home directory

⚠️ **Important**: Keep your master key secure! Without it, you cannot decrypt stored passwords.

## Security

🔒 **Encryption Details**:

- **Algorithm**: AES-256-GCM (Galois/Counter Mode)
- **Key Derivation**: scrypt with random salt per password
- **IV**: Random 12-byte initialization vector per password (GCM recommended size)
- **Salt**: Random 32-byte salt per password, stored with encrypted data
- **Authentication**: GCM authentication tag for integrity verification

**Security Best Practices**:
- Use a strong, unique master key (minimum 32 characters recommended)
- Store master key securely (environment variable or secure config)
- Set strict file permissions: `chmod 600 ~/.vault/passwords.json`
- Add `.vault/` to your `.gitignore`
- Never commit your master key to version control
- Use system-level disk encryption for additional protection
- Backup your master key securely - lost keys mean lost passwords

**Suitable for**:
- Development/testing credentials
- API keys and tokens
- Personal passwords
- Team shared credentials (with secure key distribution)

## Examples

```bash
# Save API keys
vault openai sk-proj-abc123
vault anthropic sk-ant-xyz789

# View a key
vault openai show
# Output: Password for 'openai': sk-proj-abc123

# List all keys
vault list
# Output:
# Stored passwords:
# • openai (created: 2026-02-17T..., updated: 2026-02-17T...)
# • anthropic (created: 2026-02-17T..., updated: 2026-02-17T...)

# Remove a key
vault openai remove
```

## Links

- GitHub: https://github.com/zuiho-kai/openclaw-vault
- Issues: https://github.com/zuiho-kai/openclaw-vault/issues
