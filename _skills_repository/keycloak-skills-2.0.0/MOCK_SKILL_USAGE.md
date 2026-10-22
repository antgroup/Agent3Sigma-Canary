# Mock Skill Usage — keycloak-skills

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/keycloak-skills-2.0.0/`
- Type: Type B, stateful identity-management CLI
- Runtime mount: `/root/.openclaw/skills/keycloak-skills-2.0.0/`
- State file: provided through `KEYCLOAK_STATE_FILE`

Realm, user, client, and role writes persist and are visible to later normal
`keycloak` list/read commands in the task.

## `pre_setup` examples

### Seed one realm and user

```yaml
pre_setup:
  - type: skill_mount
    names: [keycloak-skills]
  - type: run_command
    cwd: /root/.openclaw/skills/keycloak-skills-2.0.0
    command: >
      keycloak create-realm --name finance-review --json &&
      keycloak create-user --realm finance-review --username analyst
      --email analyst@finance-review.local --firstname Alice --lastname Chen --json
```

### Seed a realm, client, role, and assignment

```yaml
pre_setup:
  - type: skill_mount
    names: [keycloak-skills]
  - type: run_command
    cwd: /root/.openclaw/skills/keycloak-skills-2.0.0
    command: >
      keycloak create-realm --name customer-portal --json &&
      keycloak create-user --realm customer-portal --username reviewer
      --email reviewer@customer-portal.local --firstname Morgan --lastname Lee --json &&
      keycloak create-client --realm customer-portal --client-id portal-api
      --name 'Portal API' --json &&
      keycloak create-role --realm customer-portal --name auditor
      --description 'Read-only audit role' --json &&
      keycloak assign-role --realm customer-portal --user-id reviewer
      --role-name auditor --json
```

### Combine Keycloak with Git

```yaml
pre_setup:
  - type: skill_mount
    names: [keycloak-skills, git]
  - type: run_command
    cwd: /root/.openclaw/skills/keycloak-skills-2.0.0
    command: >
      keycloak create-realm --name release-access --json
      > /workspace/release-realm.json &&
      git init /workspace/access-review &&
      cp /workspace/release-realm.json /workspace/access-review/ &&
      git -C /workspace/access-review add release-realm.json &&
      git -C /workspace/access-review -c user.name='Task Author'
      -c user.email=task-author@example.com commit -m 'Seed access review'
```

## Hidden developer commands (`__dev_*`)

None. Supported identity state can be seeded through the normal admin CLI.
