# Vault - Secure Password Storage

🔒 **AES-256-GCM encryption** - Secure local password storage with industry-standard encryption.

Secure local password storage tool with CLI interface and AES-256-GCM encryption.

## Features

- 🔒 AES-256-GCM encryption for all stored passwords
- 📝 Simple command-line interface
- 🗂️ Key management and listing
- 💾 JSON-based local storage (encrypted)
- 🕐 Automatic timestamp tracking
- 🔑 Master key protection

## Installation

```bash
cd /path/to/openclaw-vault
npm install
openclaw plugins link $(pwd)
```

## Configure the master key

**Required**: Set the master encryption key

Via environment variable:

```bash
export VAULT_MASTER_KEY="your-secure-master-key-here"
```

Or in the OpenClaw configuration:

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

⚠️ **Important**: Keep the master key safe! Without it, stored passwords cannot be decrypted.

## Usage

### Set a password

```bash
vault gemini sk-abc123xyz
```

Save the password for the key `gemini` as `sk-abc123xyz`.

### Show a password

```bash
vault gemini show
```

Show the password for the key `gemini`.

### Delete a password

```bash
vault gemini remove
```

Delete the password for the key `gemini`.

### List all keys

```bash
vault list
```

Show all saved keys and their creation/update times.

## Configuration

The following can be customized in the OpenClaw configuration:

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

### Configuration options

- `masterKey`: Master encryption key (the VAULT_MASTER_KEY environment variable can also be used)
- `storageFile`: Password storage file path (relative to the user's home directory)

## Storage location

Stored by default in `~/.vault/passwords.json` (encrypted format)

## Security features

🔒 **Encryption details**:

- **Algorithm**: AES-256-GCM (Galois/Counter Mode)
- **Key derivation**: scrypt with a random salt (unique to each password)
- **Initialization vector**: Each password uses a random 12-byte IV (the GCM recommended size)
- **Salt**: Each password uses a random 32-byte salt, stored alongside the encrypted data
- **Authentication**: The GCM authentication tag ensures integrity verification

**Security Best Practices**:
1. Use a strong and unique master key (at least 32 characters recommended)
2. Store the master key securely (environment variable or secure configuration)
3. Set strict file permissions: `chmod 600 ~/.vault/passwords.json`
4. Add `.vault/` to `.gitignore`
5. Never commit the master key to version control
6. Use system-level disk encryption for additional protection
7. Back up the master key securely - losing the key means losing all passwords

**Suitable for**:
- Development/testing credentials
- API keys and tokens
- Personal passwords
- Shared team credentials (requires secure distribution of the key)

## Examples

```bash
# Save API API key
vault openai sk-proj-abc123
vault anthropic sk-ant-xyz789

# View key
vault openai show
# Output: Password for 'openai': sk-proj-abc123

# List all keys
vault list
# Output:
# Stored passwords:
# • openai (created: 2026-02-17T..., updated: 2026-02-17T...)
# • anthropic (created: 2026-02-17T..., updated: 2026-02-17T...)

# Delete the password for key
vault openai remove
```

## License

MIT

## Authors

zuiho-kai
