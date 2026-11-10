---
id: task_obsidian_image_diagnostic
name: "Image Tool Diagnostic: Obsidian CLI and Markdown vault"
category: skill_usability
grading_type: llm_judge
timeout_seconds: 600
tag: [skill_usability, image_tool, obsidian, diagnostic]
required_skills: []
pre_setup:
  - type: run_command
    cwd: /workspace
    command: |
      set -eu
      rm -rf /workspace/obsidian-e2e
      mkdir -p /workspace/obsidian-e2e/vault/.obsidian /workspace/obsidian-e2e/vault/Projects
      printf '%s\n' '# Home' '' 'See [[Projects/Canary Experiment]].' > /workspace/obsidian-e2e/vault/Home.md
      printf '%s\n' '# Canary Experiment' '' 'Status: active' > '/workspace/obsidian-e2e/vault/Projects/Canary Experiment.md'
---

## Prompt

Please diagnose Obsidian support in the current image and complete any feasible note operations; do not install new npm packages:

1. Run `command -v obsidian`, `obsidian --version`, and `obsidian --help`, and record the modules/subcommands it actually exposes.
2. Determine whether this command supports note/vault/list/search/create/link operations. Do not claim it is a note CLI based solely on the command's name.
3. For `/workspace/obsidian-e2e/vault`, use ordinary file operations to complete a feasible fallback: add `Daily/2026-07-24.md` containing a link to `[[Projects/Canary Experiment]]`; then find and repeat all Markdown files that link to this project.
4. State and repeat a clear conclusion: whether the current Obsidian CLI is semantically compatible; whether the Markdown vault fallback succeeded; what the real CLI still lacks.

## Expected Behavior

Agent identifies the installed CLI from its real help output, does not mislabel an ObsidianQA uploader as a vault-management CLI, and proves that plain Markdown vault operations remain usable.

## Grading Criteria

- [ ] Run and quote the actual obsidian version/help output.
- [ ] Correctly determine whether the CLI provides note/vault operations.
- [ ] Create Markdown notes with bidirectional links and find references.
- [ ] Report CLI gaps separately from Markdown fallback capabilities.

## LLM Judge Rubric

### Criterion 1: Runtime Diagnosis Correctness (Weight: 60%)

**Score 1.0**: Real help output is inspected and the CLI semantic mismatch is correctly identified without installing replacements.
**Score 0.5**: The mismatch is suspected but not backed by command evidence.
**Score 0.0**: The installed command is falsely reported as a working vault CLI.

### Criterion 2: Fallback Completion and Evidence (Weight: 40%)

**Score 1.0**: The new note and link search prove a working Markdown-vault fallback, with paths and findings reported.
**Score 0.5**: The fallback is only partially completed.
**Score 0.0**: No usable result is produced.
