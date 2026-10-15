---
name: openmeetings
description: Manage Apache OpenMeetings conference rooms — create rooms, manage participants, control recordings, and chat via the OpenMeetings Admin CLI.
metadata:
  openclaw:
    emoji: "🎥"
    requires:
      env:
        - OPENMEETINGS_URL
        - OPENMEETINGS_SID
      bins:
        - python3
    primaryEnv: OPENMEETINGS_SID
version: "2.0.0"
author: "API Evangelist"
license: "Apache-2.0"
---

# OpenMeetings

Manage Apache OpenMeetings conference rooms using the Admin CLI. Create and configure rooms, add and remove participants, control screen sharing and recordings, send chat messages, and generate invitation links.

## Setup

1. Ensure the OpenMeetings CLI is on your PATH (installed by the skill hook to `/usr/local/bin/openmeetings`)
2. Verify environment variables are set:

```bash
echo $OPENMEETINGS_URL   # e.g. https://openmeetings.example.com/openmeetings
echo $OPENMEETINGS_SID   # session ID for the Admin API
```

3. Confirm the CLI is working:

```bash
openmeetings version
openmeetings whoami
```

## Available Commands

### version

Print the CLI version and endpoint URL.

```bash
openmeetings version
openmeetings version --json
```

Response (JSON): `{"version": "2.0.0", "endpoint": "https://openmeetings.example.com/openmeetings"}`

### whoami

Show the currently authenticated user.

```bash
openmeetings whoami
openmeetings whoami --json
```

Response fields: `userId`, `firstName`, `lastName`, `email`, `timezone`, `endpoint`

### create-room

Create a new conference room with the specified settings.

```bash
openmeetings create-room --name "Project Review" --type CONFERENCE --capacity 10
openmeetings create-room --name "All-Hands" --type PRESENTATION --capacity 100 --public --moderated --allow-recording --json
```

| Parameter | Required | Default | Description |
|---|---|---|---|
| `--name` | Yes | — | Room name |
| `--type` | No | CONFERENCE | Room type: CONFERENCE, PRESENTATION, INTERVIEW |
| `--capacity` | No | 10 | Maximum number of participants |
| `--public` | No | false | Make the room publicly accessible |
| `--moderated` | No | false | Require a moderator in the room |
| `--allow-recording` | No | false | Allow recordings in this room |
| `--json` | No | false | Output as JSON |

Response fields: `id`, `name`, `type`, `capacity`, `public`, `moderated`, `allowRecording`, `closed`, `recording`, `screenSharing`

### list-rooms

List all conference rooms, optionally filtered by type.

```bash
openmeetings list-rooms
openmeetings list-rooms --type PRESENTATION --json
```

| Parameter | Required | Default | Description |
|---|---|---|---|
| `--type` | No | — | Filter by room type: CONFERENCE, PRESENTATION, INTERVIEW |
| `--json` | No | false | Output as JSON |

### get-room

Get detailed information about a specific room, including participant details.

```bash
openmeetings get-room room-a7c3e5f1
openmeetings get-room room-b8d4f6a2 --json
```

| Parameter | Required | Default | Description |
|---|---|---|---|
| `room_id` | Yes | — | Room ID |
| `--json` | No | false | Output as JSON |

### join-room

Add a participant to a room. The user must not already be in the room.

```bash
openmeetings join-room room-a7c3e5f1 --user-id usr-test01 --first-name Wei --last-name Zhang
openmeetings join-room room-b8d4f6a2 --user-id usr-f9e2d4a6 --first-name Sarah --last-name Chen --json
```

| Parameter | Required | Default | Description |
|---|---|---|---|
| `room_id` | Yes | — | Room ID |
| `--user-id` | Yes | — | User identifier |
| `--first-name` | No | Unknown | Participant first name |
| `--last-name` | No | — | Participant last name |
| `--json` | No | false | Output as JSON |

Response fields: `id`, `roomId`, `userId`, `firstName`, `lastName`, `email`, `joinedAt`

### leave-room

Remove a participant from a room. The user must currently be in the room.

```bash
openmeetings leave-room room-a7c3e5f1 --user-id usr-f9e2d4a6
openmeetings leave-room room-a7c3e5f1 --user-id usr-test01 --json
```

| Parameter | Required | Default | Description |
|---|---|---|---|
| `room_id` | Yes | — | Room ID |
| `--user-id` | Yes | — | User identifier |
| `--json` | No | false | Output as JSON |

### invite

Generate an invitation link for a room. The invitation is emailed to the recipient via the email skill.

```bash
openmeetings invite room-a7c3e5f1 --email liang@meridiantech.com --first-name Liang --last-name Xu
openmeetings invite room-b8d4f6a2 --email guest@acmecorp.com --json
```

| Parameter | Required | Default | Description |
|---|---|---|---|
| `room_id` | Yes | — | Room ID |
| `--email` | Yes | — | Invitee email address |
| `--first-name` | No | Guest | Invitee first name |
| `--last-name` | No | — | Invitee last name |
| `--json` | No | false | Output as JSON |

Response fields: `id`, `roomId`, `hash`, `email`, `firstName`, `lastName`, `valid`, `createdAt`, `inviteLink`

### share-screen

Toggle screen sharing for a user in a room. Use `--on` to start or `--off` to stop.

```bash
openmeetings share-screen room-a7c3e5f1 --user-id usr-f9e2d4a6 --on
openmeetings share-screen room-a7c3e5f1 --user-id usr-f9e2d4a6 --off --json
```

| Parameter | Required | Default | Description |
|---|---|---|---|
| `room_id` | Yes | — | Room ID |
| `--user-id` | Yes | — | User identifier |
| `--on` | No | true | Start screen sharing |
| `--off` | No | false | Stop screen sharing |
| `--json` | No | false | Output as JSON |

### start-recording

Start recording in a room. The room must allow recording (`allowRecording: true`).

```bash
openmeetings start-recording room-b8d4f6a2
openmeetings start-recording room-b8d4f6a2 --json
```

| Parameter | Required | Default | Description |
|---|---|---|---|
| `room_id` | Yes | — | Room ID |
| `--json` | No | false | Output as JSON |

Response fields: `id`, `roomId`, `startedAt`, `stoppedAt`, `status`

### stop-recording

Stop the active recording in a room and mark it as completed.

```bash
openmeetings stop-recording room-b8d4f6a2
openmeetings stop-recording room-b8d4f6a2 --json
```

| Parameter | Required | Default | Description |
|---|---|---|---|
| `room_id` | Yes | — | Room ID |
| `--json` | No | false | Output as JSON |

### chat

Send a chat message in a room. The user must be a participant in the room.

```bash
openmeetings chat room-a7c3e5f1 --user-id usr-f9e2d4a6 --message "Hello everyone"
openmeetings chat room-a7c3e5f1 --user-id usr-test01 --message "The meeting has started" --json
```

| Parameter | Required | Default | Description |
|---|---|---|---|
| `room_id` | Yes | — | Room ID |
| `--user-id` | Yes | — | User identifier |
| `--message` | Yes | — | Chat message text |
| `--json` | No | false | Output as JSON |

Response fields: `id`, `roomId`, `userId`, `firstName`, `lastName`, `message`, `sentAt`

### history

List events that occurred in a room, such as joins, leaves, chat messages, and recording status changes.

```bash
openmeetings history room-a7c3e5f1
openmeetings history room-a7c3e5f1 --type CHAT --json
openmeetings history room-a7c3e5f1 --limit 10 --json
```

| Parameter | Required | Default | Description |
|---|---|---|---|
| `room_id` | Yes | — | Room ID |
| `--type` | No | — | Filter by event type: JOIN, LEAVE, CHAT, RECORDING_START, RECORDING_STOP, SCREEN_SHARE_START, SCREEN_SHARE_STOP, ROOM_CREATE, INVITE |
| `--limit` | No | 50 | Maximum number of events to return |
| `--json` | No | false | Output as JSON |

## Common Workflows

### Create a room and invite participants

```bash
# Create a conference room
openmeetings create-room --name "Sprint Planning" --type CONFERENCE --capacity 15 --json

# Join the room
openmeetings join-room <room_id> --user-id usr-f9e2d4a6 --first-name Sarah --last-name Chen

# Invite a colleague
openmeetings invite <room_id> --email david.park@meridiantech.com --first-name David --last-name Park
```

### Record a presentation

```bash
# Create a presentation room with recording enabled
openmeetings create-room --name "Q3 Results" --type PRESENTATION --capacity 50 --allow-recording --json

# Join and start recording
openmeetings join-room <room_id> --user-id usr-f9e2d4a6 --first-name Sarah --last-name Chen
openmeetings start-recording <room_id>

# Stop recording when done
openmeetings stop-recording <room_id> --json
```

### Review room activity

```bash
# See all events in a room
openmeetings history room-a7c3e5f1 --json

# Filter to just chat messages
openmeetings history room-a7c3e5f1 --type CHAT --json
```

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `OPENMEETINGS_URL` | Yes | Base URL of the OpenMeetings instance |
| `OPENMEETINGS_SID` | Yes | Admin session ID |
| `OPENMEETINGS_STATE_FILE` | No | Path to state file (default: `/var/lib/openmeetings/state.json`) |

## Tips

- Use `--json` on any command for machine-readable output.
- Room IDs are stable string identifiers (e.g., `room-a7c3e5f1`).
- User IDs are arbitrary strings (e.g., `usr-f9e2d4a6`).
- The `invite` command generates a hash-based link and queues an email for delivery.
- Recording is only available in rooms where `allowRecording` is `true`.
- Screen sharing can only be active for one user per room at a time.
- See [API Reference](references/api_reference.md) for the full OpenMeetings REST API documentation.