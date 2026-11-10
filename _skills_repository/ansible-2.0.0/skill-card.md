## Description: <br>
Infrastructure automation with Ansible. Use for server provisioning, configuration management, application deployment, and multi-host orchestration. Includes playbooks for OpenClaw VPS setup, security hardening, and common server configurations. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[botond-rackhost](https://clawhub.ai/user/botond-rackhost) <br>

### License/Terms of Use: <br>


## Use Case: <br>
Developers and infrastructure operators use this skill to get Ansible playbook guidance, commands, and configuration patterns for provisioning VPS hosts, applying security hardening, installing Node.js, and deploying OpenClaw services. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: Bundled inventory contains active real-looking host targets, and documented playbooks can modify remote systems if run unchanged. <br>
Mitigation: Replace the inventory with approved hosts before execution, then use --list-hosts, --limit, --check, and --diff to verify target scope and changes. <br>
Risk: Security hardening changes SSH and firewall settings, which can lock out administrators if applied to the wrong host or with incomplete access checks. <br>
Mitigation: Confirm console or out-of-band access before applying SSH or firewall changes, and validate allowed SSH ports and keys in a dry run first. <br>
Risk: Playbooks install and configure system packages, Node.js sources, npm packages, and services that may change over time. <br>
Mitigation: Review and pin external package sources for production, test in staging, and run with a narrow host limit before broader rollout. <br>


## Reference(s): <br>
- [ClawHub Skill Page](https://clawhub.ai/botond-rackhost/ansible-skill) <br>
- [Ansible Best Practices](references/best-practices.md) <br>
- [Ansible Modules Cheatsheet](references/modules-cheatsheet.md) <br>
- [Ansible Troubleshooting](references/troubleshooting.md) <br>
- [Ansible Documentation](https://docs.ansible.com/) <br>
- [Ansible Galaxy](https://galaxy.ansible.com/) <br>
- [geerlingguy Ansible Roles](https://github.com/geerlingguy?tab=repositories&q=ansible-role) <br>
- [Ansible for DevOps](https://www.ansiblefordevops.com/) <br>


## Skill Output: <br>
**Output Type(s):** [text, markdown, code, shell commands, configuration, guidance] <br>
**Output Format:** [Markdown with inline YAML and bash code blocks] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [Requires ansible and ansible-playbook binaries for execution-oriented workflows.] <br>

## Skill Version(s): <br>
0.1.0 (source: server release metadata) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
