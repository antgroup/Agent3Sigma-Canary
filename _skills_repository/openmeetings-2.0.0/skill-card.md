## Description: <br>
Manage Apache OpenMeetings conference rooms — create rooms, manage participants, control recordings, and chat via the OpenMeetings Admin CLI. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[API Evangelist](https://clawhub.ai/user/apievangelist) <br>

### License/Terms of Use: <br>
Apache-2.0 <br>


## Use Case: <br>
Teams and administrators use this skill to automate OpenMeetings conference room management, including room creation, participant management, screen sharing, recording control, and chat via a CLI interface. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: The OPENMEETINGS_SID session token grants administrative access to the OpenMeetings instance. <br>
Mitigation: Use a dedicated least-privilege service account, rotate the session token periodically, and never commit it to version control. <br>
Risk: Room recordings may contain sensitive audio and video content. <br>
Mitigation: Treat recording metadata and files as confidential, restrict access to completed recordings, and follow organizational data retention policies. <br>
Risk: Invitation links grant access to conference rooms without additional authentication. <br>
Mitigation: Use moderated rooms for sensitive meetings, set invitation expiry when possible, and audit invitation usage via the history command. <br>


## Reference(s): <br>
- [ClawHub Skill Page](https://clawhub.ai/apievangelist/openmeetings) <br>
- [OpenClaw Documentation](https://docs.openclaw.ai) <br>
- [Apache OpenMeetings Documentation](https://openmeetings.apache.org/) <br>
- [API Reference](references/api_reference.md) <br>


## Skill Output: <br>
**Output Type(s):** [Text, JSON, Markdown, Shell commands] <br>
**Output Format:** [CLI output in plain text or JSON depending on --json flag; includes room, participant, recording, and event data] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [Commands operate via the OpenMeetings Admin CLI with OPENMEETINGS_URL and OPENMEETINGS_SID environment variables; all state is persisted locally.] <br>

## Skill Version(s): <br>
2.0.0 (source: server release metadata) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment.