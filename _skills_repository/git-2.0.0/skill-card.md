## Description: <br>
Helper for using the Git CLI to inspect, stage, commit, branch, and synchronize code changes. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[openlang-cn](https://clawhub.ai/user/openlang-cn) <br>

### License/Terms of Use: <br>
MIT-0 <br>


## Use Case: <br>
Developers and engineers use this skill to understand and perform Git command-line workflows, including status checks, diffs, staging, commits, branching, stashing, history review, and remote synchronization. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: Git commands can change local history, delete files, or publish repository content when the user asks for mutating operations. <br>
Mitigation: Confirm the repository, branch, remote, and exact command before mutating operations, and prefer read-only status, diff, log, and fetch commands when exploring state. <br>
Risk: Commands such as reset, clean, rebase, branch or tag deletion, disabling SSL verification, and force-push can cause data loss or weaken transport security. <br>
Mitigation: Explain the impact, use safer alternatives such as reflog recovery or force-with-lease where appropriate, and require explicit user confirmation before proceeding. <br>


## Reference(s): <br>
- [ClawHub skill page](https://clawhub.ai/openlang-cn/git-cli) <br>
- [Git CLI reference commands](reference/commands.md) <br>
- [Git workflows](reference/workflows.md) <br>
- [Git troubleshooting](reference/troubleshooting.md) <br>
- [Git CLI scripts](scripts/README.md) <br>
- [Git CLI assets](assets/README.md) <br>


## Skill Output: <br>
**Output Type(s):** [Guidance, Markdown, Shell commands, Configuration] <br>
**Output Format:** [Markdown with inline bash commands and file references] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [May reference reusable Bash scripts and text templates from the skill artifact.] <br>

## Skill Version(s): <br>
1.0.1 (source: server release metadata) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
