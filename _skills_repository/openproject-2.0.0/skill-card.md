## Description: <br>
OpenProject CRUD skill that manages work packages, projects, groups, news, users, watchers, relations, notifications, time entries, comments, attachments, wiki pages, statuses, and more via OpenProject API v3 with API token auth for cloud and self-hosted instances. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[Abdelkrim](https://clawhub.ai/user/Abdelkrim) <br>

### License/Terms of Use: <br>
MIT-0 <br>


## Use Case: <br>
Developers, project managers, and operations teams use this skill to let an agent inspect and manage OpenProject resources through user-invoked API actions. It supports routine project administration, issue tracking, time tracking, notification handling, file attachment workflows, and selected Enterprise resources. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: The skill can create, update, delete, and execute actions across OpenProject resources when supplied with a valid API token. <br>
Mitigation: Use a dedicated least-privilege API token and review create, update, delete, custom-action, and OAuth commands before running them. <br>
Risk: Bulk notification commands can affect many notifications at once. <br>
Mitigation: Review commands that use --all or broad filters before execution. <br>
Risk: Attachment upload commands send local files to the configured OpenProject instance. <br>
Mitigation: Only upload files that are intended for that OpenProject workspace and verify the configured OP_HOST before use. <br>


## Reference(s): <br>
- [ClawHub skill page](https://clawhub.ai/Abdelkrim/openproject-by-altf1be) <br>
- [OpenProject API v3 coverage and limitations](docs/API-COVERAGE.md) <br>
- [OpenProject](https://www.openproject.org/) <br>


## Skill Output: <br>
**Output Type(s):** [text, markdown, shell commands, configuration, guidance] <br>
**Output Format:** [Markdown and command-line instructions with OpenProject API results returned as text or JSON-like output] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [Requires OP_HOST and OP_API_TOKEN environment variables; optional settings include OP_DEFAULT_PROJECT, OP_MAX_RESULTS, and OP_MAX_FILE_SIZE.] <br>

## Skill Version(s): <br>
2.0.0 (source: server release metadata and package.json) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
