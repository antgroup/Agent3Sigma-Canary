## Description: <br>
Execute and manage Kubernetes clusters via kubectl commands, including querying resources, deploying applications, debugging containers, managing configurations, and monitoring cluster health. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[ddevaal](https://clawhub.ai/user/ddevaal) <br>

### License/Terms of Use: <br>
MIT <br>


## Use Case: <br>
Developers, platform engineers, and cluster operators use this skill to ask an agent for kubectl command guidance, troubleshooting steps, and helper-script workflows for Kubernetes administration. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: kubectl commands can modify or disrupt any Kubernetes cluster reachable through the active kubeconfig. <br>
Mitigation: Verify the active context and namespace, use least-privilege kubeconfig credentials, and require explicit approval before production changes. <br>
Risk: Destructive or sensitive operations such as delete, drain, exec, cp, rollout, and config-view can expose data or affect workloads. <br>
Mitigation: Prefer dry-run modes where supported and review high-impact commands before execution. <br>


## Reference(s): <br>
- [kubectl Command Reference](references/REFERENCE.md) <br>
- [Official kubectl Docs](https://kubernetes.io/docs/reference/kubectl/) <br>
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/) <br>
- [Kubernetes API Reference](https://kubernetes.io/docs/reference/generated/kubernetes-api/) <br>
- [Agent Skills Specification](https://agentskills.io/) <br>


## Skill Output: <br>
**Output Type(s):** [text, markdown, shell commands, configuration, guidance] <br>
**Output Format:** [Markdown with inline bash code blocks] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [May include kubectl commands, dry-run variants, troubleshooting sequences, and references to bundled helper scripts.] <br>

## Skill Version(s): <br>
1.0.0 (source: server release metadata, skill frontmatter, and README) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
