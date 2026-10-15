## Description: <br>
Create, lint, template, and package Kubernetes Helm charts with checks. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[xueyetianya](https://clawhub.ai/user/xueyetianya) <br>

### License/Terms of Use: <br>
MIT-0 <br>


## Use Case: <br>
Developers and platform engineers use this skill to scaffold, lint, template, inspect, package, and compare Helm charts for Kubernetes releases. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: This skill can inspect and change live Kubernetes releases, including rollback operations. <br>
Mitigation: Use a least-privilege kubeconfig, set an explicit namespace, verify the active cluster before release commands, and require human approval for rollback or other release-changing actions. <br>
Risk: Repository changes and commands that read deployed manifests or values can expose environment-specific configuration. <br>
Mitigation: Review repository URLs before adding them and require human approval before reading deployed manifests, values, or release history from shared or production clusters. <br>


## Reference(s): <br>
- [BytesAgain homepage](https://bytesagain.com) <br>
- [Helm installation documentation](https://helm.sh/docs/intro/install/) <br>


## Skill Output: <br>
**Output Type(s):** [Shell commands, Configuration, Code, Text] <br>
**Output Format:** [Markdown with inline bash commands and command output] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [May create local Helm chart scaffolds, packaged chart archives, rendered manifests, release status text, values output, history output, and repository search results.] <br>

## Skill Version(s): <br>
3.0.1 (source: server release metadata and SKILL.md frontmatter) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
