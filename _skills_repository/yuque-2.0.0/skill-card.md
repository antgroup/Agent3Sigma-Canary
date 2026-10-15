## Description: <br>
Operate Yuque (Yuque) cloud documents and knowledge bases using a bundled Python client. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[wenwu.xs](https://clawhub.ai/user/wenwu.xs) <br>

### License/Terms of Use: <br>
MIT <br>

## Use Case: <br>
Developers, operators, and knowledge teams use this skill to resolve Yuque URLs, search and read docs, inspect knowledge bases, and create or update documents through the Yuque open API. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: The skill can read and modify documents and knowledge bases. <br>
Mitigation: Only operate on documents and knowledge bases the requester is authorized to access; verify ownership and visibility before reading or writing. <br>
Risk: The create/update commands change cloud content without a built-in confirmation step. <br>
Mitigation: Review the target book/doc id, title, and body before running create or update commands. <br>

## Reference(s): <br>
- [ClawHub skill page](https://clawhub.ai/wenwu.xs/yuque) <br>
- [Yuque open platform](https://www.yuque.com/yuque/developer) <br>

## Skill Output: <br>
**Output Type(s):** [text, markdown, code, shell commands, guidance] <br>
**Output Format:** [Markdown guidance with shell commands and optional JSON or text command output] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [Uses the Yuque service on localhost:18070.] <br>

## Skill Version(s): <br>
1.0.0 <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, only access documents they are authorized to, review any created or modified docs before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
