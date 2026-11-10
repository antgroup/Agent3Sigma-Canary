# Git Troubleshooting

Common errors and fixes. Use when the user reports an error message or unexpected behavior.

## "not a git repository" / "fatal: not a git repository"

- **Cause**: Current directory is not inside a Git repo.
- **Fix**:
  - Run commands from the project root (where `.git` exists), or
  - Initialize: `git init` (new repo), or
  - Clone: `git clone <url>`.

## "Permission denied (publickey)" or auth errors on push/pull

- **Cause**: SSH key not set up or not added to Git host (GitHub, GitLab, etc.).
- **Fix**: User must configure SSH keys or use HTTPS with credentials. Point to host’s docs (e.g. "Adding SSH key to GitHub"). Do not store passwords in skill.

## Push rejected: "Updates were rejected" / "non-fast-forward"

- **Cause**: Remote has commits the local branch doesn’t have.
- **Fix**:
  1. `git pull` or `git pull --rebase`.
  2. Resolve conflicts if any, then `git push`.
- **Do not** suggest `git push --force` unless the user explicitly wants to overwrite remote (e.g. after rebase) and understands the risk; then prefer `git push --force-with-lease`.

## Merge or rebase conflicts

- **Symptoms**: "CONFLICT (content)" in files, or merge/rebase stops.
- **Fix**:
  1. Open listed conflicted files; resolve `<<<<<<<`, `=======`, `>>>>>>>` sections.
  2. `git add <resolved-files>`.
  3. Merge: `git commit`. Rebase: `git rebase --continue`.
- To abort: `git merge --abort` or `git rebase --abort`.

## Detached HEAD

- **Symptoms**: Message says "You are in 'detached HEAD' state".
- **Cause**: Checked out a commit or tag instead of a branch.
- **Fix**: Switch back to a branch: `git switch main` (or branch name). To keep changes in a new branch: `git switch -c new-branch-name`.

## "Too many untracked files" or accidental add of build artifacts

- **Fix**:
  1. Suggest checking/adding a `.gitignore` (see [assets/gitignore-common.txt](../assets/gitignore-common.txt)).
  2. If already staged: `git restore --staged .` then add/update `.gitignore` and `git add .gitignore` and relevant paths only.

## Lost commits after reset or mistaken checkout

- **Fix**: `git reflog` to find the commit hash (e.g. "HEAD@{1}" before the bad reset). Then `git checkout <hash>` to inspect or `git reset --hard <hash>` to restore (warn: destructive).

## "branch has no upstream branch" when pushing

- **Fix**: First push with upstream: `git push -u origin <branch-name>`. After that, `git push` works.

## Large files / "file exceeds limit" (e.g. GitHub)

- **Cause**: Host rejects files over a size limit.
- **Fix**: Remove file from history (e.g. `git filter-branch` or `git filter-repo`), or use Git LFS. For one-time large file, remove from latest commit: `git reset HEAD^ path/to/file`, add to `.gitignore`, then `git commit --amend`.

## SSL certificate / HTTPS errors

- **Cause**: Corporate proxy, custom CA, or outdated certs.
- **Fix**: User may need to set `git config http.sslVerify false` temporarily (explain security trade-off) or install correct CA. Prefer directing to IT or host docs.
