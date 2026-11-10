# Git CLI Scripts

Run from **repository root**. Use Git Bash or WSL on Windows.

| Script | Purpose |
|--------|---------|
| `is-repo.sh` | Exit 0 if cwd is a Git repo, else 1. Use to confirm context. |
| `status-summary.sh` | Branch, upstream, last commit, and short status. |
| `branch-list.sh` | Local branches with upstream + all branches (local + remote). |

**Example:** `bash path/to/scripts/status-summary.sh`
