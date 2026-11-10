## Description: <br>
Access Moodle LMS course, assignment, and completion data through the Moodle REST API using curl. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[altusrossouw](https://clawhub.ai/user/altusrossouw) <br>

### License/Terms of Use: <br>
MIT-0 <br>


## Use Case: <br>
External users and developers with Moodle web service access use the skill to configure MOODLE_URL and MOODLE_TOKEN, then ask an agent to list courses, inspect course content, and summarize assignment or completion status. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: A Moodle API token may be sent to the hard-coded default server if MOODLE_URL is unset. <br>
Mitigation: Set MOODLE_URL explicitly to the intended Moodle instance before running commands, use a dedicated least-privilege Moodle token, and rotate the token if examples were run without MOODLE_URL set. <br>
Risk: Command outputs can contain course, assignment, or user-specific LMS data. <br>
Mitigation: Avoid sharing logs or command output externally and review generated summaries before disclosure. <br>


## Reference(s): <br>
- [ClawHub Skill Page](https://clawhub.ai/altusrossouw/moodle) <br>
- [OpenClaw Documentation](https://docs.openclaw.ai) <br>
- [Artifact README](artifact/README.md) <br>
- [Artifact Skill Definition](artifact/SKILL.md) <br>


## Skill Output: <br>
**Output Type(s):** [Text, Markdown, Shell commands, Configuration, Guidance] <br>
**Output Format:** [Markdown with inline bash commands and JSON response descriptions] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [Commands call Moodle REST endpoints with MOODLE_TOKEN and MOODLE_URL; command results are Moodle JSON responses.] <br>

## Skill Version(s): <br>
1.0.0 (source: server release metadata) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
