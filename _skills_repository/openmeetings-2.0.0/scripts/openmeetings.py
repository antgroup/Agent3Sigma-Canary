#!/usr/bin/env python3
"""Apache OpenMeetings Admin CLI — conference room management.

Simulates the Apache OpenMeetings REST API as a local CLI so agents can manage
conference rooms, participants, recordings, chat, and invitations.
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
    "OPENMEETINGS_STATE_FILE", "/var/lib/openmeetings/state.json"
)

# ---------------------------------------------------------------------------
# Seed state
# ---------------------------------------------------------------------------

_SEED = None  # In-memory cache


def _default_state():
    return {
        "current_user": {
            "userId": "admin",
            "firstName": "Admin",
            "lastName": "User",
            "email": "admin@acme-corp.local",
        },
        "rooms": [
            {
                "id": "room-a7c3e5f1",
                "name": "Weekly Standup",
                "type": "CONFERENCE",
                "capacity": 20,
                "public": True,
                "moderated": False,
                "allowRecording": True,
                "closed": False,
                "recording": False,
                "screenSharing": False,
                "redirectUrl": "",
            },
            {
                "id": "room-b8d4f6a2",
                "name": "Board Presentation",
                "type": "PRESENTATION",
                "capacity": 50,
                "public": False,
                "moderated": True,
                "allowRecording": True,
                "closed": False,
                "recording": False,
                "screenSharing": False,
                "redirectUrl": "",
            },
        ],
        "participants": [
            {
                "id": "part-c1e2a3b4",
                "roomId": "room-a7c3e5f1",
                "userId": "usr-f9e2d4a6",
                "firstName": "Sarah",
                "lastName": "Chen",
                "email": "sarah.chen@acme-corp.local",
                "joinedAt": "2026-07-13T09:00:00Z",
            },
        ],
        "recordings": [
            {
                "id": "rec-d5f6a7b8",
                "roomId": "room-b8d4f6a2",
                "startedAt": "2026-07-10T14:00:00Z",
                "stoppedAt": "2026-07-10T15:30:00Z",
                "status": "COMPLETED",
                "duration": "01:30:00",
            },
        ],
        "messages": [
            {
                "id": "msg-e1a2b3c4",
                "roomId": "room-a7c3e5f1",
                "userId": "usr-f9e2d4a6",
                "firstName": "Sarah",
                "lastName": "Chen",
                "message": "Good morning everyone!",
                "sentAt": "2026-07-13T09:02:00Z",
            },
        ],
        "events": [
            {
                "id": "evt-1a2b3c4d",
                "roomId": "room-a7c3e5f1",
                "type": "JOIN",
                "userId": "usr-f9e2d4a6",
                "firstName": "Sarah",
                "lastName": "Chen",
                "details": "Joined room",
                "timestamp": "2026-07-13T09:00:00Z",
            },
            {
                "id": "evt-5e6f7a8b",
                "roomId": "room-b8d4f6a2",
                "type": "RECORDING_START",
                "userId": "admin",
                "firstName": "Admin",
                "lastName": "User",
                "details": "Recording started",
                "timestamp": "2026-07-10T14:00:00Z",
            },
            {
                "id": "evt-9c0d1e2f",
                "roomId": "room-b8d4f6a2",
                "type": "RECORDING_STOP",
                "userId": "admin",
                "firstName": "Admin",
                "lastName": "User",
                "details": "Recording stopped",
                "timestamp": "2026-07-10T15:30:00Z",
            },
        ],
        "invitations": [],
    }


# ---------------------------------------------------------------------------
# State management
# ---------------------------------------------------------------------------

def load_state():
    global _SEED
    if _SEED is not None:
        return _SEED
    try:
        with open(STATE_FILE, encoding="utf-8") as f:
            _SEED = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError, PermissionError):
        _SEED = _default_state()
        try:
            save_state(_SEED)
        except (PermissionError, OSError):
            pass  # State will be in-memory only
    return _SEED


def save_state(state):
    global _SEED
    _SEED = state
    try:
        os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
        with open(STATE_FILE, "w", encoding="utf-8") as f:
            json.dump(state, f, indent=2, ensure_ascii=False)
    except (PermissionError, OSError):
        pass  # Graceful degradation for read-only environments


def new_id(prefix="id"):
    return f"{prefix}-{uuid.uuid4().hex[:8]}"


def _now_iso():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

def emit(data, as_json):
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


def _print_item(item):
    for key, value in item.items():
        if isinstance(value, (dict, list)):
            print(f"{key}: {json.dumps(value, ensure_ascii=False)}")
        else:
            print(f"{key}: {value}")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _find_room(state, room_id):
    for room in state["rooms"]:
        if room["id"] == room_id:
            return room
    return None


def _add_event(state, room_id, event_type, user_id, first_name, last_name, details):
    event = {
        "id": new_id("evt"),
        "roomId": room_id,
        "type": event_type,
        "userId": user_id,
        "firstName": first_name,
        "lastName": last_name,
        "details": details,
        "timestamp": _now_iso(),
    }
    state["events"].append(event)
    return event


# ---------------------------------------------------------------------------
# Subcommands
# ---------------------------------------------------------------------------

def cmd_version(args):
    emit({"version": VERSION, "openmeetingsVersion": "7.1.0"}, args.json)


def cmd_whoami(args):
    state = load_state()
    user = dict(state["current_user"])
    user["authenticated"] = True
    emit(user, args.json)


def cmd_create_room(args):
    state = load_state()
    room = {
        "id": new_id("room"),
        "name": args.name,
        "type": args.type.upper(),
        "capacity": args.capacity,
        "public": args.public,
        "moderated": args.moderated,
        "allowRecording": args.allow_recording,
        "closed": False,
        "recording": False,
        "screenSharing": False,
        "redirectUrl": "",
    }
    state["rooms"].append(room)
    _add_event(state, room["id"], "ROOM_CREATE", "admin",
               "Admin", "User", f"Room '{args.name}' created")
    save_state(state)
    emit(room, args.json)


def cmd_list_rooms(args):
    state = load_state()
    rooms = state["rooms"]
    if args.type:
        rooms = [r for r in rooms if r["type"] == args.type.upper()]
    emit(rooms, args.json)


def cmd_get_room(args):
    state = load_state()
    room = _find_room(state, args.room_id)
    if not room:
        print(f"Room not found: {args.room_id}", file=sys.stderr)
        sys.exit(1)
    # Include current participants
    parts = [p for p in state["participants"] if p["roomId"] == args.room_id]
    result = dict(room)
    result["participants"] = parts
    result["participantCount"] = len(parts)
    emit(result, args.json)


def cmd_join_room(args):
    state = load_state()
    room = _find_room(state, args.room_id)
    if not room:
        print(f"Room not found: {args.room_id}", file=sys.stderr)
        sys.exit(1)
    # Check if already in room
    for p in state["participants"]:
        if p["roomId"] == args.room_id and p["userId"] == args.user_id:
            print(f"User {args.user_id} is already in room {args.room_id}", file=sys.stderr)
            sys.exit(1)
    participant = {
        "id": new_id("part"),
        "roomId": args.room_id,
        "userId": args.user_id,
        "firstName": args.first_name or "User",
        "lastName": args.last_name or "",
        "email": f"{args.user_id}@acme-corp.local",
        "joinedAt": _now_iso(),
    }
    state["participants"].append(participant)
    _add_event(state, args.room_id, "JOIN", args.user_id,
               participant["firstName"], participant["lastName"], "Joined room")
    save_state(state)
    emit(participant, args.json)


def cmd_leave_room(args):
    state = load_state()
    room = _find_room(state, args.room_id)
    if not room:
        print(f"Room not found: {args.room_id}", file=sys.stderr)
        sys.exit(1)
    # Find and remove participant
    participant = None
    for i, p in enumerate(state["participants"]):
        if p["roomId"] == args.room_id and p["userId"] == args.user_id:
            participant = state["participants"].pop(i)
            break
    if not participant:
        print(f"User {args.user_id} not in room {args.room_id}", file=sys.stderr)
        sys.exit(1)
    _add_event(state, args.room_id, "LEAVE", args.user_id,
               participant["firstName"], participant["lastName"], "Left room")
    save_state(state)
    emit({"status": "left", "participant": participant}, args.json)


def cmd_invite(args):
    state = load_state()
    room = _find_room(state, args.room_id)
    if not room:
        print(f"Room not found: {args.room_id}", file=sys.stderr)
        sys.exit(1)
    invitation = {
        "id": new_id("inv"),
        "roomId": args.room_id,
        "roomName": room["name"],
        "hash": uuid.uuid4().hex[:16],
        "email": args.email,
        "firstName": args.first_name or "",
        "lastName": args.last_name or "",
        "valid": True,
        "createdAt": _now_iso(),
        "url": f"https://openmeetings.acme-corp.local/hash?{uuid.uuid4().hex[:16]}",
    }
    state["invitations"].append(invitation)
    _add_event(state, args.room_id, "INVITATION", "admin",
               "Admin", "User", f"Invitation sent to {args.email}")
    save_state(state)
    emit(invitation, args.json)


def cmd_share_screen(args):
    state = load_state()
    room = _find_room(state, args.room_id)
    if not room:
        print(f"Room not found: {args.room_id}", file=sys.stderr)
        sys.exit(1)
    if args.off:
        room["screenSharing"] = False
        action = "SCREEN_SHARING_STOP"
        details = f"Screen sharing stopped by {args.user_id}"
    else:
        room["screenSharing"] = True
        action = "SCREEN_SHARING_START"
        details = f"Screen sharing started by {args.user_id}"
    _add_event(state, args.room_id, action, args.user_id,
               "User", "", details)
    save_state(state)
    emit({"roomId": args.room_id, "screenSharing": room["screenSharing"]}, args.json)


def cmd_start_recording(args):
    state = load_state()
    room = _find_room(state, args.room_id)
    if not room:
        print(f"Room not found: {args.room_id}", file=sys.stderr)
        sys.exit(1)
    if room.get("recording"):
        emit({"status": "already_recording", "roomId": args.room_id}, args.json)
        return
    room["recording"] = True
    recording = {
        "id": new_id("rec"),
        "roomId": args.room_id,
        "startedAt": _now_iso(),
        "stoppedAt": None,
        "status": "RECORDING",
        "duration": None,
    }
    state["recordings"].append(recording)
    _add_event(state, args.room_id, "RECORDING_START", "admin",
               "Admin", "User", "Recording started")
    save_state(state)
    emit(recording, args.json)


def cmd_stop_recording(args):
    state = load_state()
    room = _find_room(state, args.room_id)
    if not room:
        print(f"Room not found: {args.room_id}", file=sys.stderr)
        sys.exit(1)
    if not room.get("recording"):
        print(f"Room {args.room_id} is not recording", file=sys.stderr)
        sys.exit(1)
    room["recording"] = False
    now = _now_iso()
    # Update the active recording
    for rec in state["recordings"]:
        if rec["roomId"] == args.room_id and rec["status"] == "RECORDING":
            rec["stoppedAt"] = now
            rec["status"] = "COMPLETED"
            # Calculate duration
            from datetime import datetime as dt
            try:
                start = dt.fromisoformat(rec["startedAt"].replace("Z", "+00:00"))
                end = dt.fromisoformat(now.replace("Z", "+00:00"))
                delta = end - start
                hours, remainder = divmod(int(delta.total_seconds()), 3600)
                minutes, seconds = divmod(remainder, 60)
                rec["duration"] = f"{hours:02d}:{minutes:02d}:{seconds:02d}"
            except Exception:
                rec["duration"] = "00:00:01"
            break
    _add_event(state, args.room_id, "RECORDING_STOP", "admin",
               "Admin", "User", "Recording stopped")
    save_state(state)
    # Return the completed recording
    for rec in state["recordings"]:
        if rec["roomId"] == args.room_id and rec["status"] == "COMPLETED" and rec["stoppedAt"] == now:
            emit(rec, args.json)
            return
    emit({"status": "stopped", "roomId": args.room_id}, args.json)


def cmd_chat(args):
    state = load_state()
    room = _find_room(state, args.room_id)
    if not room:
        print(f"Room not found: {args.room_id}", file=sys.stderr)
        sys.exit(1)
    message = {
        "id": new_id("msg"),
        "roomId": args.room_id,
        "userId": args.user_id,
        "firstName": args.first_name or "User",
        "lastName": args.last_name or "",
        "message": args.message,
        "sentAt": _now_iso(),
    }
    state["messages"].append(message)
    _add_event(state, args.room_id, "CHAT", args.user_id,
               message["firstName"], message["lastName"],
               f"Sent message: {args.message[:50]}")
    save_state(state)
    emit(message, args.json)


def cmd_history(args):
    state = load_state()
    events = [e for e in state["events"] if e["roomId"] == args.room_id]
    if args.type:
        events = [e for e in events if e["type"] == args.type.upper()]
    # Sort by timestamp descending
    events.sort(key=lambda e: e.get("timestamp", ""), reverse=True)
    if args.limit:
        events = events[:args.limit]
    emit(events, args.json)


# ---------------------------------------------------------------------------
# Parser
# ---------------------------------------------------------------------------

def build_parser():
    parser = argparse.ArgumentParser(
        prog="openmeetings",
        description="Apache OpenMeetings CLI — manage conference rooms and participants",
    )
    parser.add_argument("--version", action="version", version=VERSION)
    subparsers = parser.add_subparsers(dest="command", required=True)

    # version
    p = subparsers.add_parser("version", help="Print version info")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_version)

    # whoami
    p = subparsers.add_parser("whoami", help="Show current user info")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_whoami)

    # create-room
    p = subparsers.add_parser("create-room", help="Create a conference room")
    p.add_argument("--name", required=True, help="Room name")
    p.add_argument("--type", default="CONFERENCE", choices=["CONFERENCE", "PRESENTATION", "INTERVIEW"], help="Room type")
    p.add_argument("--capacity", type=int, default=20, help="Maximum participants")
    p.add_argument("--public", action="store_true", help="Public room")
    p.add_argument("--moderated", action="store_true", help="Room requires moderator")
    p.add_argument("--allow-recording", action="store_true", help="Allow recording")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_create_room)

    # list-rooms
    p = subparsers.add_parser("list-rooms", help="List conference rooms")
    p.add_argument("--type", choices=["CONFERENCE", "PRESENTATION", "INTERVIEW"], help="Filter by room type")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_list_rooms)

    # get-room
    p = subparsers.add_parser("get-room", help="Get room details with participants")
    p.add_argument("room_id", help="Room ID")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_get_room)

    # join-room
    p = subparsers.add_parser("join-room", help="Add participant to room")
    p.add_argument("room_id", help="Room ID")
    p.add_argument("--user-id", required=True, help="User ID")
    p.add_argument("--first-name", help="First name")
    p.add_argument("--last-name", help="Last name")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_join_room)

    # leave-room
    p = subparsers.add_parser("leave-room", help="Remove participant from room")
    p.add_argument("room_id", help="Room ID")
    p.add_argument("--user-id", required=True, help="User ID")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_leave_room)

    # invite
    p = subparsers.add_parser("invite", help="Generate invitation for a room")
    p.add_argument("room_id", help="Room ID")
    p.add_argument("--email", required=True, help="Invitee email address")
    p.add_argument("--first-name", help="Invitee first name")
    p.add_argument("--last-name", help="Invitee last name")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_invite)

    # share-screen
    p = subparsers.add_parser("share-screen", help="Toggle screen sharing in room")
    p.add_argument("room_id", help="Room ID")
    p.add_argument("--user-id", required=True, help="User ID toggling screen share")
    p.add_argument("--off", action="store_true", help="Stop screen sharing (default: start)")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_share_screen)

    # start-recording
    p = subparsers.add_parser("start-recording", help="Start recording in a room")
    p.add_argument("room_id", help="Room ID")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_start_recording)

    # stop-recording
    p = subparsers.add_parser("stop-recording", help="Stop recording in a room")
    p.add_argument("room_id", help="Room ID")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_stop_recording)

    # chat
    p = subparsers.add_parser("chat", help="Send chat message in room")
    p.add_argument("room_id", help="Room ID")
    p.add_argument("--user-id", required=True, help="User ID sending message")
    p.add_argument("--message", required=True, help="Chat message content")
    p.add_argument("--first-name", help="Sender first name")
    p.add_argument("--last-name", help="Sender last name")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_chat)

    # history
    p = subparsers.add_parser("history", help="List room events")
    p.add_argument("room_id", help="Room ID")
    p.add_argument("--type", choices=["JOIN", "LEAVE", "CHAT", "RECORDING_START", "RECORDING_STOP", "SCREEN_SHARING_START", "SCREEN_SHARING_STOP", "ROOM_CREATE", "INVITATION"], help="Filter by event type")
    p.add_argument("--limit", type=int, help="Maximum number of events to return")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_history)

    return parser


def main(argv=None):
    parser = build_parser()
    args = parser.parse_args(argv)
    args.func(args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())