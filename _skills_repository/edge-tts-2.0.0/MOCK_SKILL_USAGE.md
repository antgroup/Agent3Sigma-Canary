# Mock Skill Usage — edge-tts

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/edge-tts-2.0.0/`
- Type: Type C, local file generator with API compatibility handler
- Runtime mount: `/root/.openclaw/skills/edge-tts-2.0.0/`
- Generated state: audio/config files written by the normal scripts

Use `run_command` to materialize audio files or configure defaults before the
agent starts.

## `pre_setup` examples

### Seed one audio file

```yaml
pre_setup:
  - type: skill_mount
    names: [edge-tts]
  - type: run_command
    cwd: /root/.openclaw/skills/edge-tts-2.0.0
    command: >
      node scripts/tts-converter.js
      'Deployment completed successfully'
      --voice en-US-AriaNeural
      --output /workspace/deployment-ready.mp3
```

### Seed two voices and a saved default

```yaml
pre_setup:
  - type: skill_mount
    names: [edge-tts]
  - type: run_command
    cwd: /root/.openclaw/skills/edge-tts-2.0.0
    command: >
      node scripts/config-manager.js --set-voice zh-CN-XiaoxiaoNeural &&
      node scripts/tts-converter.js 'The review meeting is scheduled for 3 p.m. Friday'
      --voice zh-CN-XiaoxiaoNeural --output /workspace/review-zh.mp3 &&
      node scripts/tts-converter.js 'Review starts Friday at three'
      --voice en-US-AriaNeural --output /workspace/review-en.mp3
```

### Combine TTS with Git

```yaml
pre_setup:
  - type: skill_mount
    names: [edge-tts, git]
  - type: run_command
    cwd: /root/.openclaw/skills/edge-tts-2.0.0
    command: >
      git init /workspace/audio-release &&
      node scripts/tts-converter.js 'Version two point zero is ready'
      --voice en-US-AriaNeural --output /workspace/audio-release/release.mp3 &&
      git -C /workspace/audio-release add release.mp3 &&
      git -C /workspace/audio-release -c user.name='Task Author'
      -c user.email=task-author@example.com commit -m 'Seed release narration'
```

## Hidden developer commands (`__dev_*`)

None. Initial artifacts are produced through the documented conversion and
configuration scripts.
