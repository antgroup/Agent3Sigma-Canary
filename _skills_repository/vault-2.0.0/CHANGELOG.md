# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.2] - 2026-02-17

### Security
- **CRITICAL**: Fixed security issue with fixed salt value
- Now uses random 32-byte salt per password (stored with encrypted data)
- Changed IV size from 16 bytes to 12 bytes (GCM recommended size)
- Each password now has unique salt for better key derivation security

### Changed
- Added `requiredEnv: ["VAULT_MASTER_KEY"]` to openclaw.plugin.json
- Updated encryption implementation to generate and store random salt per entry
- Modified decrypt function to use stored salt for key derivation
- Updated documentation to reflect security improvements

### Fixed
- Registry metadata now properly declares required VAULT_MASTER_KEY environment variable
- Addressed security concern about fixed salt reducing KDF effectiveness

## [1.1.0] - 2026-02-17

### Added
- **AES-256-GCM encryption** for all stored passwords
- Master key support via `VAULT_MASTER_KEY` environment variable or config
- Encryption class with scrypt key derivation
- Random IV (initialization vector) generation per password
- GCM authentication tags for integrity verification

### Changed
- Updated from plain text to encrypted storage format
- Modified `VaultStorage` class to support encryption/decryption
- Updated all documentation to reflect encryption features
- Changed description from "simple" to "secure" password storage
- Version bumped to 1.1.0

### Security
- **BREAKING**: Requires master key to be set (VAULT_MASTER_KEY or config.masterKey)
- Passwords now encrypted with AES-256-GCM before storage
- Each password uses unique random IV for enhanced security
- Authentication tags ensure data integrity
- Existing plain text passwords will need to be re-entered after upgrade

## [1.0.1] - 2026-02-17

### Changed
- Updated documentation to clearly state plain text storage
- Removed misleading "encryptionEnabled" config option (was not implemented)
- Added explicit security warnings about appropriate use cases
- Changed description from "secure" to "simple" password storage

### Security
- Clarified that this plugin uses plain text storage
- Added warnings about not using for production/sensitive credentials
- Recommended proper password managers for high-value secrets

## [1.0.0] - 2026-02-17

### Added
- Initial release
- Password storage and retrieval
- Commands: set, show, remove, list
- JSON-based local storage
- Automatic timestamp tracking (created/updated)
- Basic configuration support

### Security
- Plain text storage (encryption planned for future release)
- Local file system storage in user home directory
