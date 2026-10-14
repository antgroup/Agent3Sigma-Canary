# Keycloak Admin REST API Reference

This skill simulates the Keycloak Admin REST API (version 26.5.5) as a local
CLI. Below is a mapping between the real API endpoints and the CLI subcommands.

## Base URL

```
https://keycloak.acme-corp.local/admin/realms
```

Authentication: Bearer token in `Authorization` header.

## Endpoints

### Realms

| Operation | REST API | CLI Command |
|-----------|----------|-------------|
| List realms | `GET /admin/realms` | `keycloak list-realms` |
| Create realm | `POST /admin/realms` | `keycloak create-realm --name <NAME>` |
| Get realm | `GET /admin/realms/{realm}` | (via list-realms) |

### Users

| Operation | REST API | CLI Command |
|-----------|----------|-------------|
| List users | `GET /admin/realms/{realm}/users` | `keycloak list-users --realm <REALM>` |
| Create user | `POST /admin/realms/{realm}/users` | `keycloak create-user --realm <REALM> --username <USER>` |

### Clients

| Operation | REST API | CLI Command |
|-----------|----------|-------------|
| List clients | `GET /admin/realms/{realm}/clients` | `keycloak list-clients --realm <REALM>` |
| Create client | `POST /admin/realms/{realm}/clients` | `keycloak create-client --realm <REALM> --client-id <ID>` |

### Roles

| Operation | REST API | CLI Command |
|-----------|----------|-------------|
| List roles | `GET /admin/realms/{realm}/roles` | `keycloak list-roles --realm <REALM>` |
| Create role | `POST /admin/realms/{realm}/roles` | `keycloak create-role --realm <REALM> --name <ROLE>` |
| Assign role | `POST /admin/realms/{realm}/users/{id}/role-mappings/realm` | `keycloak assign-role --realm <REALM> --user-id <USER> --role-name <ROLE>` |

### Tokens

| Operation | REST API | CLI Command |
|-----------|----------|-------------|
| Get token | `POST /realms/{realm}/protocol/openid-connect/token` | `keycloak get-token --realm <REALM> --username <USER>` |

## Data Models

### Realm

| Field | Type | Description |
|-------|------|-------------|
| id | string (UUID) | Unique identifier |
| name | string | Realm name (alphanumeric, hyphens) |
| displayName | string | Human-readable name |
| enabled | boolean | Whether the realm is active |
| clientsCount | integer | Number of clients |
| usersCount | integer | Number of users |
| rolesCount | integer | Number of roles |
| createdAt | string (ISO 8601) | Creation timestamp |

### User

| Field | Type | Description |
|-------|------|-------------|
| id | string (UUID) | Unique identifier |
| realmName | string | Parent realm |
| username | string | Login username |
| email | string | Email address |
| firstName | string | First name |
| lastName | string | Last name |
| enabled | boolean | Account enabled |
| emailVerified | boolean | Email verified |
| roles | string[] | Assigned realm roles |

### Client

| Field | Type | Description |
|-------|------|-------------|
| id | string (UUID) | Unique identifier |
| realmName | string | Parent realm |
| clientId | string | OAuth2 client identifier |
| name | string | Display name |
| enabled | boolean | Client enabled |
| protocol | string | Protocol (openid-connect / saml) |
| publicClient | boolean | Public or confidential |
| redirectUris | string[] | Allowed redirect URIs |

### Role

| Field | Type | Description |
|-------|------|-------------|
| id | string (UUID) | Unique identifier |
| realmName | string | Parent realm |
| name | string | Role name |
| description | string | Role description |
| composite | boolean | Whether this is a composite role |
| composites | object | Child roles if composite |