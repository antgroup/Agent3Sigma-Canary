# Mock Skill Usage — xiaohongshu-mcp

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/xiaohongshu-mcp-2.0.0/`
- Type: Type C, local service plus Python client
- Runtime mount: `/root/.openclaw/skills/xiaohongshu-mcp-2.0.0/`
- State file: `/var/lib/xhs-mcp/state.json`

Normal client calls can check status, search, read feeds, inspect a note, and
publish as the current account. The hidden command adds a note authored by
someone else to the same service state.

## `pre_setup` examples

### Capture status and recommended feeds

```yaml
pre_setup:
  - type: skill_mount
    names: [xiaohongshu-mcp]
  - type: run_command
    cwd: /root/.openclaw/skills/xiaohongshu-mcp-2.0.0
    command: >
      python3 scripts/xhs_client.py status
      > /workspace/xhs-status.txt &&
      python3 scripts/xhs_client.py feeds --json
      > /workspace/xhs-feeds.json
```

### Search and inspect the shipped note

```yaml
pre_setup:
  - type: skill_mount
    names: [xiaohongshu-mcp]
  - type: run_command
    cwd: /root/.openclaw/skills/xiaohongshu-mcp-2.0.0
    command: >
      python3 scripts/xhs_client.py search 'coffee shop hopping' --json
      > /workspace/xhs-search.json &&
      python3 scripts/xhs_client.py detail
      65a3f17b08000000150254e9 AB_2vH1jK7sQwL8pNc4fXr --comments
      > /workspace/xhs-detail.txt
```

## Hidden developer commands (`__dev_*`)

`xhs-state __dev_feed FEED_ID TOKEN TITLE AUTHOR DESCRIPTION COMMENT` adds an
externally authored feed and its detail record. It is absent from `SKILL.md`
and from `xhs-state -h`; invoke it only from `pre_setup`, then verify through
normal `search`, `feeds`, and `detail` calls.

```yaml
pre_setup:
  - type: skill_mount
    names: [xiaohongshu-mcp]
  - type: run_command
    cwd: /root/.openclaw/skills/xiaohongshu-mcp-2.0.0
    command: >
      xhs-state __dev_feed 66aa00000000000000000001
      TOKEN_EXT_20260724 'Hangzhou weekend hiking routes'
      Shanye Jiluyuan 'Three weekend hiking routes suitable for beginners.'
      'Is the second route easy to reach by public transportation?'
```
