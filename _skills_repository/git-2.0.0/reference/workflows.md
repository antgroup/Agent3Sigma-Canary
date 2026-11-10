# Git Workflows

Step-by-step workflows for common tasks. Use when the user needs a guided sequence beyond single commands.

## Daily: see what changed and commit

1. `git status` — see branch, staged/unstaged/untracked.
2. `git diff` — review unstaged changes; `git diff --staged` for staged.
3. `git add <paths>` or `git add .` — stage.
4. `git commit -m "descriptive message"`.

## Create a feature branch and push

1. Ensure clean state or commit/stash: `git status`.
2. Update main: `git switch main` then `git pull`.
3. Create branch: `git switch -c feature/my-feature`.
4. Make changes, then: `git add .` → `git commit -m "message"`.
5. First push: `git push -u origin feature/my-feature`.
6. Later: `git push`.

## Sync with remote when push is rejected

1. `git fetch` (or `git pull` / `git pull --rebase`).
2. If merge: resolve conflicts if any, then `git add` and `git commit`.
3. If rebase: resolve conflicts, `git add`, then `git rebase --continue`.
4. `git push`.

## Resolve merge or rebase conflicts

1. Open conflicted files; look for `<<<<<<<`, `=======`, `>>>>>>>`.
2. Edit to keep the correct content and remove markers.
3. `git add <resolved-files>`.
4. **Merge**: `git commit` (message often pre-filled).
5. **Rebase**: `git rebase --continue`. Repeat until done.

## Stash, switch branch, then restore

1. `git stash` (optionally `git stash push -m "WIP feature X"`).
2. `git switch other-branch` — do other work.
3. `git switch feature/x` then `git stash pop` (or `git stash apply` to keep stash).

## Amend last commit (forgot file or fix message)

1. Stage the forgotten file: `git add <file>`.
2. `git commit --amend --no-edit` — add to last commit, keep message.
   - Or: `git commit --amend -m "New message"` to change message.

## Release with a tag

1. Commit all changes and push: `git push`.
2. On the release commit: `git tag -a v1.0.0 -m "Release 1.0.0"`.
3. Push tag: `git push origin v1.0.0` or `git push origin --tags`.

## Recover after mistaken reset or checkout

1. `git reflog` — find the commit hash you want (e.g. before `reset --hard`).
2. `git checkout <hash>` to inspect, or `git reset --hard <hash>` to restore that state (destructive; confirm with user).

## Leave detached HEAD

If you checked out a commit or tag and see "detached HEAD":

1. `git switch main` (or the branch you want) — or create a new branch: `git switch -c new-branch`.

## Merge another branch into current

1. `git merge <branch>`.
2. If conflicts: resolve in files → `git add` → `git commit`.
3. If no conflicts: commit may be created automatically (or run `git commit` if needed).

## Rebase current branch onto main

1. `git fetch` then `git switch main` and `git pull`.
2. `git switch feature-branch` then `git rebase main`.
3. On conflict: fix files → `git add` → `git rebase --continue`.
4. Push: `git push` (may need `--force-with-lease` if branch was already pushed; warn user).
