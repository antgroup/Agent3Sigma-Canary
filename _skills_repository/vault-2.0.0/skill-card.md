## Description: <br>
Secure local password storage tool with AES-256-GCM encryption. Store, retrieve, and manage passwords with CLI commands. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[zuiho-kai](https://clawhub.ai/user/zuiho-kai) <br>

### License/Terms of Use: <br>
MIT <br>


## Use Case: <br>
Developers and OpenClaw users use Vault to store, list, retrieve, and remove local passwords, API keys, and credentials through CLI-style commands. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: Using the skill lets OpenClaw store, reveal, and delete credentials when commanded, and plaintext secrets shown by the tool may appear in transcripts, logs, screenshots, or terminal history. <br>
Mitigation: Install only when agent-managed credential access is acceptable, use a strong master key, keep the vault file private, avoid high-value production secrets unless that access is acceptable, and use show commands carefully. <br>


## Reference(s): <br>
- [Vault ClawHub listing](https://clawhub.ai/zuiho-kai/vault) <br>
- [README](README.md) <br>
- [Changelog](CHANGELOG.md) <br>


## Skill Output: <br>
**Output Type(s):** [Text, Files, Configuration] <br>
**Output Format:** [Plain text command responses with encrypted local JSON storage] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [Requires Node.js, npm, and VAULT_MASTER_KEY; show commands may return plaintext secrets.] <br>

## Skill Version(s): <br>
1.1.2 (source: server release metadata, SKILL.md frontmatter, package.json, openclaw.plugin.json, CHANGELOG released 2026-02-17) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
