---
name: wordpress
description: >
  Work on WordPress plugins, themes, REST API code, WP-CLI operations, and
  WordPress Playground workflows using the bundled WordPress agent guidance and
  the WordPress runtime tools available in the image.
allowed-tools: Read, Bash
---

# WordPress Skill

Use this skill for WordPress development and operations tasks. It combines
WordPress-specific agent guidance from `WordPress/agent-skills` with real
runtime tools in the image:

- `wp` for WP-CLI operations.
- `wp-playground-cli` for disposable WordPress Playground environments.
- PHP CLI and common PHP extensions for WordPress checks.
- Node.js for the upstream detection scripts.

## First Step

Read the routed guidance under:

```text
/tmp/scry/skill_data/wordpress/agent_skills/skills/wordpress-router/SKILL.md
/tmp/scry/skill_data/wordpress/agent_skills/skills/wp-project-triage/SKILL.md
/tmp/scry/skill_data/wordpress/agent_skills/skills/wp-plugin-development/SKILL.md
/tmp/scry/skill_data/wordpress/agent_skills/skills/wp-rest-api/SKILL.md
/tmp/scry/skill_data/wordpress/agent_skills/skills/wp-wpcli-and-ops/SKILL.md
/tmp/scry/skill_data/wordpress/agent_skills/skills/wp-playground/SKILL.md
```

The writable guidance directory is prepared automatically when the container
starts. If it is missing, run:

```bash
bash scripts/prepare_agent_skills.sh
```

## Useful Commands

| Command | Purpose |
| --- | --- |
| `bash scripts/prepare_agent_skills.sh` | Restore the bundled WordPress guidance into `/tmp/scry/skill_data/wordpress/agent_skills` |
| `bash scripts/runtime_check.sh` | Print PHP, WP-CLI, and Playground availability |
| `bash scripts/triage.sh [repo_root]` | Run the upstream WordPress project detector |
| `bash scripts/detect_plugins.sh [repo_root]` | Detect WordPress plugin headers |
| `bash scripts/wpcli_inspect.sh --path=<wp-root> [--url=<url>]` | Inspect a WordPress site with WP-CLI |

## Workflow

1. Run `bash scripts/runtime_check.sh` to confirm runtime availability.
2. Run `bash scripts/triage.sh <repo>` before editing WordPress code.
3. Route to the relevant upstream skill:
   - plugin work: `/tmp/scry/skill_data/wordpress/agent_skills/skills/wp-plugin-development/SKILL.md`
   - REST API work: `/tmp/scry/skill_data/wordpress/agent_skills/skills/wp-rest-api/SKILL.md`
   - WP-CLI operations: `/tmp/scry/skill_data/wordpress/agent_skills/skills/wp-wpcli-and-ops/SKILL.md`
   - Playground environments: `/tmp/scry/skill_data/wordpress/agent_skills/skills/wp-playground/SKILL.md`
4. Prefer the repository's existing build, lint, and test commands.
5. For operations that write to a WordPress site, verify the target with
   `wp --info`, `wp core is-installed`, and the intended `--path`/`--url`.

## Notes

- Do not use production data for disposable Playground runs.
- WP-CLI commands that modify a site can be destructive; inspect first and
  use dry-run flags when the upstream guidance recommends them.
- If a task only needs static code analysis, use the bundled Node detectors
  before starting a full WordPress runtime.
