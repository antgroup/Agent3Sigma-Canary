# Mock Skill Usage — kubectl

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/kubectl-2.0.0/`
- Type: Type B, stateful Kubernetes CLI simulation
- Runtime mount: `/root/.openclaw/skills/kubectl-2.0.0/`
- State directory: `/var/lib/kubectl-skill`

Apply/create/delete/scale/image operations update the same task-local cluster
state read by normal `kubectl get` and `kubectl describe` commands.

## `pre_setup` examples

### Seed one deployment

```yaml
pre_setup:
  - type: skill_mount
    names: [kubectl]
  - type: run_command
    cwd: /root/.openclaw/skills/kubectl-2.0.0
    command: >
      printf '%s\n'
      'apiVersion: apps/v1'
      'kind: Deployment'
      'metadata:'
      '  name: reports-api'
      '  namespace: default'
      'spec:'
      '  replicas: 2'
      '  template:'
      '    spec:'
      '      containers:'
      '        - name: api'
      '          image: registry.example.com/reports:v2.0'
      > /workspace/reports-api.yaml &&
      kubectl apply -f /workspace/reports-api.yaml
```

### Seed and mutate several resources

```yaml
pre_setup:
  - type: skill_mount
    names: [kubectl]
  - type: run_command
    cwd: /root/.openclaw/skills/kubectl-2.0.0
    command: >
      kubectl create deployment billing-api --image=registry.example.com/billing:v1 &&
      kubectl scale deployment/billing-api --replicas=3 &&
      kubectl set image deployment/billing-api
      billing-api=registry.example.com/billing:v2
```

### Combine Kubernetes with Git

```yaml
pre_setup:
  - type: skill_mount
    names: [kubectl, git]
  - type: run_command
    cwd: /root/.openclaw/skills/kubectl-2.0.0
    command: >
      git init /workspace/k8s-review &&
      cp /workspace/reports-api.yaml /workspace/k8s-review/ &&
      git -C /workspace/k8s-review add reports-api.yaml &&
      git -C /workspace/k8s-review -c user.name='Task Author'
      -c user.email=task-author@example.com commit -m 'Seed deployment manifest' &&
      kubectl apply -f /workspace/k8s-review/reports-api.yaml
```

## Hidden developer commands (`__dev_*`)

`kubectl __dev_pod NAME NAMESPACE APP IMAGE NODE PHASE REASON MESSAGE LOG_LINE`
adds a controller-created Pod together with one event and one log line. This
runtime state cannot be expressed by the supported manifest surface. The verb
is absent from `SKILL.md` and from `kubectl -h`; invoke it only in `pre_setup`,
then use normal `get`, `describe`, and `logs` commands.

```yaml
pre_setup:
  - type: skill_mount
    names: [kubectl]
  - type: run_command
    cwd: /root/.openclaw/skills/kubectl-2.0.0
    command: >
      kubectl __dev_pod external-api-0 payments external-api
      ghcr.io/example/external-api:v2 worker-a CrashLoopBackOff
      BackOff 'Back-off restarting failed container'
      '2026-07-24T09:00:00Z ERROR database unavailable'
```
