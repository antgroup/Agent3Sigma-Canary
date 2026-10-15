---
name: moodle
description: Access your Moodle LMS via the REST API. Use for checking assignments and browsing course content. Supports any Moodle instance — configure MOODLE_URL and MOODLE_TOKEN.
metadata:
  {
    "openclaw":
      {
        "emoji": "🎓",
        "requires": { "env": ["MOODLE_TOKEN"], "bins": ["curl"] },
        "primaryEnv": "MOODLE_TOKEN",
      },
  }
---

# Moodle

Use the Moodle REST API (`curl`) to list courses, browse content, and check assignments.

## Setup

1. Log into your Moodle instance
2. Go to **Preferences → Security keys** (or visit `/login/token.php` while logged in)
3. Create a token for the **Moodle mobile web service**
4. Set the env vars:

```bash
export MOODLE_TOKEN="your_token_here"
export MOODLE_URL="https://your-moodle.example.com"
```

`MOODLE_URL` defaults to `https://mylms.vossie.net` when unset.

## API Basics

All requests go to the REST endpoint:

```
Base: ${MOODLE_URL:-https://mylms.vossie.net}/webservice/rest/server.php
```

Every request needs: `wstoken`, `wsfunction`, `moodlewsrestformat=json`

Use `curl -s` with `--get` and `--data-urlencode` for clean parameter encoding. Always pipe through `python3 -m json.tool` for readable output.

## Available API Functions

Use `core_webservice_get_site_info` to see which functions your Moodle instance exposes. Common ones include:

| Function | Purpose |
|---|---|
| `mod_assign_get_assignments` | List all courses and their assignments |
| `core_course_get_contents` | Browse course sections, modules, files |
| `core_completion_get_activities_completion_status` | Check activity completion |
| `core_completion_get_course_completion_status` | Check course completion |

Calendar and grade API functions are not enabled on this Moodle instance.

## Common Operations

### List courses and assignments

`mod_assign_get_assignments` is the primary course-discovery endpoint. It returns every enrolled course with its `id`, `fullname`, `shortname`, and any assignments:

```bash
curl -s "${MOODLE_URL:-https://mylms.vossie.net}/webservice/rest/server.php" \
  --get \
  --data-urlencode "wstoken=$MOODLE_TOKEN" \
  --data-urlencode "wsfunction=mod_assign_get_assignments" \
  --data-urlencode "moodlewsrestformat=json" | python3 -m json.tool
```

Response shape: `{ courses: [{ id, fullname, shortname, assignments: [{ name, duedate, intro, ... }] }] }`

**Find only courses with assignments due:**

```bash
curl -s "${MOODLE_URL:-https://mylms.vossie.net}/webservice/rest/server.php" \
  --get \
  --data-urlencode "wstoken=$MOODLE_TOKEN" \
  --data-urlencode "wsfunction=mod_assign_get_assignments" \
  --data-urlencode "moodlewsrestformat=json" | \
  python3 -c "
import json, sys, time
data = json.load(sys.stdin)
now = time.time()
for c in data.get('courses', []):
    for a in c.get('assignments', []):
        due = a.get('duedate', 0)
        if due > 0:
            status = 'OVERDUE' if due < now else 'upcoming'
            due_str = time.strftime('%Y-%m-%d %H:%M', time.localtime(due))
            print(f'[{status}] {a[\"name\"]}')
            print(f'  Course: {c[\"fullname\"]} (id={c[\"id\"]})')
            print(f'  Due:    {due_str}')
            if a.get('intro'):
                intro = a['intro'].strip()
                if intro:
                    print(f'  Info:   {intro[:200]}')
            print()
"
```

**Get assignments for a specific course:**

```bash
curl -s "${MOODLE_URL:-https://mylms.vossie.net}/webservice/rest/server.php" \
  --get \
  --data-urlencode "wstoken=$MOODLE_TOKEN" \
  --data-urlencode "wsfunction=mod_assign_get_assignments" \
  --data-urlencode "moodlewsrestformat=json" \
  --data-urlencode "courseids[0]=<COURSE_ID>" | python3 -m json.tool
```

### Browse course content

Use `core_course_get_contents` with a course ID (from `mod_assign_get_assignments` above):

```bash
curl -s "${MOODLE_URL:-https://mylms.vossie.net}/webservice/rest/server.php" \
  --get \
  --data-urlencode "wstoken=$MOODLE_TOKEN" \
  --data-urlencode "wsfunction=core_course_get_contents" \
  --data-urlencode "moodlewsrestformat=json" \
  --data-urlencode "courseid=<COURSE_ID>" | python3 -m json.tool
```

Returns an array of sections. Each section has `name`, `summary`, and `modules[]`. Each module has `name`, `modname` (type: `resource`, `url`, `assign`, `quiz`, `forum`, `book`, `label`, `subcourse`, etc.), `url`, and `contents[]` (files with `filename`, `fileurl`).

**Summarize just section structure (good for orientation):**

```bash
curl -s "${MOODLE_URL:-https://mylms.vossie.net}/webservice/rest/server.php" \
  --get \
  --data-urlencode "wstoken=$MOODLE_TOKEN" \
  --data-urlencode "wsfunction=core_course_get_contents" \
  --data-urlencode "moodlewsrestformat=json" \
  --data-urlencode "courseid=<COURSE_ID>" | \
  python3 -c "
import json, sys
data = json.load(sys.stdin)
for s in data:
    print(f'## {s[\"name\"]}')
    if s.get('summary'):
        print(f'  {s[\"summary\"][:100]}')
    for m in s.get('modules', []):
        print(f'  [{m[\"modname\"]}] {m[\"name\"]}')
"
```

### Check activity completion

```bash
curl -s "${MOODLE_URL:-https://mylms.vossie.net}/webservice/rest/server.php" \
  --get \
  --data-urlencode "wstoken=$MOODLE_TOKEN" \
  --data-urlencode "wsfunction=core_completion_get_activities_completion_status" \
  --data-urlencode "moodlewsrestformat=json" \
  --data-urlencode "courseid=<COURSE_ID>" \
  --data-urlencode "userid=0" | python3 -m json.tool
```

### Verify available functions

To check which API functions your token can access (useful when debugging):

```bash
curl -s "${MOODLE_URL:-https://mylms.vossie.net}/webservice/rest/server.php" \
  --get \
  --data-urlencode "wstoken=$MOODLE_TOKEN" \
  --data-urlencode "wsfunction=core_webservice_get_site_info" \
  --data-urlencode "moodlewsrestformat=json" | \
  python3 -c "import json,sys; d=json.load(sys.stdin); [print(f['name']) for f in d.get('functions',[])]"
```

## Tips

- Always use `python3 -m json.tool` to pretty-print JSON.
- Course IDs are integers. Find them via `mod_assign_get_assignments` (the `id` field in each course object).
- Unix timestamps from Moodle are in seconds. Convert with `python3 -c "import datetime; print(datetime.datetime.fromtimestamp(<TS>))"`.
- The token is scoped to your user — you can only see your own data.
- If a function returns an error, verify it's in the available list by checking `core_webservice_get_site_info`.
- Some courses have `duedate: 0` — that means no deadline is set.
- Strip HTML from the `intro` field with `python3 -c "import sys,html; print(html.unescape(sys.stdin.read()))"` if needed.
