# Git Commands Reference

Detailed command list with common options. Use when the user needs options, variants, or examples beyond the Quick Reference in SKILL.md.

## Inspect state

| Command | Description |
|---------|-------------|
| `git status` | Short status (branch, staged, unstaged, untracked) |
| `git status -sb` | Short + branch in one line |
| `git diff` | Unstaged changes (working tree vs index) |
| `git diff --staged` | Staged changes (index vs HEAD) |
| `git diff --stat` | Summary of changed files and line counts |
| `git diff <commit> -- <path>` | Diff working tree against a commit |
| `git diff A..B` | Diff between two commits |

## Stage and unstage

| Command | Description |
|---------|-------------|
| `git add <path>` | Stage file or directory |
| `git add .` | Stage all changes in current tree |
| `git add -p` | Interactive stage (hunk by hunk) |
| `git restore --staged <path>` | Unstage, keep working tree changes |
| `git restore <path>` | Discard working tree changes (destructive) |
| `git restore .` | Discard all working tree changes (destructive) |

## Commit

| Command | Description |
|---------|-------------|
| `git commit -m "message"` | Commit with one-line message |
| `git commit` | Open editor for message (multi-line) |
| `git commit --amend --no-edit` | Amend last commit, keep message, add staged files |
| `git commit --amend -m "message"` | Amend last commit with new message |
| `git commit --allow-empty -m "message"` | Create empty commit |

## Branching

| Command | Description |
|---------|-------------|
| `git branch` | List local branches |
| `git branch -a` | List local + remote-tracking |
| `git branch -vv` | List with upstream and last commit |
| `git switch -c <name>` | Create branch and switch (Git 2.23+) |
| `git switch <name>` | Switch to existing branch |
| `git checkout -b <name>` | Create and switch (classic) |
| `git checkout <name>` | Switch (classic) |
| `git branch -d <name>` | Delete merged branch |
| `git branch -D <name>` | Force delete branch |

## Remote and sync

| Command | Description |
|---------|-------------|
| `git remote -v` | List remotes and URLs |
| `git remote show origin` | Detailed origin info (branches, push/pull) |
| `git fetch` | Fetch from default remote |
| `git fetch origin` | Fetch from origin |
| `git fetch --prune` | Fetch and remove stale remote-tracking refs |
| `git pull` | Fetch + merge current branch |
| `git pull --rebase` | Fetch + rebase current branch |
| `git push -u origin <branch>` | Push and set upstream |
| `git push` | Push to upstream |
| `git push origin --delete <branch>` | Delete remote branch |

## Stash

| Command | Description |
|---------|-------------|
| `git stash` | Stash working tree + index |
| `git stash push -m "message"` | Stash with message |
| `git stash list` | List stashes |
| `git stash show -p stash@{0}` | Show stash diff |
| `git stash apply` | Apply top stash, keep it |
| `git stash pop` | Apply top stash and drop |
| `git stash drop stash@{0}` | Drop a stash |
| `git stash branch <name>` | Create branch from stash and drop |

## History and blame

| Command | Description |
|---------|-------------|
| `git log --oneline -n 20` | Last 20 commits, one line each |
| `git log --oneline --decorate --graph --all` | Graph of all branches |
| `git log -p -- <path>` | Log with patch for file |
| `git log --follow -- <path>` | Follow renames |
| `git blame <path>` | Who changed each line |
| `git blame -L 10,20 <path>` | Blame lines 10–20 |
| `git reflog` | History of HEAD movements (for recovery) |

## Tags

| Command | Description |
|---------|-------------|
| `git tag` | List tags |
| `git tag v1.0` | Lightweight tag at current commit |
| `git tag -a v1.0 -m "msg"` | Annotated tag |
| `git push origin v1.0` | Push one tag |
| `git push origin --tags` | Push all tags |
| `git tag -d v1.0` | Delete local tag |
| `git push origin --delete v1.0` | Delete remote tag |

## Merge and rebase

| Command | Description |
|---------|-------------|
| `git merge <branch>` | Merge branch into current |
| `git merge --abort` | Abort merge after conflict |
| `git rebase <branch>` | Rebase current onto branch |
| `git rebase --continue` | After resolving conflict |
| `git rebase --abort` | Abort rebase |
| `git rebase -i HEAD~n` | Interactive rebase last n commits |

## Clone and init

| Command | Description |
|---------|-------------|
| `git clone <url>` | Clone into directory named from URL |
| `git clone <url> <dir>` | Clone into `<dir>` |
| `git clone --depth 1 <url>` | Shallow clone (single commit) |
| `git init` | Create repo in current directory |
| `git remote add origin <url>` | Add remote named origin |

## Utility

| Command | Description |
|---------|-------------|
| `git rev-parse --is-inside-work-tree` | Print "true" or "false" (for scripts) |
| `git rev-parse --show-toplevel` | Print repo root path |
| `git config --list --local` | List local config |
