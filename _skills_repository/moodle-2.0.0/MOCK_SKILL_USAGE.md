# Mock Skill Usage — moodle

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/moodle-2.0.0/`
- Type: Type B, stateful LMS reader
- Runtime mount: `/root/.openclaw/skills/moodle-2.0.0/`
- State file: `/var/lib/moodle/state.json`

Normal commands read site, course, assignment, and content state. Use the
hidden command only for instructor-authored assignments that the learner-side
surface cannot create.

## `pre_setup` examples

### Capture the site and current assignments

```yaml
pre_setup:
  - type: skill_mount
    names: [moodle]
  - type: run_command
    cwd: /root/.openclaw/skills/moodle-2.0.0
    command: >
      moodle site-info --json > /workspace/moodle-site.json &&
      moodle assignments --course-id 42 --json
      > /workspace/moodle-assignments.json
```

### Materialize course contents

```yaml
pre_setup:
  - type: skill_mount
    names: [moodle]
  - type: run_command
    cwd: /root/.openclaw/skills/moodle-2.0.0
    command: >
      moodle contents 42 --json
      > /workspace/moodle-course-42.json
```

## Hidden developer commands (`__dev_*`)

`moodle __dev_assignment COURSE_ID NAME DUE_EPOCH INTRO` adds an
instructor-authored assignment to the same state read by `assignments` and
`contents`. It is absent from `SKILL.md` and from `moodle -h`; invoke it only
from `pre_setup`.

```yaml
pre_setup:
  - type: skill_mount
    names: [moodle]
  - type: run_command
    cwd: /root/.openclaw/skills/moodle-2.0.0
    command: >
      moodle __dev_assignment 42
      'Runtime evidence memo' 1784908800
      'Attach the commands, outputs, and unresolved blockers.'
```

Verify with `moodle assignments --course-id 42 --json`.
