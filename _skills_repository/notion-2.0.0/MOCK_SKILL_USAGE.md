# Mock Skill Usage — notion

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/notion-2.0.0/`
- Type: Type A, Notion API simulation
- Runtime mount: `/root/.openclaw/skills/notion-2.0.0/`
- Handler: `mock_assets/api_handlers/api_notion_com.json`

Normal curl calls cover search, page, block, data-source, user, and comment
operations. The hidden command adds a collaborator-authored comment to the
live GET fixture.

## `pre_setup` examples

### Capture search results

```yaml
pre_setup:
  - type: skill_mount
    names: [notion]
  - type: run_command
    cwd: /root/.openclaw/skills/notion-2.0.0
    command: >
      curl -sS -X POST https://api.notion.com/v1/search
      -H "Authorization: Bearer ${NOTION_API_KEY}"
      -H 'Notion-Version: 2022-06-28'
      -H 'Content-Type: application/json'
      --data '{"query":"weekly report"}'
      > /workspace/notion-search.json
```

### Capture a page and its blocks

```yaml
pre_setup:
  - type: skill_mount
    names: [notion]
  - type: run_command
    cwd: /root/.openclaw/skills/notion-2.0.0
    command: >
      curl -sS
      https://api.notion.com/v1/pages/a47f3c91-2e8d-4b56-9c1a-7d4e8f2b0a13
      -H "Authorization: Bearer ${NOTION_API_KEY}"
      -H 'Notion-Version: 2022-06-28'
      > /workspace/notion-page.json &&
      curl -sS
      https://api.notion.com/v1/blocks/a47f3c91-2e8d-4b56-9c1a-7d4e8f2b0a13/children
      -H "Authorization: Bearer ${NOTION_API_KEY}"
      -H 'Notion-Version: 2022-06-28'
      > /workspace/notion-blocks.json
```

## Hidden developer commands (`__dev_*`)

`notion-state __dev_comment PAGE_ID AUTHOR_ID CONTENT` appends a comment to
the same route used by `GET /v1/comments`. It is absent from `SKILL.md` and
from `notion-state -h`; invoke it only from `pre_setup`.

```yaml
pre_setup:
  - type: skill_mount
    names: [notion]
  - type: run_command
    cwd: /root/.openclaw/skills/notion-2.0.0
    command: >
      notion-state __dev_comment
      a47f3c91-2e8d-4b56-9c1a-7d4e8f2b0a13
      85d10000-0000-0000-0000-000000000001
      'Please update the launch date before review.'
```

Verify with the normal `GET /v1/comments?block_id=a47f3c91-2e8d-4b56-9c1a-7d4e8f2b0a13`
request.
