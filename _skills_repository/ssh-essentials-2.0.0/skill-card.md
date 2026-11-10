## Description: <br>
Essential SSH commands for secure remote access, key management, tunneling, and file transfers. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[Arnarsson](https://clawhub.ai/user/Arnarsson) <br>

### License/Terms of Use: <br>


## Use Case: <br>
Developers and engineers use this skill as a concise SSH reference for secure remote access, key management, tunneling, file transfer, configuration, and troubleshooting tasks. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: Commands that disable host-key checking can make SSH connections vulnerable if the server identity is not verified another way. <br>
Mitigation: Keep strict host-key checking enabled for normal use, or verify the server through a trusted channel before using relaxed host-key options. <br>
Risk: Agent forwarding and background tunnels can expose credentials or network access beyond the intended session. <br>
Mitigation: Use agent forwarding and tunnels only for trusted hosts, limit their lifetime, and close background sessions when they are no longer needed. <br>
Risk: Destructive transfer examples such as rsync with --delete can remove remote files if paths are wrong. <br>
Mitigation: Run rsync with --dry-run and review source, destination, and exclude rules before using --delete. <br>


## Reference(s): <br>
- [OpenSSH](https://www.openssh.com/) <br>
- [OpenSSH Manual Pages](https://www.openssh.com/manual.html) <br>
- [ClawHub Skill Page](https://clawhub.ai/Arnarsson/ssh-essentials) <br>
- [Publisher Profile](https://clawhub.ai/user/Arnarsson) <br>


## Skill Output: <br>
**Output Type(s):** [text, markdown, shell commands, configuration, guidance] <br>
**Output Format:** [Markdown reference with shell command and configuration examples] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [Instruction-only reference; no hidden code execution or API calls.] <br>

## Skill Version(s): <br>
1.0.0 (source: server release metadata) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
