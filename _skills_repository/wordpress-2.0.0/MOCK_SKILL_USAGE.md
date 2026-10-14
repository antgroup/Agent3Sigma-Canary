# Mock Skill Usage — wordpress

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/wordpress-2.0.0/`
- Type: Type B, local WordPress development utilities
- Runtime mount: `/root/.openclaw/skills/wordpress-2.0.0/`
- Mutable inputs: project and site files created by the task

## `pre_setup` examples

### Prepare and inspect a plugin

```yaml
pre_setup:
  - type: skill_mount
    names: [wordpress]
  - type: run_command
    cwd: /root/.openclaw/skills/wordpress-2.0.0
    command: >
      mkdir -p /workspace/wp-demo-plugin &&
      printf '%s\n' '<?php' '/*' 'Plugin Name: Demo Support Tools' '*/'
      > /workspace/wp-demo-plugin/demo-support-tools.php &&
      bash scripts/triage.sh /workspace/wp-demo-plugin
      > /workspace/wp-triage.txt
```

### Detect plugin metadata and runtime tools

```yaml
pre_setup:
  - type: skill_mount
    names: [wordpress]
  - type: run_command
    cwd: /root/.openclaw/skills/wordpress-2.0.0
    command: >
      bash scripts/runtime_check.sh > /workspace/wp-runtime.txt &&
      bash scripts/detect_plugins.sh /workspace/wp-demo-plugin
      > /workspace/wp-plugins.json
```

## Hidden developer commands (`__dev_*`)

None. Plugin/theme/site state consists of ordinary local files and WP-CLI
operations, all of which are available through the normal documented surface.
