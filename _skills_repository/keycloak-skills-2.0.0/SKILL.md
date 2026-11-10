---
name: keycloak-skills
description: Administer Keycloak identity and access management — manage realms, users, clients, roles, and tokens via the Keycloak Admin CLI.
metadata:
  openclaw:
    emoji: "🔑"
    requires:
      env:
        - KEYCLOAK_URL
        - KEYCLOAK_ADMIN_TOKEN
      bins:
        - python3
    primaryEnv: KEYCLOAK_ADMIN_TOKEN
version: "2.0.0"
author: "Tide Foundation"
license: "MIT"
---

# Keycloak Skills

Manage Keycloak identity and access management via the Admin CLI. Create realms,
users, clients, and roles; assign roles and obtain access tokens.

## Setup

The CLI authenticates as the admin user automatically. Set the environment
variables if you need to point at a different instance:

```bash
export KEYCLOAK_URL="https://keycloak.acme-corp.local"
export KEYCLOAK_ADMIN_TOKEN="your_admin_token_here"
```

## Available Commands

### list_realms

List all enabled realms (or all realms with `--all`).

```bash
bash scripts/list_realms.sh [--all] [--json]
# Or via CLI:
keycloak list-realms --json
```

Response (JSON): array of `{id, name, displayName, enabled, clientsCount, usersCount, rolesCount, createdAt}`

### create_realm

Create a new realm.

```bash
bash scripts/create_realm.sh --name <NAME> [--enabled] [--json]
keycloak create-realm --name test-project --json
```

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--name` | Yes | Realm name (alphanumeric, hyphens) |
| `--enabled` | No | Enable realm (default: true) |

Response: the created realm object with `id`, `name`, `displayName`, `enabled`, etc.

### create_user

Create a user in a realm.

```bash
bash scripts/create_user.sh --realm <REALM> --username <USER> [--email EMAIL] [--firstname FIRST] [--lastname LAST] [--json]
keycloak create-user --realm acme-corp --username analyst --email analyst@acme-corp.local --firstname Alice --lastname Chen --json
```

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--realm` | Yes | Realm name or id |
| `--username` | Yes | Username |
| `--email` | No | Email address (defaults to `<username>@<realm>.local`) |
| `--firstname` | No | First name |
| `--lastname` | No | Last name |

Response: the created user object with `id`, `realmName`, `username`, `email`, `roles`, etc.

### list_users

List users in a realm.

```bash
bash scripts/list_users.sh --realm <REALM> [--json]
keycloak list-users --realm acme-corp --json
```

Response: array of user objects.

### create_client

Create a client in a realm.

```bash
bash scripts/create_client.sh --realm <REALM> --client-id <CLIENT_ID> [--name NAME] [--json]
keycloak create-client --realm acme-corp --client-id backend-api --name "Backend API Service" --json
```

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--realm` | Yes | Realm name or id |
| `--client-id` | Yes | Client identifier |
| `--name` | No | Display name |

Response: the created client object with `id`, `realmName`, `clientId`, `protocol`, etc.

### list_clients

List clients in a realm.

```bash
bash scripts/list_clients.sh --realm <REALM> [--json]
keycloak list-clients --realm acme-corp --json
```

Response: array of client objects.

### create_role

Create a role in a realm.

```bash
bash scripts/create_role.sh --realm <REALM> --name <ROLE_NAME> [--description DESC] [--json]
keycloak create-role --realm acme-corp --name developer --description "Application developer role" --json
```

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--realm` | Yes | Realm name or id |
| `--name` | Yes | Role name |
| `--description` | No | Role description |

Response: the created role object with `id`, `realmName`, `name`, `composite`.

### list_roles

List roles in a realm.

```bash
bash scripts/list_roles.sh --realm <REALM> [--json]
keycloak list-roles --realm acme-corp --json
```

Response: array of role objects.

### assign_role

Assign a role to a user.

```bash
bash scripts/assign_role.sh --realm <REALM> --user-id <USER_ID> --role-name <ROLE> [--json]
keycloak assign-role --realm acme-corp --user-id jdoe --role-name developer --json
```

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--realm` | Yes | Realm name or id |
| `--user-id` | Yes | User id or username |
| `--role-name` | Yes | Role name to assign |

Response: `{userId, username, realm, assignedRoles}`

### get_token

Obtain an access token for a user.

```bash
bash scripts/get_token.sh --realm <REALM> --username <USER> [--json]
keycloak get-token --realm acme-corp --username jdoe --json
```

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--realm` | Yes | Realm name or id |
| `--username` | Yes | Username |

Response: `{access_token, tokenType, expiresIn, refreshExpiresIn, refreshToken, scope}`

## Tips

- Run `keycloak whoami` to verify the CLI is working and you are authenticated.
- Run `keycloak version` to check CLI and Keycloak version compatibility.
- All commands accept `--json` for structured output.
- Realm names are case-sensitive; use the exact `name` field from `list-realms`.
- User `--user-id` can be either the UUID `id` or the `username`.