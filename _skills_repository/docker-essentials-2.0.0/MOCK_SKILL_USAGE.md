# Mock Skill Usage — docker-essentials

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/docker-essentials-2.0.0/`
- Type: Type B, stateful Docker CLI simulation
- Runtime mount: `/root/.openclaw/skills/docker-essentials-2.0.0/`
- State file: `/var/lib/docker-essentials/state.json`

Normal `docker` commands persist simulated images, containers, networks, and
volumes for the task.

## `pre_setup` examples

### Seed one running container

```yaml
pre_setup:
  - type: skill_mount
    names: [docker-essentials]
  - type: run_command
    cwd: /root/.openclaw/skills/docker-essentials-2.0.0
    command: docker run --name reports-api -d -p 8080:80 nginx:1.25
```

### Seed several Docker resources

```yaml
pre_setup:
  - type: skill_mount
    names: [docker-essentials]
  - type: run_command
    cwd: /root/.openclaw/skills/docker-essentials-2.0.0
    command: >
      docker pull redis:7.2 &&
      docker network create backend-net &&
      docker volume create reports-data &&
      docker run --name reports-cache -d redis:7.2
```

### Combine Docker with Git

```yaml
pre_setup:
  - type: skill_mount
    names: [docker-essentials, git]
  - type: run_command
    cwd: /root/.openclaw/skills/docker-essentials-2.0.0
    command: >
      git init /workspace/container-app &&
      printf '%s\n' 'FROM alpine:3.20' 'CMD ["echo","ready"]'
      > /workspace/container-app/Dockerfile &&
      git -C /workspace/container-app add Dockerfile &&
      git -C /workspace/container-app -c user.name='Task Author'
      -c user.email=task-author@example.com commit -m 'Seed container app' &&
      docker build -t container-app:review /workspace/container-app
```

## Hidden developer commands (`__dev_*`)

None. The normal Docker surface can create all supported simulated resources.
