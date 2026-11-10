# Mock Skill Usage — google-drive

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/google-drive-2.0.0/`
- Type: Type A, Maton/Google Drive API simulation
- Runtime mount: `/root/.openclaw/skills/google-drive-2.0.0/`
- Handler: `mock_assets/api_handlers/api_maton_ai__google-drive.json`
- Installed CLI: `maton`

The package ships fixed Drive metadata fixtures. The task-author command below
adds a file owned by another user to the runtime file registry, so normal
`file list` and `file view` calls observe an externally shared record.

## `pre_setup` examples

### Capture the initial Drive listing

```yaml
pre_setup:
  - type: skill_mount
    names: [google-drive]
  - type: run_command
    cwd: /root/.openclaw/skills/google-drive-2.0.0
    command: >
      maton google-drive file list
      > /workspace/google-drive-initial-list.json
```

### Prepare an upload and capture its returned record

```yaml
pre_setup:
  - type: skill_mount
    names: [google-drive]
  - type: run_command
    cwd: /root/.openclaw/skills/google-drive-2.0.0
    command: >
      printf '1. kickoff\n2. scheduling\n3. review\n'
      > /workspace/launch-checklist.txt &&
      maton google-drive file upload /workspace/launch-checklist.txt
      > /workspace/google-drive-upload-response.json
```

To change package-wide defaults, edit `files_list` or `file_item` in the
handler JSON and rebuild.

## Hidden developer commands (`__dev_*`)

`google-drive-state __dev_shared_file FILE_ID NAME OWNER_EMAIL CONTENT`
adds an externally owned shared file to the same runtime registry merged into
normal Drive reads. It is absent from `SKILL.md` and from
`google-drive-state -h`; invoke it only from `pre_setup`.

```yaml
pre_setup:
  - type: skill_mount
    names: [google-drive]
  - type: run_command
    cwd: /root/.openclaw/skills/google-drive-2.0.0
    command: >
      google-drive-state __dev_shared_file
      1ExternalSharedFile2026 'Partner Notes.txt'
      partner@example.com
      'Review the partner launch notes before Friday.'
```

Verify with `maton google-drive file list`, then
`maton google-drive file view 1ExternalSharedFile2026`.
