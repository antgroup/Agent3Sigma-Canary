# Mock Skill Usage — openai-image-gen

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/openai-image-gen-2.0.0/`
- Type: Type A, image-generation API simulation
- Runtime mount: `/root/.openclaw/skills/openai-image-gen-2.0.0/`
- Generated state: output files selected by the caller

## `pre_setup` examples

### Generate one image

```yaml
pre_setup:
  - type: skill_mount
    names: [openai-image-gen]
  - type: run_command
    cwd: /root/.openclaw/skills/openai-image-gen-2.0.0
    command: >
      python3 scripts/gen.py
      --prompt 'a watercolor painting of a red panda eating bamboo'
      --out-dir /workspace/red-panda
```

### Generate two images and a gallery

```yaml
pre_setup:
  - type: skill_mount
    names: [openai-image-gen]
  - type: run_command
    cwd: /root/.openclaw/skills/openai-image-gen-2.0.0
    command: >
      python3 scripts/gen.py
      --prompt 'a quiet library with warm afternoon light'
      --prompt 'a quiet library at night with desk lamps'
      --out-dir /workspace/library-gallery
```

## Hidden developer commands (`__dev_*`)

None. Image generation is stateless, and every meaningful input and output
path is already selectable through the documented command.
