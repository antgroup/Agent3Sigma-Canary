## Description: <br>
Manage OrangeHRM human resources — handle employees, attendance, leave, recruitment, and performance KPIs via the OrangeHRM Admin CLI. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[OrangeHRM](https://clawhub.ai/user/orangehrm) <br>

### License/Terms of Use: <br>
GPL-3.0 <br>


## Use Case: <br>
HR administrators and managers use this skill to perform day-to-day HR operations through the OrangeHRM Admin CLI. After configuring ORANGEHRM_URL and ORANGEHRM_TOKEN, an agent can manage employee records, track attendance (punch in/out), handle leave requests (apply, approve, reject, check balances), manage recruitment candidates and interview schedules, and define performance KPIs. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: An OrangeHRM API token may be sent to the default server if ORANGEHRM_URL is unset. <br>
Mitigation: Set ORANGEHRM_URL explicitly to the intended OrangeHRM instance before running commands, use a dedicated least-privilege admin token, and rotate the token if commands were run without ORANGEHRM_URL set. <br>
Risk: Command outputs can contain employee personal data (names, emails, phone numbers, leave histories). <br>
Mitigation: Avoid sharing logs or command output externally and review outputs before disclosure. Apply role-based access controls on the OrangeHRM token. <br>


## Reference(s): <br>
- [ClawHub Skill Page](https://clawhub.ai/orangehrm/orangehrm) <br>
- [OpenClaw Documentation](https://docs.openclaw.ai) <br>
- [Artifact Skill Definition](artifact/SKILL.md) <br>


## Skill Output: <br>
**Output Type(s):** [Text, JSON, Markdown] <br>
**Output Format:** [JSON responses from the OrangeHRM Admin CLI, plain-text key-value output when --json is omitted] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [Commands call the OrangeHRM CLI with ORANGEHRM_TOKEN and ORANGEHRM_URL; command results are structured HR data objects.] <br>

## Skill Version(s): <br>
2.0.0 (source: server release metadata) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. Exercise caution when handling employee PII (personally identifiable information) exposed through HR system commands.