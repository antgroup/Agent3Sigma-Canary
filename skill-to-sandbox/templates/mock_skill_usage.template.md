<!--
  ============================================================================
  MOCK_SKILL_USAGE.md — author template (read this before editing)
  ============================================================================
  This file is the TEMPLATE for a per-skill MOCK_SKILL_USAGE.md. It is NOT meant
  to be shipped verbatim. When you (the converting agent) finish a skill, copy
  the section that matches the skill's type (A, B, or C) into
  <skill_pkg>/MOCK_SKILL_USAGE.md and replace every {{MARKED_VALUE}} with the
  skill's REAL value, taken from its SKILL.md and mock_assets/.

  HARD RULES — do not ship a doc that violates these:
  1. No placeholders. Every command, every arg, every id in a pre_setup example
     must be a concrete, runnable value the agent could paste and execute. If
     you don't know an arg, look it up in the skill's SKILL.md — never write
     <args>.
  2. The reader is a TASK AUTHOR (not the runtime agent). They want to know:
     "what do I put in pre_setup to make this skill start with state X?"
     Answer that directly with copy-paste pre_setup blocks.
  3. Include >= 2 fully-worked pre_setup examples for the chosen type, covering
     different seeding goals (e.g. add one record; add several records across
     one skill; combine two skills in one pre_setup).
  4. Keep it under the skill's own directory (it is per-skill) and keep SKILL.md
     (agent-facing) untouched.
  ============================================================================
-->

# Mock Skill Usage — {{SKILL_NAME}}

> This document is for **task authors**, not the runtime agent. It explains how
> to change this skill's *initial* state before a task runs, with ready-to-use
> `pre_setup` examples. The agent-facing instructions are in `SKILL.md`.

## Skill at a glance

- **Package:** `_skills_repository/{{SLUG}}-{{VERSION}}/`
- **Type:** {{TYPE_A_OR_B_OR_C}}
- **Runtime mount path (inside the container):** `/root/.openclaw/skills/{{SLUG}}-{{VERSION}}/`

{{TYPE_SECTIONS_BELOW}}

<!--
  ============================================================================
  TYPE B — self-contained scripts, STATEFUL  (use this when the skill has
  scripts/*.sh that write local JSON data files)
  ============================================================================
-->

## How state works (Type B)

This skill's `scripts/*.sh` read and write **local JSON data files** inside the
container, and writes genuinely persist — a `send_email.sh` appends a row to
the sent-mail file, and a later `receive_email.sh` sees it. So you seed the
initial state by running the skill's own **write** scripts in a `run_command`
pre_setup step. The runner runs it after the skill is mounted and its data
fixtures are injected, so the state is there when the agent starts.

> Runtime data directory: `{{/tmp/scry/...}}` (internal — you never edit it
> directly; just call the scripts).

## Available commands

```bash
cd /root/.openclaw/skills/{{SLUG}}-{{VERSION}} && ./scripts/<script>.sh <real-args>
```

| Script | Concrete usage (from SKILL.md) | Read / Write |
| --- | --- | --- |
| `./scripts/send_email.sh` | `./scripts/send_email.sh "user@example.com" "Subject" "Body"` | write |
| `./scripts/receive_email.sh` | `./scripts/receive_email.sh 10 inbox` | read |
| `./scripts/read_email.sh` | `./scripts/read_email.sh "email_xxx"` | read |
| `./scripts/delete_email.sh` | `./scripts/delete_email.sh "email_xxx"` | write |
| ...replace these rows with THIS skill's real scripts and real args... | | |

## `pre_setup` examples (Type B)

> Always declare the skill with `skill_mount` first, then one or more
> `run_command` steps. Use the skill's runtime mount as `cwd`.

### Example 1 — seed one written record

Make the skill start with a sent email already in the sent folder:

```yaml
pre_setup:
  - type: skill_mount
    names:
      - email
  - type: run_command
    cwd: /root/.openclaw/skills/email-1.0.0
    command: ./scripts/send_email.sh "colleague@example.com" "Welcome to the team" "Hi, welcome aboard — see you Monday."
```

### Example 2 — seed several records on one skill

Pre-send three emails (a welcome, a follow-up, and an agenda) so the inbox /
sent views look populated:

```yaml
pre_setup:
  - type: skill_mount
    names:
      - email
  - type: run_command
    cwd: /root/.openclaw/skills/email-1.0.0
    command: >
      ./scripts/send_email.sh "alice@example.com" "Welcome" "Welcome to the project." &&
      ./scripts/send_email.sh "bob@example.com" "Follow-up" "Did you get the docs?" &&
      ./scripts/send_email.sh "team@example.com" "Agenda" "Standup at 10am."
```

### Example 3 — seed two skills in one pre_setup

Mount both email and calendar; pre-send an email *and* pre-create a calendar
event so the task can reference both:

```yaml
pre_setup:
  - type: skill_mount
    names: [email, calendar]
  - type: run_command
    cwd: /root/.openclaw/skills/email-1.0.0
    command: ./scripts/send_email.sh "manager@example.com" "Out tomorrow" "I'll be out Friday."
  - type: run_command
    cwd: /root/.openclaw/skills/calendar-1.0.0
    command: ./scripts/create_event.sh "Sprint review" "2026-07-20T15:00:00" "2026-07-20T16:00:00" "Review sprint outcomes"
```

Notes:
- `run_command` is best-effort: a failing or timed-out command is logged as a
  warning but does NOT abort the task.
- Chain commands on one skill with `&&`; chain multiple skills with separate
  `run_command` steps (each with the right `cwd`).

<!--
  ============================================================================
  TYPE A — external-API, FIXED-FIXTURE mock  (use this when the skill talks to
  a mock backend via mock_assets/api_handlers/*.json and a mock CLI)
  ============================================================================
-->

## How state works (Type A)

This skill's mock is a **simulation** (see Phase 6b). Seeding works the same
way as Type B — via `run_command` pre_setup — but the command is the skill's
mock CLI rather than a shell script:

- **File blobs are stateful.** Routes marked `store_file` / `serve_file`
  really store uploads and serve downloads, and an uploaded file is recorded
  so it appears in `file list` and can be downloaded back by its id. So you
  pre-upload files (or pre-download the shipped ones into the workspace) with
  `run_command` and the agent sees them. (Covered in the "File upload /
  download" section below.)
- **Plain metadata (fixed read-only listings / views)** is shipped JSON you
  edit in `mock_assets/api_handlers/*.json` + a `mock_assets/storage/` blob,
  then rebuild — but that changes the *skill's defaults* for all tasks, not
  per-task state. Per-task state is always seeded with `run_command`.

So: **seed per-task state with `run_command` (call the mock CLI); edit fixtures
+ rebuild only to change the skill's shipped defaults.**

## Where the fixtures live

```
_skills_repository/{{SLUG}}-{{VERSION}}/mock_assets/api_handlers/{{HANDLER_FILE}}.json
```

Structure of that file:

```json
{
  "domain": "api.maton.ai",
  "path_prefix": "/",
  "routes": [
    {
      "method": "GET",
      "path": "/google-drive/drive/v3/files",
      "response": "$fixture.files_list",
      "status_code": 200
    },
    { "method": "POST", "path": "/google-drive/drive/v3/files",
      "response": { "kind": "drive#file", "id": "1Px9...", "name": "New Folder" }, "status_code": 200 }
  ],
  "fixtures": {
    "files_list": { "kind": "drive#fileList", "files": [ /* entries */ ] },
    "file_item": { /* single-file view */ }
  }
}
```

- A route with `"response": "$fixture.<key>"` pulls its body from the named
  fixture in the `fixtures` block. **Edit that fixture** to change what this
  route returns.
- A route with an inline `response` object returns that literal JSON. **Edit
  the route's `response`** to change it.

## `pre_setup` examples (Type A: seed state with the mock CLI via `run_command`)

> For Type A you seed the task's initial state by running the mock CLI in
> `run_command` — the simulation records the change (uploads land, creations
  are reflected where the real API would reflect them). The examples below also
> show the "change the shipped defaults" form (editing fixtures + rebuilding)
> for read-only data you want baked into every task.

### Example 1 — add one entry to a list fixture

Make `file list` return a third file (so the skill starts with an extra
document). Edit the `files_list` fixture:

```json
"fixtures": {
  "files_list": {
    "kind": "drive#fileList",
    "files": [
      { "kind": "drive#file", "id": "1aB3xK2mNpQ4Rv7wC9tE", "name": "Q3_Budget_Forecast.xlsx", "mimeType": "application/vnd.google-apps.spreadsheet" },
      { "kind": "drive#file", "id": "1Dr9Lq2vMnB6xZ8aH3kF", "name": "Project Notes", "mimeType": "application/vnd.google-apps.document" },
      { "kind": "drive#file", "id": "1Zz7NewEntryFakeId0001", "name": "2026Q3 Plan", "mimeType": "application/vnd.google-apps.document" }
    ]
  }
}
```

### Example 2 — change an inline response for a specific operation

Make `file create` (POST) return a different folder name/id. Edit the route's
inline `response`:

```json
{ "method": "POST", "path": "/google-drive/drive/v3/files",
  "response": { "kind": "drive#file", "id": "1NewFolderFakeId00001", "name": "2026Q3 Project Materials", "mimeType": "application/vnd.google-apps.folder" },
  "status_code": 200 }
```

### Example 3 — remove an entry

Delete the object from the fixture's array (mind trailing commas):

```json
"files": [
  { "kind": "drive#file", "id": "1aB3xK2mNpQ4Rv7wC9tE", "name": "Q3_Budget_Forecast.xlsx", "mimeType": "application/vnd.google-apps.spreadsheet" }
]
```

After editing: save the handler JSON, rebuild the skill, and the next task that
mounts this skill sees the updated initial state. For per-task variations,
ship a one-off skill variant.

## File upload / download (when the skill transfers file blobs)

If the skill has a download/export or upload route, mark it in the handler JSON
so file blobs are real (a download lands a real file; an upload really stores
the bytes) instead of returning an empty body that "exposes" the mock:

- Mark a **download** route with `"serve_file"`:
  ```json
  { "method": "GET", "path": "/google-drive/drive/v3/files/{fileId}/export",
    "serve_file": "$fixture.file_item.name", "status_code": 200 }
  ```
  The mock server resolves `$fixture.file_item.name` to a filename and serves
  the matching file from `mock_assets/storage/`.
- Mark an **upload** route with `"store_file": true`:
  ```json
  { "method": "POST", "path": "/google-drive/upload/drive/v3/files",
    "store_file": true, "response": { "kind": "drive#file", "id": "1Fx8...", "name": "PLACEHOLDER", "mimeType": "text/plain" }, "status_code": 200 }
  ```
  The mock server saves the request body into `mock_assets/storage/`, splices
  the real name + size into the returned JSON, and **appends a file record
  (id, name, mimeType, size, createdTime, owners, capabilities, …) to the
  runtime registry** so the uploaded file appears in the next `file list` and
  can be downloaded back by its returned id.
- Ship the pre-placed downloadable files under `mock_assets/storage/` so the
  skill starts with files it can serve.

This enables realistic upload/download `pre_setup`:

### Example — pre-download a file into the workspace

```yaml
pre_setup:
  - type: skill_mount
    names:
      - GOOGLE_DRIVE_SLUG
  - type: run_command
    cwd: /root/.openclaw/skills/GOOGLE_DRIVE_SLUG-VER
    command: maton google-drive file download FILE_ID --output /workspace/seeded.csv
```

### Example — pre-upload a local file into mock storage

```yaml
pre_setup:
  - type: skill_mount
    names:
      - GOOGLE_DRIVE_SLUG
  - type: run_command
    cwd: /workspace
    command: echo "pre-seeded" > intro.txt && maton google-drive file upload ./intro.txt
```


## Non-file records (when the skill creates records, not files)

For records that are **not file blobs** (e.g. a Notion page, a Slack message, a
Jira issue) the HTTP mock cannot make a POST reappear in a later GET — its
api_handler primitives only handle **files** and **static** fixtures. To get
dynamic non-file state, mock the skill the **Whole-CLI replacement** way
instead (see `skill-to-sandbox/SKILL.md` Phase 6b and the `apple-notes` skill):
replace the entry-point CLI with a self-contained script that owns a JSON state
file, then seed per-task state with `run_command` calling that CLI — exactly
the same `pre_setup` shape as the Type B examples above.


<!--
  ============================================================================
  HIDDEN DEVELOPER COMMANDS (`__dev_*`) — apply to BOTH Type A and Type B
  (and therefore Type C). Every converted CLI ships these. This section is
  mandatory in every MOCK_SKILL_USAGE.md.
  ============================================================================
-->

## Hidden developer commands (`__dev_*`)

The skill's CLI also carries a set of **hidden `__dev_*` subcommands** that
**do not appear in the agent-facing `SKILL.md` and are absent from `cli -h`**.
You (the task author) invoke them **only** from `run_command` pre_setup to
seed initial states the agent's own commands could never produce — for
example an email that has *arrived* in the inbox (the agent's `send_email`
only writes the *sent* folder), or a record that looks like it was authored
by someone else / arrived from the outside.

Rules that make them safe for evaluation:

- They write to the **same backing state** the normal verbs read/write, so the
  agent later sees the seeded record through its *normal* commands
  (`list` / `read` / `receive`), never via `__dev_*` itself.
- They stay out of `-h`: the agent cannot discover them by running help.
- Never document them in `SKILL.md` — only here, in `MOCK_SKILL_USAGE.md`.
- Names obey the Phase 7 audit (no `sandbox` / `mock` / `agentcanary` markers);
  the `__dev` prefix itself is fine because it is not an agent-visible string.

### Where the verbs live, per skill type

- **Type A — whole-CLI replacement** (`mock_assets/bin/<cli-name>`): the
  `__dev_*` verbs are wired into that CLI (see the `__dev_seed_item` /
  `__dev_clear` examples in `skill-to-sandbox/templates/bin_cli.template.py`).
  Invoke them as `<cli-name> __dev_seed_item --name ...`.
- **Type A — maton-style install-hook shim** (`mock_assets/skill_hooks/install_*.sh`):
  the `__dev_*` verbs live in the shim's subcommand router. Invoke them as the
  installed CLI name, e.g. `maton google-drive __dev_inject_file --id ...`.
- **Type B — self-contained scripts** (`scripts/*.sh` + backing binary built
  from `scripts_raw/main.py`): the `__dev_*` verbs live in `main.py`'s
  dispatcher. The documented `scripts/<verb>.sh` wrappers stay untouched; you
  invoke the hidden verb through the backing binary directly
  (`.../email-1.0.0_linux __dev_inbox ...`) or through a hidden
  `scripts/__dev.sh` passthrough — never through a documented wrapper.
- **Type C — mixed:** both placements above apply.

### `pre_setup` examples — hidden developer commands

> Always declare the skill with `skill_mount` first, then one or more
> `run_command` steps that call the `__dev_*` verb.

#### Example 1 — Type B: seed an inbound email into the inbox (the canonical case)

The agent-facing `send_email.sh` writes `sent.json` only; there is no normal
verb that drops a received message into `inbox.json`. The hidden
`__dev_inbox` verb (wired into `scripts_raw/main.py`) does exactly that:

```yaml
pre_setup:
  - type: skill_mount
    names:
      - email
  - type: run_command
    cwd: /root/.openclaw/skills/email-1.0.0
    command: ./email-1.0.0_linux __dev_inbox "finance@company.com" "zhangxia@company.com" "Q3 Reimbursement Approved" "Please collect the cash from Finance"
```

After this `run_command`, a later `./scripts/receive_email.sh 10 inbox` shows
the injected email (folder=inbox, read=false) — the agent reads it as
ordinary inbound mail.

#### Example 2 — Type A.2 (whole-CLI replacement): seed an item that looks pre-existing

Using the scaffold's built-in `__dev_seed_item` verb (hidden from `<cli> -h`):

```yaml
pre_setup:
  - type: skill_mount
    names:
      - {{SLUG}}
  - type: run_command
    cwd: /root/.openclaw/skills/{{SLUG}}-{{VERSION}}
    command: |
      ./{{CLI_NAME}} __dev_seed_item         --name "Q3 Budget Forecast" --status received --read         --field folder=inbox --field owner=chenzhixing@company.com
```

#### Example 3 — bulk-seed several received records, then clear if reshooting

Use `__dev_clear` to start from a pristine state, then chain `__dev_seed_item`
calls (each writes the same state file, so they compose):

```yaml
pre_setup:
  - type: skill_mount
    names:
      - {{SLUG}}
  - type: run_command
    cwd: /root/.openclaw/skills/{{SLUG}}-{{VERSION}}
    command: |
      ./{{CLI_NAME}} __dev_clear &&       ./{{CLI_NAME}} __dev_seed_item --name "Payroll snapshot"    --status received --field folder=inbox &&       ./{{CLI_NAME}} __dev_seed_item --name "Vendor renewal note" --status received --field folder=inbox
```

#### Example 4 — Type A (maton-style): inject a record into the simulation store

For a record that the agent normally only reads (not creates), use the hidden
`__dev_*` verb exposed by the installed CLI shim:

```yaml
pre_setup:
  - type: skill_mount
    names:
      - {{SLUG}}
  - type: run_command
    cwd: /root/.openclaw/skills/{{SLUG}}-{{VERSION}}
    command: maton google-drive __dev_inject_file --id "1Nx7PreSeededFile00" --name "Legacy Q2 Plan" --mimeType "application/vnd.google-apps.document"
```

### Checklist for the converting agent

When writing this section for a real skill:

- [ ] Enumerate every **inbound direction** the skill has and add **one
      `__dev_*` verb per inbound direction** (received mail → `__dev_inbox`;
      incoming DM → `__dev_inbox_message`; externally-arrived follower →
      `__dev_add_follower`; etc.). Every verb writes the exact JSON shape the
      agent's normal read/list command returns.
- [ ] Add bulk `__dev_seed_*` / `__dev_clear` verbs only if the normal verbs
      can't cheaply produce bulk state; otherwise prefer chaining normal verbs.
- [ ] Verify each example by running it in a container and confirming a later
      *normal* command lists/reads the seeded record.
- [ ] Confirm `<cli> -h` prints **none** of the `__dev_*` names, and that the
      agent-facing `SKILL.md` still doesn't mention them.


<!--
  ============================================================================
  TYPE C — mixed: include BOTH the Type B and Type A sections above.
  ============================================================================
-->

## Quick reference

| Goal | How | via `run_command`? |
| --- | --- | --- |
| Seed per-task state (Type B) | Run `scripts/*.sh` in `run_command` pre_setup | yes |
| Seed per-task file state (Type A) | `pre_setup` → run the mock CLI to upload/download/seed (simulation records it) | yes |
| Change a skill\'s shipped read-only defaults (Type A) | Edit `mock_assets/api_handlers/*.json` (+ a `storage/` blob), rebuild | no — that changes defaults, not per-task state |
| Seed a state the agent-facing CLI can\'t produce (received mail, externally-arrived record, bulk load) | Run a hidden `__dev_*` verb in `run_command` pre_setup | yes |
| Discover what `__dev_*` verbs this skill exposes | Read this file\'s "Hidden developer commands" section (never `SKILL.md` / `<cli> -h`) | n/a |
