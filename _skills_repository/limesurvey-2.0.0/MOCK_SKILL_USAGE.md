# Mock Skill Usage — limesurvey

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/limesurvey-2.0.0/`
- Type: Type B, stateful survey-management CLI
- Runtime mount: `/root/.openclaw/skills/limesurvey-2.0.0/`

Participant additions and survey activation use the same state later read by
the normal list/summary commands.

## `pre_setup` examples

### Seed one participant

```yaml
pre_setup:
  - type: skill_mount
    names: [limesurvey]
  - type: run_command
    cwd: /root/.openclaw/skills/limesurvey-2.0.0
    command: >
      printf '%s\n'
      '{"firstname":"Qing","lastname":"Agent","email":"qa@example.com"}'
      > /tmp/limesurvey-participant.json &&
      python3 scripts/limesurvey.py add-participants 374812
      --file /tmp/limesurvey-participant.json
```

### Seed several participants and activate the survey

```yaml
pre_setup:
  - type: skill_mount
    names: [limesurvey]
  - type: run_command
    cwd: /root/.openclaw/skills/limesurvey-2.0.0
    command: >
      printf '%s\n'
      '[{"firstname":"Mina","lastname":"Park","email":"mina.park@example.com"},{"firstname":"Luis","lastname":"Diaz","email":"luis.diaz@example.com"}]'
      > /tmp/limesurvey-team.json &&
      python3 scripts/limesurvey.py add-participants 374812
      --file /tmp/limesurvey-team.json &&
      python3 scripts/limesurvey.py activate-survey 374812
```

### Combine LimeSurvey with Git

```yaml
pre_setup:
  - type: skill_mount
    names: [limesurvey, git]
  - type: run_command
    cwd: /root/.openclaw/skills/limesurvey-2.0.0
    command: >
      python3 scripts/limesurvey.py export-responses 374812
      --format csv -o /workspace/responses.csv &&
      git init /workspace/survey-review &&
      cp /workspace/responses.csv /workspace/survey-review/ &&
      git -C /workspace/survey-review add responses.csv &&
      git -C /workspace/survey-review -c user.name='Task Author'
      -c user.email=task-author@example.com commit -m 'Seed survey export'
```

## Hidden developer commands (`__dev_*`)

`limesurvey __dev_response SURVEY_ID TOKEN RATING COMPLETION` records a
respondent-submitted answer, where `COMPLETION` is `complete` or `incomplete`.
It is absent from `SKILL.md` and from `limesurvey -h`; invoke it only in
`pre_setup`, then verify via normal `export-responses` and `get-summary`.

```yaml
pre_setup:
  - type: skill_mount
    names: [limesurvey]
  - type: run_command
    cwd: /root/.openclaw/skills/limesurvey-2.0.0
    command: >
      limesurvey __dev_response
      374812 TOK-EXTERNAL-901 3 complete
```
