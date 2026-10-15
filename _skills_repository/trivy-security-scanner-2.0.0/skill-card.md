## Description: <br>
Run Trivy vulnerability scans on containers, filesystems, and IaC, then triage findings by exploitability, reachability, and business impact with AI-powered prioritization. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[charlie-morrison](https://clawhub.ai/user/charlie-morrison) <br>

### License/Terms of Use: <br>
MIT-0 <br>


## Use Case: <br>
Developers, DevSecOps teams, and security reviewers use this skill to run Trivy scans across images, filesystems, repositories, Kubernetes clusters, IaC, and SBOMs, then prioritize remediation using exploitability, reachability, fix availability, and compliance context. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: Installing or updating Trivy may require privileged package-manager changes. <br>
Mitigation: Verify the Trivy package source and approve any sudo, apt, or Homebrew changes before installation. <br>
Risk: Scans can collect sensitive vulnerability, secret, dependency, infrastructure, or Kubernetes context details. <br>
Mitigation: Scope the exact image, path, repository, SBOM, or cluster context before running scans and treat raw scan reports as sensitive. <br>
Risk: Exploitability enrichment may send CVE identifiers to FIRST and CISA services. <br>
Mitigation: Confirm that sharing CVE lists with those public enrichment services is acceptable for the environment before using enrichment steps. <br>


## Reference(s): <br>
- [Aqua Security Trivy Debian Repository](https://aquasecurity.github.io/trivy-repo/deb) <br>
- [FIRST EPSS API](https://api.first.org/data/v1/epss?cve=$CVES) <br>
- [CISA Known Exploited Vulnerabilities Catalog](https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json) <br>


## Skill Output: <br>
**Output Type(s):** [Text, Markdown, Code, Shell commands, Configuration, Guidance] <br>
**Output Format:** [Markdown with tables, inline shell commands, code blocks, and configuration examples] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [May include prioritized findings, remediation plans, accepted-risk entries, compliance mappings, trend comparisons, and CI/CD configuration.] <br>

## Skill Version(s): <br>
1.0.0 (source: server release metadata) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
