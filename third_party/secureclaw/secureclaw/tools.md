# SecureClaw Tools

## security_audit

Run a comprehensive security audit of this OpenClaw instance.

**Parameters:**
- `deep` (boolean, optional): Include active network probes. Default: false.
- `json` (boolean, optional): Output in JSON format. Default: false.

**Returns:** AuditReport with findings, score (0-100), and remediation steps.

## security_status

Get the current security posture including score, active monitor status, and recent alerts.

**Parameters:** None.

**Returns:** Security score, monitor status (credential, memory, cost), and recent alert count.

## skill_scan

Scan a ClawHub skill directory for malicious patterns before installation.

**Parameters:**
- `skill_name` (string, required): The name or path of the skill to scan.

**Returns:** SkillScanResult with safe/unsafe verdict, findings list, and matched patterns.

## cost_report

Show API cost tracking data including current spend, projections, and threshold alerts.

**Parameters:** None.

**Returns:** CostReport with hourly/daily/monthly spend, projections, and circuit breaker status.
