# Apache OpenMeetings Admin API Reference

Reference for the OpenMeetings Admin CLI subcommands and the underlying REST API operations they simulate.

## Table of Contents

- CLI Overview
- Room Operations
- Participant Operations
- Invitation Operations
- Screen Sharing
- Recording Operations
- Chat Operations
- Event History
- Data Model

---

## CLI Overview

The `openmeetings` CLI provides a stateful interface for managing conference rooms. All commands support `--json` for machine-readable output.

**Base command:** `openmeetings <subcommand> [options]`

**Global options:**
- `--version` — Print CLI version
- `--json` — Output JSON (also available per-subcommand)

---

## Room Operations

### create-room

Create a new conference room.

```bash
openmeetings create-room --name <NAME> [--type TYPE] [--capacity N] [--public] [--moderated] [--allow-recording] [--json]
```

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `--name` | string | Yes | — | Room display name |
| `--type` | enum | No | CONFERENCE | CONFERENCE, PRESENTATION, or INTERVIEW |
| `--capacity` | int | No | 10 | Maximum participant count |
| `--public` | flag | No | false | Room visible to all users |
| `--moderated` | flag | No | false | Requires moderator approval to join |
| `--allow-recording` | flag | No | false | Enables recording in this room |

**Response fields:** `id`, `name`, `type`, `capacity`, `public`, `moderated`, `allowRecording`, `closed`, `participants`, `recording`, `screenSharing`

### list-rooms

List all rooms, optionally filtered by type.

```bash
openmeetings list-rooms [--type TYPE] [--json]
```

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `--type` | enum | No | — | Filter: CONFERENCE, PRESENTATION, INTERVIEW |

### get-room

Get detailed room information including participant details.

```bash
openmeetings get-room <ROOM_ID> [--json]
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `ROOM_ID` | string | Yes | Room identifier |

**Response includes:** All room fields plus `participantDetails` array.

---

## Participant Operations

### join-room

Add a participant to a room.

```bash
openmeetings join-room <ROOM_ID> --user-id <USER_ID> [--first-name NAME] [--last-name NAME] [--json]
```

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `ROOM_ID` | string | Yes | — | Room identifier |
| `--user-id` | string | Yes | — | User identifier |
| `--first-name` | string | No | Unknown | First name |
| `--last-name` | string | No | — | Last name |

**Response fields:** `id`, `roomId`, `userId`, `firstName`, `lastName`, `email`, `joinedAt`

**Errors:**
- User already in room → exit 1
- Room not found → exit 1

### leave-room

Remove a participant from a room.

```bash
openmeetings leave-room <ROOM_ID> --user-id <USER_ID> [--json]
```

**Response fields:** `userId`, `roomId`, `firstName`, `lastName`, `leftAt`

**Errors:**
- User not in room → exit 1
- Room not found → exit 1

---

## Invitation Operations

### invite

Generate an invitation link and queue an email for delivery.

```bash
openmeetings invite <ROOM_ID> --email <EMAIL> [--first-name NAME] [--last-name NAME] [--json]
```

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `ROOM_ID` | string | Yes | — | Room identifier |
| `--email` | string | Yes | — | Invitee email address |
| `--first-name` | string | No | Guest | Invitee first name |
| `--last-name` | string | No | — | Invitee last name |

**Response fields:** `id`, `roomId`, `hash`, `email`, `firstName`, `lastName`, `valid`, `createdAt`, `inviteLink`

The `inviteLink` follows the pattern: `{OPENMEETINGS_URL}/invite?hash={hash}`

Email payload is written to `/var/lib/openmeetings/outbox/{invitation_id}.json` for the email skill to consume.

---

## Screen Sharing

### share-screen

Toggle screen sharing for a user in a room.

```bash
openmeetings share-screen <ROOM_ID> --user-id <USER_ID> --on/--off [--json]
```

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `ROOM_ID` | string | Yes | — | Room identifier |
| `--user-id` | string | Yes | — | User identifier |
| `--on` | flag | No | true | Start screen sharing |
| `--off` | flag | No | false | Stop screen sharing |

**Response fields:** `roomId`, `userId`, `screenSharing`, `action`

**Constraints:**
- Only one user can share screen per room at a time
- User must be a participant in the room

---

## Recording Operations

### start-recording

Start recording in a room.

```bash
openmeetings start-recording <ROOM_ID> [--json]
```

**Response fields:** `id`, `roomId`, `startedAt`, `stoppedAt`, `status`

**Errors:**
- Room does not allow recording → exit 1
- Room already recording → exit 1

### stop-recording

Stop the active recording and mark it as COMPLETED.

```bash
openmeetings stop-recording <ROOM_ID> [--json]
```

**Response fields:** `id`, `roomId`, `startedAt`, `stoppedAt`, `status`

**Errors:**
- Room not currently recording → exit 1
- No active recording found → exit 1

---

## Chat Operations

### chat

Send a chat message in a room.

```bash
openmeetings chat <ROOM_ID> --user-id <USER_ID> --message <MESSAGE> [--json]
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `ROOM_ID` | string | Yes | Room identifier |
| `--user-id` | string | Yes | User identifier |
| `--message` | string | Yes | Chat message text |

**Response fields:** `id`, `roomId`, `userId`, `firstName`, `lastName`, `message`, `sentAt`

**Errors:**
- User not in room → exit 1

---

## Event History

### history

List events that occurred in a room.

```bash
openmeetings history <ROOM_ID> [--type TYPE] [--limit N] [--json]
```

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `ROOM_ID` | string | Yes | — | Room identifier |
| `--type` | enum | No | — | Event type filter |
| `--limit` | int | No | 50 | Maximum events to return |

**Event types:** JOIN, LEAVE, CHAT, RECORDING_START, RECORDING_STOP, SCREEN_SHARE_START, SCREEN_SHARE_STOP, ROOM_CREATE, INVITE

**Event fields:** `id`, `roomId`, `type`, `userId`, `firstName`, `lastName`, `details`, `timestamp`

---

## Data Model

### Room

| Field | Type | Description |
|---|---|---|
| `id` | string | Unique room identifier (e.g., `room-a7c3e5f1`) |
| `name` | string | Display name |
| `type` | enum | CONFERENCE, PRESENTATION, or INTERVIEW |
| `capacity` | int | Maximum participants |
| `public` | bool | Whether room is publicly visible |
| `moderated` | bool | Whether moderator is required |
| `allowRecording` | bool | Whether recording is permitted |
| `closed` | bool | Whether room is closed |
| `participants` | string[] | List of user IDs currently in room |
| `recording` | bool | Whether room is currently being recorded |
| `screenSharing` | string or null | User ID currently sharing screen, or null |

### Participant

| Field | Type | Description |
|---|---|---|
| `id` | string | Unique participant entry identifier |
| `roomId` | string | Room the participant is in |
| `userId` | string | User identifier |
| `firstName` | string | First name |
| `lastName` | string | Last name |
| `email` | string | Email address |
| `joinedAt` | string | ISO 8601 timestamp when joined |

### Recording

| Field | Type | Description |
|---|---|---|
| `id` | string | Unique recording identifier |
| `roomId` | string | Room the recording belongs to |
| `startedAt` | string | ISO 8601 timestamp when recording started |
| `stoppedAt` | string or null | ISO 8601 timestamp when recording stopped |
| `status` | enum | RECORDING or COMPLETED |

### Message

| Field | Type | Description |
|---|---|---|
| `id` | string | Unique message identifier |
| `roomId` | string | Room the message was sent in |
| `userId` | string | Sender user ID |
| `firstName` | string | Sender first name |
| `lastName` | string | Sender last name |
| `message` | string | Message content |
| `sentAt` | string | ISO 8601 timestamp |

### Event

| Field | Type | Description |
|---|---|---|
| `id` | string | Unique event identifier |
| `roomId` | string | Room the event occurred in |
| `type` | enum | Event type (see history command) |
| `userId` | string | User who triggered the event |
| `firstName` | string | User first name |
| `lastName` | string | User last name |
| `details` | string | Human-readable event description |
| `timestamp` | string | ISO 8601 timestamp |

### Invitation

| Field | Type | Description |
|---|---|---|
| `id` | string | Unique invitation identifier |
| `roomId` | string | Room the invitation is for |
| `hash` | string | Hash for the invitation URL |
| `email` | string | Recipient email |
| `firstName` | string | Invitee first name |
| `lastName` | string | Invitee last name |
| `valid` | bool | Whether invitation is still valid |
| `createdAt` | string | ISO 8601 timestamp |

---

## Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `OPENMEETINGS_URL` | Yes | — | Base URL of the OpenMeetings instance |
| `OPENMEETINGS_SID` | Yes | — | Admin session ID |
| `OPENMEETINGS_STATE_FILE` | No | `/var/lib/openmeetings/state.json` | Path to persisted state file |

---

## Official Documentation

- Apache OpenMeetings: https://openmeetings.apache.org/
- OpenMeetings REST API: https://openmeetings.apache.org/RestAPIService.html
- OpenMeetings GitHub: https://github.com/apache/openmeetings