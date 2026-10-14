## Description: <br>
Query Prometheus monitoring data to check server metrics, resource usage, and system health. <br>

This skill is ready for commercial/non-commercial use. <br>

## Publisher: <br>
[Akellacom](https://clawhub.ai/user/Akellacom) <br>

### License/Terms of Use: <br>


## Use Case: <br>
Developers, operators, and site reliability engineers use this skill to query one or more Prometheus instances for server health, resource usage, alerts, targets, labels, and time-series data. <br>

### Deployment Geography for Use: <br>
Global <br>

## Known Risks and Mitigations: <br>
Risk: Prometheus credentials may be stored in local configuration files or environment variables. <br>
Mitigation: Use read-only, least-privilege credentials, restrict access to configuration files, and avoid committing prometheus.json or credential-bearing environment files. <br>
Risk: Queries connect to user-configured Prometheus endpoints and may expose monitoring data over the network. <br>
Mitigation: Install only trusted local scripts, configure trusted endpoints, prefer HTTPS, and avoid running the tool from untrusted directories that may contain unexpected .env files. <br>


## Reference(s): <br>
- [ClawHub skill page](https://clawhub.ai/Akellacom/prometheus) <br>


## Skill Output: <br>
**Output Type(s):** [text, markdown, code, shell commands, configuration, guidance] <br>
**Output Format:** [Markdown guidance with shell commands and JSON Prometheus query results] <br>
**Output Parameters:** [1D] <br>
**Other Properties Related to Output:** [Prometheus API responses are returned as JSON; multi-instance queries include per-instance success or error results.] <br>

## Skill Version(s): <br>
1.1.0 (source: package.json and server release metadata) <br>

## Ethical Considerations: <br>
Users should evaluate whether this skill is appropriate for their environment, review any generated or modified files before relying on them, and apply their organization's safety, security, and compliance requirements before deployment. <br>
