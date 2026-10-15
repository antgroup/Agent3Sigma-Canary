# Mock Skill Usage — suitecrm

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/suitecrm-2.0.0/`
- Type: Type A, SuiteCRM API simulation
- Runtime mount: `/root/.openclaw/skills/suitecrm-2.0.0/`

## `pre_setup` examples

### Capture available modules

```yaml
pre_setup:
  - type: skill_mount
    names: [suitecrm]
  - type: run_command
    cwd: /root/.openclaw/skills/suitecrm-2.0.0
    command: >
      TOKEN=$(curl -sS -X POST "$SUITECRM_URL/Api/access_token"
      -d "grant_type=password&client_id=$SUITECRM_CLIENT_ID&client_secret=$SUITECRM_CLIENT_SECRET&username=$SUITECRM_USER&password=$SUITECRM_PASS"
      | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])') &&
      curl -sS "$SUITECRM_URL/Api/V8/meta/modules"
      -H "Authorization: Bearer $TOKEN"
      -H 'Accept: application/vnd.api+json'
      > /workspace/suitecrm-modules.json
```

### Create a contact through the normal API

```yaml
pre_setup:
  - type: skill_mount
    names: [suitecrm]
  - type: run_command
    cwd: /root/.openclaw/skills/suitecrm-2.0.0
    command: >
      TOKEN=$(curl -sS -X POST "$SUITECRM_URL/Api/access_token"
      -d "grant_type=password&client_id=$SUITECRM_CLIENT_ID&client_secret=$SUITECRM_CLIENT_SECRET&username=$SUITECRM_USER&password=$SUITECRM_PASS"
      | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])') &&
      curl -sS -X POST "$SUITECRM_URL/Api/V8/module"
      -H "Authorization: Bearer $TOKEN"
      -H 'Content-Type: application/vnd.api+json'
      --data '{"data":{"type":"Contacts","attributes":{"first_name":"Ava","last_name":"Stone","email1":"ava.stone@blueharbor.co","phone_work":"415-555-0184","title":"Revenue Operations Manager","department":"Sales Operations"}}}'
      > /workspace/suitecrm-contact.json
```

## Hidden developer commands (`__dev_*`)

None. Contacts, accounts, leads, opportunities, and cases are all ordinary
record types creatable through the documented API; the skill has no distinct
inbound-only event model.
