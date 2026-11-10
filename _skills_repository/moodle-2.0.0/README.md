# openclaw-moodle

OpenClaw skill for accessing your Moodle LMS via the REST API. Teach your AI agent to check assignments, browse course content, and more.

## Features

- List all courses and their assignments
- View upcoming and overdue assignments with due dates
- Browse course content (sections, modules, files)
- Check activity and course completion status

## Requirements

- [OpenClaw](https://docs.openclaw.ai) installed
- A Moodle web service token (generate in Moodle under Preferences → Security keys)
- `curl` on PATH

## Install

### Option A: OpenClaw workspace install

```bash
mkdir -p ~/.openclaw/skills/moodle
cp SKILL.md ~/.openclaw/skills/moodle/SKILL.md
```

### Option B: ClawHub (if published)

```bash
openclaw skills install moodle
```

### Option C: Git clone

```bash
git clone https://github.com/AltusRossouw/openclaw-moodle.git ~/.openclaw/skills/moodle
```

## Configure

Add to `~/.openclaw/openclaw.json`:

```json5
{
  skills: {
    entries: {
      moodle: {
        env: {
          MOODLE_TOKEN: "your_api_token_here",
          MOODLE_URL: "https://your-moodle.example.com",
        },
      },
    },
  },
}
```

Or export in your shell:

```bash
export MOODLE_TOKEN="your_api_token_here"
export MOODLE_URL="https://your-moodle.example.com"
```

## Usage

Start a new agent session and ask:

- *"Show me my upcoming assignments"*
- *"What's the course content for Programming 101?"*
- *"List all my courses"*
- *"Which assignments are overdue?"*

## Supported Moodle API Functions

The skill uses these Moodle web service functions (availability depends on your instance):

| Function | Purpose |
|---|---|
| `mod_assign_get_assignments` | List courses and assignments |
| `core_course_get_contents` | Browse course sections, modules, files |
| `core_completion_get_activities_completion_status` | Check activity completion |
| `core_webservice_get_site_info` | Verify available functions |

## License

MIT
