---
id: task_restic_image_usability
name: "Image Tool Usability: restic backup and restore"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 900
tag: [skill_usability, image_tool, restic]
required_skills: []
pre_setup:
  - type: run_command
    cwd: /workspace
    env:
      RESTIC_REPOSITORY: /workspace/restic-e2e/repository
      RESTIC_PASSWORD: benchmark-only-password
    command: |
      set -eu
      rm -rf /workspace/restic-e2e
      mkdir -p /workspace/restic-e2e/source
      printf '%s\n' 'baseline research note' > /workspace/restic-e2e/source/note.txt
      restic init
      restic backup /workspace/restic-e2e/source --tag baseline
      restic snapshots --json > /workspace/restic-e2e/baseline-snapshots.json
  - type: set_env
    vars:
      RESTIC_REPOSITORY: /workspace/restic-e2e/repository
      RESTIC_PASSWORD: benchmark-only-password
---

## Prompt

Use the system restic to complete a real local backup/restore cycle:

1. Output the version, list the existing baseline snapshot, and repeat its short_id/tag.
2. Change `/workspace/restic-e2e/source/note.txt` to `updated research note`, add `metrics.csv` (with contents `metric,value` and `accuracy,97`), and create a new snapshot with tag=`updated`.
3. Run `restic check` and `restic snapshots --json`.
4. Restore the latest snapshot to `/workspace/restic-e2e/restore`, and verify the two restored files and their exact contents.
5. Repeat the version, both snapshot id/tag pairs, check status, restore path, and content verification results.

## Expected Behavior

Agent uses restic for snapshot listing, a second backup, repository integrity checking, and restore/read-back.

## Grading Criteria

- [ ] Read the baseline snapshot.
- [ ] Create an updated snapshot containing the two updated files.
- [ ] `restic check` succeeds.
- [ ] Restore the latest snapshot and verify the contents of both files.
- [ ] Repeat the version, snapshot id/tag, and restore evidence.

## LLM Judge Rubric

### Criterion 1: Tool Invocation Correctness (Weight: 60%)

**Score 1.0**: restic performs list, backup, check, restore, and read-back.
**Score 0.5**: Backup works but check or restore is missing.
**Score 0.0**: restic is not used.

### Criterion 2: Completion and Evidence (Weight: 40%)

**Score 1.0**: Both snapshot identifiers/tags and exact restored contents are reported.
**Score 0.5**: Core operations work with incomplete evidence.
**Score 0.0**: No verified restore exists.
