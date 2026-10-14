## Description: <br>
Perform authorized network reconnaissance and port scanning with Nmap to find open ports, detect services, identify vulnerabilities, and enumerate targets. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[nsahal](https://clawhub.ai/user/nsahal) <br>

### License/Terms of Use: <br>
MIT <br>


## Use Case: <br>
Security practitioners and developers use this skill to prepare Nmap commands and interpret scan outputs during authorized network reconnaissance, service discovery, and vulnerability checks. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: Nmap scans are active network actions and can be misused against targets the user is not authorized to test. <br>
Mitigation: Confirm ownership or written permission for each target before scanning, and avoid public, production, or third-party infrastructure without approval. <br>
Risk: Aggressive timing, sudo-based scans, vulnerability scripts, and exploit or auth NSE categories can increase operational impact. <br>
Mitigation: Use exact target scopes, start with conservative scan profiles when appropriate, and review privileged or aggressive commands before running them. <br>


## Reference(s): <br>
- [ClawHub skill page](https://clawhub.ai/nsahal/nmap-recon) <br>
- [ClawHub publisher profile](https://clawhub.ai/user/nsahal) <br>


## Skill Output: <br>
**Output Type(s):** [text, markdown, shell commands, guidance] <br>
**Output Format:** [Markdown with inline bash code blocks] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [Commands should be reviewed before execution and limited to explicitly authorized targets.] <br>

## Skill Version(s): <br>
1.0.0 (source: server release and artifact/skill.json) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
