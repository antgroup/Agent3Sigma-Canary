#!/usr/bin/env python3
"""Keycloak Admin CLI — administer realms, users, clients, roles, and tokens.

Simulates the Keycloak Admin REST API as a local CLI so agents can manage
identity and access management without an external server.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import uuid
from datetime import datetime, timezone

VERSION = "2.0.0"

STATE_FILE = os.environ.get(
    "KEYCLOAK_STATE_FILE", "/var/lib/keycloak/state.json"
)

# ---------------------------------------------------------------------------
# State management
# ---------------------------------------------------------------------------

_SEED: dict = {}


def _default_state() -> dict:
    master_id = "a7c3e5f1-3d8b-4f6a-9e2d-1b4c6d8f0a2e"
    acme_id = "b8d4f6a2-5e9c-4a7b-8f3d-2c6e0a1b4d7f"
    admin_user_id = "c9e5a3b7-6f1d-4b8a-ad4e-3c7f1b9d2e6a"
    jdoe_user_id = "d0f6b4c8-7a2e-4c9b-be5f-4d8a2c0e1f3b"
    realm_admin_role_id = "e1a7c5d9-8b3f-4d0c-af6a-5e9b3d1f7a4c"
    employee_role_id = "f2b8d6e0-9c4a-4e1d-bg7b-6f0c4e2a8b5d"
    account_client_id = "a3c9e1b5-d0f7-4a2e-8c4b-7d1f9e3a5b6c"
    webapp_client_id = "b4d0f2c6-e1a8-4b3f-9d5c-8e2a0f4b6c7d"

    return {
        "realms": [
            {
                "id": master_id,
                "name": "master",
                "displayName": "Master Realm",
                "enabled": True,
                "clientsCount": 1,
                "usersCount": 1,
                "rolesCount": 1,
                "createdAt": "2025-01-15T08:00:00Z",
            },
            {
                "id": acme_id,
                "name": "acme-corp",
                "displayName": "ACME Corporation",
                "enabled": True,
                "clientsCount": 1,
                "usersCount": 1,
                "rolesCount": 1,
                "createdAt": "2025-03-20T10:30:00Z",
            },
        ],
        "users": [
            {
                "id": admin_user_id,
                "realmId": master_id,
                "realmName": "master",
                "username": "admin",
                "email": "admin@acme-corp.local",
                "firstName": "System",
                "lastName": "Administrator",
                "enabled": True,
                "emailVerified": True,
                "roles": ["realm-admin"],
                "createdTimestamp": 1705312800000,
            },
            {
                "id": jdoe_user_id,
                "realmId": acme_id,
                "realmName": "acme-corp",
                "username": "jdoe",
                "email": "john.doe@acme-corp.local",
                "firstName": "John",
                "lastName": "Doe",
                "enabled": True,
                "emailVerified": True,
                "roles": ["employee"],
                "createdTimestamp": 1711084800000,
            },
        ],
        "clients": [
            {
                "id": account_client_id,
                "realmId": master_id,
                "realmName": "master",
                "clientId": "account",
                "name": "Account Console",
                "enabled": True,
                "protocol": "openid-connect",
                "publicClient": False,
                "redirectUris": ["https://keycloak.acme-corp.local/realms/master/account/*"],
            },
            {
                "id": webapp_client_id,
                "realmId": acme_id,
                "realmName": "acme-corp",
                "clientId": "web-app",
                "name": "Web Application",
                "enabled": True,
                "protocol": "openid-connect",
                "publicClient": False,
                "redirectUris": ["https://app.acme-corp.local/*"],
            },
        ],
        "roles": [
            {
                "id": realm_admin_role_id,
                "realmId": master_id,
                "realmName": "master",
                "name": "realm-admin",
                "description": "Realm administration role with full access",
                "composite": True,
                "composites": {"realm": ["manage-realm", "manage-users", "manage-clients"]},
            },
            {
                "id": employee_role_id,
                "realmId": acme_id,
                "realmName": "acme-corp",
                "name": "employee",
                "description": "Standard employee role with basic access",
                "composite": False,
                "composites": None,
            },
        ],
    }


def load_state() -> dict:
    global _SEED
    if _SEED:
        return _SEED
    try:
        with open(STATE_FILE, encoding="utf-8") as f:
            _SEED = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        _SEED = _default_state()
        save_state(_SEED)
    return _SEED


def save_state(state: dict) -> None:
    global _SEED
    _SEED = state
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    with open(STATE_FILE, "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2, ensure_ascii=False)


def new_id() -> str:
    return str(uuid.uuid4())


# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

def emit(data, as_json: bool) -> None:
    if as_json:
        print(json.dumps(data, indent=2, ensure_ascii=False))
        return
    if isinstance(data, list):
        for item in data:
            _print_item(item)
            print()
    elif isinstance(data, dict):
        _print_item(data)
    else:
        print(data)


def _print_item(item: dict) -> None:
    for key, value in item.items():
        if isinstance(value, (dict, list)):
            print(f"{key}: {json.dumps(value, ensure_ascii=False)}")
        else:
            print(f"{key}: {value}")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _find_realm(state: dict, realm_ref: str) -> dict | None:
    for r in state["realms"]:
        if r["name"] == realm_ref or r["id"] == realm_ref:
            return r
    return None


def _find_user(state: dict, realm_name: str, user_ref: str) -> dict | None:
    for u in state["users"]:
        if u["realmName"] == realm_name and (
            u["id"] == user_ref or u["username"] == user_ref
        ):
            return u
    return None


def _now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


# ---------------------------------------------------------------------------
# Subcommands
# ---------------------------------------------------------------------------

def cmd_whoami(args: argparse.Namespace) -> None:
    result = {
        "username": "admin",
        "realm": "master",
        "email": "admin@acme-corp.local",
        "roles": ["realm-admin"],
        "authenticated": True,
    }
    emit(result, args.json)


def cmd_version(args: argparse.Namespace) -> None:
    result = {"version": VERSION, "keycloakVersion": "26.5.5", "profile": "product"}
    emit(result, args.json)


def cmd_list_realms(args: argparse.Namespace) -> None:
    state = load_state()
    realms = state["realms"]
    if not args.all:
        realms = [r for r in realms if r.get("enabled", True)]
    emit(realms, args.json)


def cmd_create_realm(args: argparse.Namespace) -> None:
    state = load_state()
    realm_id = new_id()
    realm = {
        "id": realm_id,
        "name": args.name,
        "displayName": args.name.replace("-", " ").replace("_", " ").title(),
        "enabled": args.enabled,
        "clientsCount": 0,
        "usersCount": 0,
        "rolesCount": 0,
        "createdAt": _now_iso(),
    }
    state["realms"].append(realm)
    save_state(state)
    emit(realm, args.json)


def cmd_create_user(args: argparse.Namespace) -> None:
    state = load_state()
    realm = _find_realm(state, args.realm)
    if not realm:
        print(f"Realm not found: {args.realm}", file=sys.stderr)
        sys.exit(1)
    user_id = new_id()
    user = {
        "id": user_id,
        "realmId": realm["id"],
        "realmName": realm["name"],
        "username": args.username,
        "email": args.email or f"{args.username}@{realm['name']}.local",
        "firstName": args.firstname or "",
        "lastName": args.lastname or "",
        "enabled": True,
        "emailVerified": False,
        "roles": [],
        "createdTimestamp": int(datetime.now(timezone.utc).timestamp() * 1000),
    }
    state["users"].append(user)
    realm["usersCount"] = realm.get("usersCount", 0) + 1
    save_state(state)
    emit(user, args.json)


def cmd_list_users(args: argparse.Namespace) -> None:
    state = load_state()
    realm = _find_realm(state, args.realm)
    if not realm:
        print(f"Realm not found: {args.realm}", file=sys.stderr)
        sys.exit(1)
    users = [u for u in state["users"] if u["realmName"] == realm["name"]]
    emit(users, args.json)


def cmd_create_client(args: argparse.Namespace) -> None:
    state = load_state()
    realm = _find_realm(state, args.realm)
    if not realm:
        print(f"Realm not found: {args.realm}", file=sys.stderr)
        sys.exit(1)
    client_id = new_id()
    client = {
        "id": client_id,
        "realmId": realm["id"],
        "realmName": realm["name"],
        "clientId": args.client_id,
        "name": args.name or args.client_id,
        "enabled": True,
        "protocol": "openid-connect",
        "publicClient": False,
        "redirectUris": [],
    }
    state["clients"].append(client)
    realm["clientsCount"] = realm.get("clientsCount", 0) + 1
    save_state(state)
    emit(client, args.json)


def cmd_list_clients(args: argparse.Namespace) -> None:
    state = load_state()
    realm = _find_realm(state, args.realm)
    if not realm:
        print(f"Realm not found: {args.realm}", file=sys.stderr)
        sys.exit(1)
    clients = [c for c in state["clients"] if c["realmName"] == realm["name"]]
    emit(clients, args.json)


def cmd_create_role(args: argparse.Namespace) -> None:
    state = load_state()
    realm = _find_realm(state, args.realm)
    if not realm:
        print(f"Realm not found: {args.realm}", file=sys.stderr)
        sys.exit(1)
    role_id = new_id()
    role = {
        "id": role_id,
        "realmId": realm["id"],
        "realmName": realm["name"],
        "name": args.name,
        "description": args.description or "",
        "composite": False,
        "composites": None,
    }
    state["roles"].append(role)
    realm["rolesCount"] = realm.get("rolesCount", 0) + 1
    save_state(state)
    emit(role, args.json)


def cmd_list_roles(args: argparse.Namespace) -> None:
    state = load_state()
    realm = _find_realm(state, args.realm)
    if not realm:
        print(f"Realm not found: {args.realm}", file=sys.stderr)
        sys.exit(1)
    roles = [r for r in state["roles"] if r["realmName"] == realm["name"]]
    emit(roles, args.json)


def cmd_assign_role(args: argparse.Namespace) -> None:
    state = load_state()
    realm = _find_realm(state, args.realm)
    if not realm:
        print(f"Realm not found: {args.realm}", file=sys.stderr)
        sys.exit(1)
    user = _find_user(state, realm["name"], args.user_id)
    if not user:
        print(f"User not found: {args.user_id} in realm {realm['name']}", file=sys.stderr)
        sys.exit(1)
    role = None
    for r in state["roles"]:
        if r["realmName"] == realm["name"] and r["name"] == args.role_name:
            role = r
            break
    if not role:
        print(f"Role not found: {args.role_name} in realm {realm['name']}", file=sys.stderr)
        sys.exit(1)
    if role["name"] not in user["roles"]:
        user["roles"].append(role["name"])
    save_state(state)
    result = {
        "userId": user["id"],
        "username": user["username"],
        "realm": realm["name"],
        "assignedRoles": user["roles"],
    }
    emit(result, args.json)


def cmd_get_token(args: argparse.Namespace) -> None:
    state = load_state()
    realm = _find_realm(state, args.realm)
    if not realm:
        print(f"Realm not found: {args.realm}", file=sys.stderr)
        sys.exit(1)
    user = _find_user(state, realm["name"], args.username)
    if not user:
        print(f"User not found: {args.username} in realm {realm['name']}", file=sys.stderr)
        sys.exit(1)

    # Simulate JWT token
    import base64
    header = base64.urlsafe_b64encode(
        json.dumps({"alg": "RS256", "typ": "JWT"}).encode()
    ).decode().rstrip("=")
    now_ts = int(datetime.now(timezone.utc).timestamp())
    payload_data = {
        "exp": now_ts + 300,
        "iat": now_ts,
        "jti": str(uuid.uuid4()),
        "iss": f"https://keycloak.acme-corp.local/realms/{realm['name']}",
        "aud": "account",
        "sub": user["id"],
        "typ": "Bearer",
        "azp": "admin-cli",
        "preferred_username": user["username"],
        "email": user["email"],
        "realm_access": {"roles": user["roles"]},
    }
    payload = base64.urlsafe_b64encode(
        json.dumps(payload_data).encode()
    ).decode().rstrip("=")
    signature = base64.urlsafe_b64encode(uuid.uuid4().bytes).decode().rstrip("=")
    token_str = f"{header}.{payload}.{signature}"

    result = {
        "access_token": token_str,
        "tokenType": "Bearer",
        "expiresIn": 300,
        "refreshExpiresIn": 1800,
        "refreshToken": f"{header}.{base64.urlsafe_b64encode(uuid.uuid4().bytes).decode().rstrip('=')}.{signature}",
        "scope": "openid profile email",
    }
    emit(result, args.json)


# ---------------------------------------------------------------------------
# Parser
# ---------------------------------------------------------------------------

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="keycloak",
        description="Keycloak Admin CLI — manage realms, users, clients, roles, and tokens",
    )
    parser.add_argument("--version", action="version", version=VERSION)
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # whoami
    p = subparsers.add_parser("whoami", help="Show current admin user info")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_whoami)

    # version
    p = subparsers.add_parser("version", help="Print version info")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_version)

    # list-realms
    p = subparsers.add_parser("list-realms", help="List all realms")
    p.add_argument("--all", action="store_true", help="Include disabled realms")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_list_realms)

    # create-realm
    p = subparsers.add_parser("create-realm", help="Create a new realm")
    p.add_argument("--name", required=True, help="Realm name")
    p.add_argument("--enabled", action="store_true", default=True, help="Enable realm (default: true)")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_create_realm)

    # create-user
    p = subparsers.add_parser("create-user", help="Create a user in a realm")
    p.add_argument("--realm", required=True, help="Realm name or id")
    p.add_argument("--username", required=True, help="Username")
    p.add_argument("--email", help="Email address")
    p.add_argument("--firstname", help="First name")
    p.add_argument("--lastname", help="Last name")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_create_user)

    # list-users
    p = subparsers.add_parser("list-users", help="List users in a realm")
    p.add_argument("--realm", required=True, help="Realm name or id")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_list_users)

    # create-client
    p = subparsers.add_parser("create-client", help="Create a client in a realm")
    p.add_argument("--realm", required=True, help="Realm name or id")
    p.add_argument("--client-id", required=True, help="Client ID")
    p.add_argument("--name", help="Client display name")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_create_client)

    # list-clients
    p = subparsers.add_parser("list-clients", help="List clients in a realm")
    p.add_argument("--realm", required=True, help="Realm name or id")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_list_clients)

    # create-role
    p = subparsers.add_parser("create-role", help="Create a role in a realm")
    p.add_argument("--realm", required=True, help="Realm name or id")
    p.add_argument("--name", required=True, help="Role name")
    p.add_argument("--description", help="Role description")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_create_role)

    # list-roles
    p = subparsers.add_parser("list-roles", help="List roles in a realm")
    p.add_argument("--realm", required=True, help="Realm name or id")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_list_roles)

    # assign-role
    p = subparsers.add_parser("assign-role", help="Assign a role to a user")
    p.add_argument("--realm", required=True, help="Realm name or id")
    p.add_argument("--user-id", required=True, help="User id or username")
    p.add_argument("--role-name", required=True, help="Role name")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_assign_role)

    # get-token
    p = subparsers.add_parser("get-token", help="Obtain an access token for a user")
    p.add_argument("--realm", required=True, help="Realm name or id")
    p.add_argument("--username", required=True, help="Username")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_get_token)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    args.func(args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())