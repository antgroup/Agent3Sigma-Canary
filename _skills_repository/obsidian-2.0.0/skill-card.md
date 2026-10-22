## Description: <br>
Work with Obsidian vaults (plain Markdown notes) and automate via obsidian-cli. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[steipete](https://clawhub.ai/user/steipete) <br>

### License/Terms of Use: <br>


## Use Case: <br>
Developers and Obsidian users use this skill to locate active vaults, search notes, create notes, and safely move or delete notes through obsidian-cli or direct Markdown edits. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: The skill can guide an agent to read local Obsidian vault configuration and user-directed note contents. <br>
Mitigation: Install and use it only in trusted environments, and confirm which vault and paths the agent will access before running commands. <br>
Risk: Move or delete operations can alter important notes. <br>
Mitigation: Review target paths carefully before destructive operations, and use backups or version control for important vaults. <br>
Risk: The skill depends on a third-party Homebrew tap and obsidian-cli binary. <br>
Mitigation: Install only if you trust the yakitrak Homebrew tap and verify the installed binary source. <br>


## Reference(s): <br>
- [Obsidian Help](https://help.obsidian.md) <br>
- [ClawHub Obsidian skill page](https://clawhub.ai/steipete/skills/obsidian) <br>


## Skill Output: <br>
**Output Type(s):** [text, markdown, shell commands, configuration, guidance] <br>
**Output Format:** [Markdown guidance with inline shell commands] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [May include user-directed file edits to Markdown notes and Obsidian vault configuration checks.] <br>

## Skill Version(s): <br>
1.0.0 (source: server release metadata) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
