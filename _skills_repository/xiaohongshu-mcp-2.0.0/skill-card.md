## Description: <br>
Automate Xiaohongshu (RedNote) content operations using a Python client for the xiaohongshu-mcp server. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[Borye](https://clawhub.ai/user/Borye) <br>

### License/Terms of Use: <br>


## Use Case: <br>
Developers, operators, and social media teams use this skill to automate Xiaohongshu content research, feed and profile inspection, and note publishing through a local xiaohongshu-mcp server. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: The skill requires third-party local binaries and a logged-in Xiaohongshu account. <br>
Mitigation: Install only trusted upstream releases, verify binaries where possible, use a low-risk account, and stop the local server when not in use. <br>
Risk: The publish command can post content without a built-in confirmation step. <br>
Mitigation: Manually review each title, body, image URL, and tag before running publish commands. <br>


## Reference(s): <br>
- [ClawHub skill page](https://clawhub.ai/Borye/xiaohongshu-mcp) <br>
- [xiaohongshu-mcp upstream project](https://github.com/xpzouying/xiaohongshu-mcp) <br>
- [xiaohongshu-mcp releases](https://github.com/xpzouying/xiaohongshu-mcp/releases) <br>


## Skill Output: <br>
**Output Type(s):** [text, markdown, code, shell commands, configuration, guidance] <br>
**Output Format:** [Markdown guidance with shell commands and optional JSON or text command output] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [Requires a local xiaohongshu-mcp server on localhost:18060 and a logged-in Xiaohongshu session.] <br>

## Skill Version(s): <br>
1.0.0 (source: server release evidence) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
