# Mock Skill Usage — trivy-security-scanner

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/trivy-security-scanner-2.0.0/`
- Type: Type A.2, scanner plus risk-enrichment APIs
- Runtime mount: `/root/.openclaw/skills/trivy-security-scanner-2.0.0/`
- Mutable inputs: image names, filesystem trees, and configuration files

## `pre_setup` examples

### Produce an image report

```yaml
pre_setup:
  - type: skill_mount
    names: [trivy-security-scanner]
  - type: run_command
    cwd: /root/.openclaw/skills/trivy-security-scanner-2.0.0
    command: >
      trivy image --format json --output /workspace/trivy-image.json
      registry.example.com/api:v2.3.1
```

### Produce a filesystem report

```yaml
pre_setup:
  - type: skill_mount
    names: [trivy-security-scanner]
  - type: run_command
    cwd: /root/.openclaw/skills/trivy-security-scanner-2.0.0
    command: >
      mkdir -p /workspace/trivy-app &&
      printf '%s\n' '{"dependencies":{"minimist":"0.0.8"}}'
      > /workspace/trivy-app/package.json &&
      trivy fs --format json --output /workspace/trivy-fs.json
      /workspace/trivy-app
```

## Hidden developer commands (`__dev_*`)

None. Findings are determined by caller-controlled scan targets, while EPSS
and KEV are read-only reference data rather than task-local mutable records.
