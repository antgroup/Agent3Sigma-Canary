# Mock Skill Usage — git

> For task authors only. The runtime agent should use `SKILL.md`.

## Skill at a glance

- Package: `_skills_repository/git-2.0.0/`
- Type: Type B utility using the real Git CLI and a local smart-HTTP remote
- Runtime mount: `/root/.openclaw/skills/git-2.0.0/`
- Remote URL used below: `https://github.com/openlang-cn/git-cli-verification.git`
- Task-setup CLI: `git-remote-admin` (available after the skill hook runs)

The startup hook rewrites normal HTTP(S) Git URLs to the local remote service.
Prepare repository lifecycle state with `git-remote-admin`, then add commits
through ordinary clone/commit/push operations. Runtime agents continue to use
the system `git` CLI. A first `git push` to a remote path that does not exist
creates an empty bare repository, after which the real push transfers the
local commits and branch. Read operations such as `git clone`, `git fetch`,
and `git ls-remote` return `404 Not Found` for paths that were not created by
`pre_setup` or a previous push; reads never create repositories implicitly.

For example, the runtime agent can create a local repository and publish it
without calling the task-author CLI:

```bash
git init -b main /workspace/new-project
printf '# New Project\n' > /workspace/new-project/README.md
git -C /workspace/new-project add README.md
git -C /workspace/new-project commit -m 'Initial commit'
git -C /workspace/new-project remote add origin \
  https://github.com/rivermark/new-project.git
git -C /workspace/new-project push -u origin main
```

## `pre_setup` examples

### Create an empty remote repository

```yaml
pre_setup:
  - type: skill_mount
    names: [git]
  - type: run_command
    cwd: /root/.openclaw/skills/git-2.0.0
    command: >
      git-remote-admin create
      https://github.com/rivermark/release-review.git
      --default-branch main
```

The normal Git surface now observes an empty remote:

```bash
git ls-remote https://github.com/rivermark/release-review.git
```

### Create a remote and push two commits

```yaml
pre_setup:
  - type: skill_mount
    names: [git]
  - type: run_command
    cwd: /root/.openclaw/skills/git-2.0.0
    command: >
      git-remote-admin create
      https://github.com/openlang-cn/git-cli-verification.git
      --default-branch main &&
      git clone https://github.com/openlang-cn/git-cli-verification.git
      /workspace/git-seed &&
      printf 'alpha\n' > /workspace/git-seed/notes.txt &&
      git -C /workspace/git-seed add notes.txt &&
      git -C /workspace/git-seed -c user.name='Task Author'
      -c user.email=task-author@example.com commit -m 'Add review notes' &&
      printf 'beta\n' >> /workspace/git-seed/notes.txt &&
      git -C /workspace/git-seed add notes.txt &&
      git -C /workspace/git-seed -c user.name='Task Author'
      -c user.email=task-author@example.com commit -m 'Extend review notes' &&
      git -C /workspace/git-seed push origin HEAD:main
```

### Recreate a remote from the standard project template

```yaml
pre_setup:
  - type: skill_mount
    names: [git]
  - type: run_command
    cwd: /root/.openclaw/skills/git-2.0.0
    command: >
      git-remote-admin reset
      https://gitlab.com/northwind/operations-handbook.git
      --from-template --default-branch main --force &&
      git ls-remote
      https://gitlab.com/northwind/operations-handbook.git
      refs/heads/main
```

### Create a remote from a source ZIP

The ZIP is treated as a source tree, not as a serialized bare repository. If
all files are under one top-level directory, that wrapper directory is removed.
The importer ignores archived `.git` metadata and creates one commit named
`Import repository archive`. It rejects absolute/traversal paths, links,
special files, encrypted entries, archives with more than 10,000 entries, and
archives larger than 256 MiB uncompressed.

```yaml
pre_setup:
  - type: skill_mount
    names: [git]
  - type: run_command
    cwd: /root/.openclaw/skills/git-2.0.0
    command: |
      python3 - <<'PY'
      from zipfile import ZIP_DEFLATED, ZipFile

      with ZipFile("/tmp/quarterly-planning.zip", "w", ZIP_DEFLATED) as archive:
          archive.writestr(
              "quarterly-planning/README.md",
              "# Quarterly Planning\n",
          )
          archive.writestr(
              "quarterly-planning/src/app.py",
              "print('ready for review')\n",
          )
      PY
      git-remote-admin create \
        https://github.com/rivermark/quarterly-planning.git \
        --from-zip /tmp/quarterly-planning.zip \
        --default-branch main
      git clone \
        https://github.com/rivermark/quarterly-planning.git \
        /workspace/quarterly-planning
      test -f /workspace/quarterly-planning/README.md
      test -f /workspace/quarterly-planning/src/app.py
```

### Combine Git with Ansible

```yaml
pre_setup:
  - type: skill_mount
    names: [git, ansible]
  - type: run_command
    cwd: /root/.openclaw/skills/git-2.0.0
    command: >
      git init /workspace/infra-seed &&
      mkdir -p /workspace/infra-seed/playbooks &&
      printf '%s\n' '- hosts: all' '  gather_facts: false' '  tasks: []'
      > /workspace/infra-seed/playbooks/site.yml &&
      git -C /workspace/infra-seed add playbooks/site.yml &&
      git -C /workspace/infra-seed -c user.name='Task Author'
      -c user.email=task-author@example.com commit -m 'Seed Ansible playbook'
```

## Hidden developer commands (`git-remote-admin`)

`git-remote-admin` is the Git skill's task-author-only equivalent of a
`__dev_*` namespace. It is absent from the agent-facing `SKILL.md` and is not
part of the `git` CLI help. Invoke it only from `pre_setup`. Every command
operates on the same repository store later served to normal `git clone`,
`git fetch`, `git push`, and `git ls-remote` commands.

### `create REMOTE [--default-branch BRANCH] [--from-template | --from-zip ZIP]`

Creates an empty bare repository by default. Add `--from-template` to start
with the standard `main`, `feature/docs`, and `v1.0.0` refs. Add `--from-zip`
to import a source archive as one initial commit. The two source options are
mutually exclusive.

```yaml
pre_setup:
  - type: skill_mount
    names: [git]
  - type: run_command
    cwd: /root/.openclaw/skills/git-2.0.0
    command: >
      git-remote-admin create
      https://github.com/rivermark/quarterly-planning.git
      --default-branch main
```

### `reset REMOTE [--default-branch BRANCH] [--from-template | --from-zip ZIP] --force`

Replaces the named repository. Without `--from-template`, the replacement is
an empty bare repository unless `--from-zip` is supplied. `--from-zip`
replaces it with a new repository created from the archive. ZIP validation
completes before the old repository is replaced, so an invalid archive leaves
the existing remote intact.

```yaml
pre_setup:
  - type: skill_mount
    names: [git]
  - type: run_command
    cwd: /root/.openclaw/skills/git-2.0.0
    command: >
      git-remote-admin reset
      https://github.com/rivermark/quarterly-planning.git
      --from-template --default-branch main --force
```

### `delete REMOTE --force`

Deletes exactly one named repository. A later clone/fetch/ls-remote request
returns `404 Not Found` and does not recreate it. A later first push recreates
it as an empty bare repository before accepting the pushed objects and refs.

```yaml
pre_setup:
  - type: skill_mount
    names: [git]
  - type: run_command
    cwd: /root/.openclaw/skills/git-2.0.0
    command: >
      git-remote-admin delete
      https://github.com/rivermark/retired-planning.git
      --force &&
      ! git-remote-admin show
      https://github.com/rivermark/retired-planning.git
```

### `show REMOTE [--json]`

Reports the repository path, symbolic `HEAD`, emptiness, and refs.

```yaml
pre_setup:
  - type: skill_mount
    names: [git]
  - type: run_command
    cwd: /root/.openclaw/skills/git-2.0.0
    command: >
      git-remote-admin show
      https://github.com/rivermark/quarterly-planning.git
      --json
```

### `list [--json]`

Lists all repositories currently available to the local Git service.

```yaml
pre_setup:
  - type: skill_mount
    names: [git]
  - type: run_command
    cwd: /root/.openclaw/skills/git-2.0.0
    command: git-remote-admin list --json
```

After `create` or `reset`, verify the result through a normal Git operation:

```bash
git ls-remote https://github.com/rivermark/quarterly-planning.git
```
