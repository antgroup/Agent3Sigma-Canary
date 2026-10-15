## Description: <br>
Automates LimeSurvey survey management through the RemoteControl 2 JSON-RPC API, including survey, participant, response, question, group, export, invitation, and reporting workflows. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[olegantonov](https://clawhub.ai/user/olegantonov) <br>

### License/Terms of Use: <br>
MIT-0 <br>


## Use Case: <br>
Developers and operators use this skill to automate LimeSurvey administration tasks, including survey lifecycle management, participant handling, response export, invitation delivery, and reporting. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: The skill can export sensitive survey responses, participant records, tokens, and email addresses. <br>
Mitigation: Treat exported data as sensitive, avoid casual logging or printing, and store outputs only in approved locations. <br>
Risk: The skill can send participant invitations and reminders or mutate survey records. <br>
Mitigation: Use a dedicated least-privilege LimeSurvey service account and confirm survey IDs, recipient lists, and mutation intent before execution. <br>
Risk: Delete, import, and activation workflows can affect production survey state. <br>
Mitigation: Keep current backups and review changes before running destructive or state-changing operations in production. <br>


## Reference(s): <br>
- [ClawHub Skill Page](https://clawhub.ai/olegantonov/limesurvey-openclaw-skill) <br>
- [ClawHub Publisher Profile](https://clawhub.ai/user/olegantonov) <br>
- [Metadata Homepage](https://github.com/olegantonov/limesurvey-openclaw-skill) <br>
- [LimeSurvey RemoteControl 2 API Manual](https://www.limesurvey.org/manual/RemoteControl_2_API) <br>
- [LimeSurvey RemoteControl API Reference](https://api.limesurvey.org/classes/remotecontrol-handle.html) <br>
- [API Reference](references/api_reference.md) <br>
- [Examples](references/examples.md) <br>


## Skill Output: <br>
**Output Type(s):** [text, markdown, code, shell commands, configuration, guidance] <br>
**Output Format:** [Markdown guidance with inline shell and Python examples; scripts may produce JSON, CSV, Excel, PDF, or decoded export files depending on the requested LimeSurvey operation.] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [Requires LIMESURVEY_URL, LIMESURVEY_USER, and LIMESURVEY_PASSWORD environment variables for authenticated RemoteControl API access.] <br>

## Skill Version(s): <br>
1.2.2 (source: server release metadata) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
