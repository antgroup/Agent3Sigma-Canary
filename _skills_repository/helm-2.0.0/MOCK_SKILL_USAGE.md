# Mock Skill Usage — helm

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/helm-2.0.0/`
- Type: Type B utility simulation
- Runtime mount: `/root/.openclaw/skills/helm-2.0.0/`
- Mutable state: chart directories and packaged archives

Seed Helm tasks by creating concrete charts under `/workspace` with the normal
`helm` or skill wrapper commands.

## `pre_setup` examples

### Seed one chart

```yaml
pre_setup:
  - type: skill_mount
    names: [helm]
  - type: run_command
    cwd: /root/.openclaw/skills/helm-2.0.0
    command: >
      cd /workspace &&
      bash /root/.openclaw/skills/helm-2.0.0/scripts/script.sh create support-portal &&
      bash /root/.openclaw/skills/helm-2.0.0/scripts/script.sh lint support-portal
```

### Seed and package two charts

```yaml
pre_setup:
  - type: skill_mount
    names: [helm]
  - type: run_command
    cwd: /root/.openclaw/skills/helm-2.0.0
    command: >
      cd /workspace &&
      helm create billing-api &&
      helm create notification-worker &&
      helm package billing-api &&
      helm package notification-worker
```

### Combine Helm with Git

```yaml
pre_setup:
  - type: skill_mount
    names: [helm, git]
  - type: run_command
    cwd: /root/.openclaw/skills/helm-2.0.0
    command: >
      helm create /workspace/review-chart &&
      git init /workspace/review-chart &&
      git -C /workspace/review-chart add . &&
      git -C /workspace/review-chart -c user.name='Task Author'
      -c user.email=task-author@example.com commit -m 'Seed Helm chart'
```

## Hidden developer commands (`__dev_*`)

`helm __dev_release NAME NAMESPACE REVISION STATUS CHART APP_VERSION DESCRIPTION`
adds a release observed from the cluster to the same state used by normal
`list`, `status`, and `history` commands. It is absent from `SKILL.md` and
from `helm -h`; invoke it only from `pre_setup`.

```yaml
pre_setup:
  - type: skill_mount
    names: [helm]
  - type: run_command
    cwd: /root/.openclaw/skills/helm-2.0.0
    command: >
      helm __dev_release checkout-api payments 7 failed
      checkout-api-2.4.1 2.4.1
      'Upgrade failed after the readiness probe timed out'
```
