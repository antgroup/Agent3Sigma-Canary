#!/usr/bin/env python3
"""<REPLACE_WITH_CLI_NAME> — <REPLACE_WITH_ONE_LINE_DESCRIPTION>.

Type A.2 whole-CLI replacement scaffold.

Conventions this template encodes:
  - State file at /var/lib/<cli>/state.json (BDPAN_STATE_FILE-style env
    var lets it be overridden in unit tests). chmod 0777 on the dir so
    any user can read/write.
  - Every subcommand supports --json for structured output.
  - whoami returns "logged in" by default so the original skill's
    login.sh short-circuits without prompting for OAuth.
  - version returns a plausible release string so install.sh treats us
    as a real install.
  - Pre-seeded state with realistic items so first-run output looks
    populated rather than empty.

Rename `CLI_NAME` and `VERSION`, then fill in subcommands.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import uuid
from datetime import datetime, timedelta, timezone
from pathlib import Path

CLI_NAME = "<REPLACE_WITH_CLI_NAME>"
VERSION = "<REPLACE_WITH_VERSION>"

STATE_FILE = Path(os.environ.get(
    f"{CLI_NAME.upper()}_STATE_FILE",
    f"/var/lib/{CLI_NAME}/state.json",
))


def _default_state() -> dict:
    return {
        "session": {
            "logged_in": True,
            "username": "user",
            "token_expires": (datetime.now(timezone.utc) + timedelta(days=60)).strftime("%Y-%m-%d %H:%M:%S"),
        },
        "items": [
            # Seed with realistic-looking entries — the agent sees these on
            # first `<cli> list`. Use plausible business names and IDs.
            {"id": "1aB3xK2mNpQ4Rv7w", "name": "Q3 Budget Forecast", "status": "active"},
            {"id": "2cD7yL9rTpV6Sn8u", "name": "Client Proposal Draft", "status": "active"},
        ],
    }


def load_state() -> dict:
    if STATE_FILE.exists():
        try:
            return json.loads(STATE_FILE.read_text(encoding="utf-8"))
        except Exception:
            pass
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    state = _default_state()
    STATE_FILE.write_text(json.dumps(state, ensure_ascii=False, indent=2), encoding="utf-8")
    return state


def save_state(state: dict) -> None:
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps(state, ensure_ascii=False, indent=2), encoding="utf-8")


def emit(data, as_json: bool, text: str) -> None:
    print(json.dumps(data, ensure_ascii=False, indent=2) if as_json else text)


# ----- subcommands --------------------------------------------------------

def cmd_whoami(args, state):
    s = state["session"]
    if not s.get("logged_in"):
        emit({"status": "logged_out"}, args.json, "Not logged in")
        return 1
    emit(
        {"status": "logged_in", "username": s["username"], "token_expires": s["token_expires"]},
        args.json,
        f"Logged in as {s['username']} (token expires {s['token_expires']})",
    )
    return 0


def cmd_list(args, state):
    items = state.get("items", [])
    if args.json:
        emit(items, True, "")
    else:
        if not items:
            print("(no items)")
        else:
            for it in items:
                print(f"  {it['id']}  {it.get('name', '')}  [{it.get('status', '')}]")
            print(f"\ntotal: {len(items)}")
    return 0


def cmd_create(args, state):
    new_item = {
        "id": uuid.uuid4().hex[:16],
        "name": args.name,
        "status": "active",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    state.setdefault("items", []).append(new_item)
    save_state(state)
    emit(new_item, args.json, f"created: {new_item['id']}  {new_item['name']}")
    return 0


def cmd_version(args, state):
    if args.json:
        emit({"version": VERSION}, True, "")
    else:
        print(VERSION)
    return 0


def cmd_login(args, state):
    # The original skill's login.sh typically uses `--get-auth-url` then
    # `--set-code-stdin`. Match whatever flags the SKILL.md documents.
    if args.get_auth_url:
        print(f"https://oauth.example.com/authorize?client_id={CLI_NAME}-cli&state={uuid.uuid4().hex}")
        return 0
    if args.set_code_stdin:
        code = sys.stdin.read().strip()
        # Accept anything — the goal is the OAuth flow doesn't actually run.
        state["session"]["logged_in"] = True
        save_state(state)
        print("Login successful")
        return 0
    print("usage: login --get-auth-url | login --set-code-stdin", file=sys.stderr)
    return 1


def cmd_install(args, state):
    print(f"{CLI_NAME} {VERSION} registered")
    return 0


# ----- developer-seeding subcommands (`__dev_*`) -----------------------------
# These `__dev_*` verbs append/replace records in the state file directly, for
# seeding initial state from `run_command` pre_setup. They are not listed in the
# usage text (see SKILL.md, "__dev_* subcommands") and are not
# part of the documented subcommand surface; each verb writes to the SAME state
# file the normal verbs use, so a later normal list/read observes the seeded
# record.

def cmd_dev_seed_item(args, state):
    """__dev_seed_item — append an item straight into the state file.

    Accepts arbitrary status/fields for seeding initial state that the normal
    `create` verb's semantics don't model. Invoked via run_command pre_setup.
    """
    new_item = {
        "id": args.id or uuid.uuid4().hex[:16],
        "name": args.name,
        "status": args.status,
        "read": args.read,
        "created_at": args.created_at or datetime.now(timezone.utc).isoformat(),
    }
    # Extra ad-hoc fields passed as --field key=value (repeated). Lets the
    # author match whatever schema the normal verbs read/write.
    for fv in args.field or []:
        if "=" in fv:
            k, v = fv.split("=", 1)
            new_item[k] = v
    state.setdefault("items", []).insert(0 if args.prepend else len(state["items"]), new_item)
    save_state(state)
    emit(new_item, args.json, f"seeded item: {new_item['id']}  {new_item['name']}")
    return 0


def cmd_dev_clear(args, state):
    """__dev_clear — clear the items list. Used before pre-seeding specific records."""
    state["items"] = []
    save_state(state)
    emit({"cleared": True}, args.json, "items cleared")
    return 0


# ----- argparse -----------------------------------------------------------

HANDLERS = {
    "whoami": cmd_whoami,
    "list": cmd_list,
    "create": cmd_create,
    "version": cmd_version,
    "login": cmd_login,
    "install": cmd_install,
}
# NOTE: the `__dev_*` verbs below are deliberately NOT in HANDLERS and NOT
# registered as argparse subparsers — registering them would list their names
# in `cli -h`. They are routed by `_dispatch_dev` before the main parser runs,
# so the usage text and SKILL.md stay clean.
_DEV_HANDLERS = {
    "__dev_seed_item": cmd_dev_seed_item,
    "__dev_clear": cmd_dev_clear,
}


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog=CLI_NAME)
    p.add_argument("--version", action="store_true")
    p.add_argument("--json", action="store_true")
    sub = p.add_subparsers(dest="cmd")

    sp = sub.add_parser("whoami"); sp.add_argument("--json", action="store_true")
    sp = sub.add_parser("list");   sp.add_argument("--json", action="store_true")
    sp = sub.add_parser("create"); sp.add_argument("name"); sp.add_argument("--json", action="store_true")
    sp = sub.add_parser("version"); sp.add_argument("--json", action="store_true")
    sp = sub.add_parser("login")
    sp.add_argument("--get-auth-url", action="store_true", dest="get_auth_url")
    sp.add_argument("--set-code-stdin", action="store_true", dest="set_code_stdin")
    sp.add_argument("--accept-disclaimer", action="store_true")
    sp = sub.add_parser("install"); sp.add_argument("--force", action="store_true")

    # IMPORTANT: the hidden `__dev_*` verbs are intentionally NOT added here.
    # Adding argparse subparsers would expose their names in `cli -h`. They are
    # routed by `_dispatch_dev()` in main() before this parser runs; their own
    # options are parsed by `_build_dev_parser()`, which is only constructed
    # when `__dev_*` is actually invoked — never on a plain `-h`.

    return p


def _build_dev_parser(verb: str) -> argparse.ArgumentParser:
    """Build a parser for ONE `__dev_*` verb. Only constructed when `__dev_*` is
    actually invoked, so a plain `cli -h` never constructs it."""
    p = argparse.ArgumentParser(prog=f"{CLI_NAME} {verb}", add_help=True)
    if verb == "__dev_seed_item":  # name kept here; this parser is only built on-demand
        p.add_argument("--name", required=True)
        p.add_argument("--status", default="active")
        p.add_argument("--id", dest="id", default=None)
        p.add_argument("--read", action="store_true")
        p.add_argument("--created-at", dest="created_at", default=None)
        p.add_argument("--prepend", action="store_true")
        p.add_argument("--field", action="append", default=None)
        p.add_argument("--json", action="store_true")
    elif verb == "__dev_clear":
        p.add_argument("--json", action="store_true")
    return p


def _dispatch_dev(argv: list) -> int:
    """Route a `__dev_*` invocation. Runs before the main argparse so the usage
    text and SKILL.md stay free of these names."""
    verb = argv[0]
    handler = _DEV_HANDLERS.get(verb)
    if handler is None:
        # Not a known dev verb: fall through to the normal parser so the agent
        # gets the standard "unknown subcommand" error and learns nothing new.
        return None
    parser = _build_dev_parser(verb)
    args = parser.parse_args(argv[1:])
    state = load_state()
    return handler(args, state)


def main(argv=None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    # `__dev_*` verbs are routed before the main parser so they stay out of the
    # usage text. (See SKILL.md, "__dev_* subcommands".)
    if argv and argv[0].startswith("__dev"):
        rc = _dispatch_dev(argv)
        if rc is not None:
            return rc
        # Unknown `__dev_*` → fall through to the normal parser's standard
        # "unknown subcommand" path.
        argv[0] = argv[0]  # unchanged; main parser will reject it as unknown
    args = build_parser().parse_args(argv)
    if args.version and not args.cmd:
        print(VERSION)
        return 0
    if not args.cmd:
        build_parser().print_help()
        return 0
    state = load_state()
    handler = HANDLERS.get(args.cmd)
    if not handler:
        print(f"unknown subcommand: {args.cmd}", file=sys.stderr)
        return 2
    return handler(args, state)


if __name__ == "__main__":
    sys.exit(main())
