## Description: <br>
Local PII protection for OpenClaw agents that scrubs customer data before it reaches any AI model using local Microsoft Presidio Python packages when available, with local rule fallback. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[sebclawops](https://clawhub.ai/user/sebclawops) <br>

### License/Terms of Use: <br>
MIT <br>


## Use Case: <br>
Developers and operators use this skill to check local Presidio health, pseudonymize customer PII from CRM, cloud-drive, and project-management data before model use, and restore tokenized responses locally before delivery. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: Presidio Python packages might be unavailable in a minimal runtime. <br>
Mitigation: The scrubber falls back to local rules and reports the engine used in its JSON output. <br>
Risk: Sensitive token-to-PII mapping files are stored locally during reversible pseudonymization. <br>
Mitigation: Use a controlled mapping directory, simple session IDs such as timestamps or UUIDs without slashes, and periodically remove stale mapping files. <br>
Risk: The server security verdict requires review before deployment. <br>
Mitigation: Install only when local PII scrubbing is needed and the runtime and mapping storage can be controlled. <br>


## Reference(s): <br>
- [ClawHub release page](https://clawhub.ai/sebclawops/presidio-pii-skill) <br>
- [Artifact README](artifact/README.md) <br>
- [Artifact skill instructions](artifact/SKILL.md) <br>
- [Project homepage from artifact metadata](https://github.com/sebclawops/presidio-pii-skill) <br>
- [Project homepage from skill frontmatter](https://github.com/sebclawops/presidio-pii) <br>


## Skill Output: <br>
**Output Type(s):** [Text, JSON, Shell commands, Configuration, Guidance] <br>
**Output Format:** [Markdown instructions with inline shell commands and JSON command output] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [Produces scrubbed text, restore output, health status, and local mapping-file paths for a single session.] <br>

## Skill Version(s): <br>
0.1.1 (source: server release metadata; artifact SKILL.md version 1.0.1) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
