# git-cli Skill

Git command-line assistant: Answer questions or perform Git-related operations in Cursor (check status, stage and commit, branches, push and pull, stash, history, tags, merge/rebase, clone, etc.). **SKILL.md** is intended for AI and explains when and how to use it, safety principles, and a quick reference; this README is intended for humans and explains the directory structure and usage.

## When to Use

- The user asks things like “How do I use Git to do XXX?”, “What does this command mean?”, or “What should I do when a push is rejected?”
- When the user needs to check the current status, write a commit message, create a branch, resolve conflicts, or recover from a mistaken operation, AI should first consult this skill’s Quick Reference and reference/, and cite scripts/ or assets/ when necessary.

## Directory Structure

```
git-cli/
├── SKILL.md              # AI Workflow guide: process, safety, quick reference, where to look
├── README.md              # This file (human-readable guide)
├── reference/             # Detailed reference (commands, workflows, troubleshooting)
│   ├── README.md
│   ├── commands.md        # Command list and common options
│   ├── workflows.md       # Step-by-step workflows
│   └── troubleshooting.md # Common errors and how to handle them
├── scripts/               # Executable scripts (run from the repository root)
│   ├── README.md
│   ├── is-repo.sh         # Whether the current directory is Git repository
│   ├── status-summary.sh  # branch + upstream + latest commit + Status
│   └── branch-list.sh    # local/remote branches and upstreams
└── assets/                # Templates and static assets
    ├── README.md
    ├── commit-msg-template.txt  # Commit message template (Conventional Commits)
    └── gitignore-common.txt     # Common .gitignore snippets
```

## Directory Descriptions

| Directory | Contents | Typical Use |
|------|------|----------|
| **reference/** | Command tables, step-by-step workflows, troubleshooting notes | For detailed steps or to look up a command, see [commands.md](reference/commands.md), [workflows.md](reference/workflows.md), and [troubleshooting.md](reference/troubleshooting.md) |
| **scripts/** | Bash scripts | Run from the **repository root**, for example: `bash path/to/scripts/status-summary.sh`; on Windows, use Git Bash or WSL |
| **assets/** | Commit message and .gitignore templates | For formatting examples or ignore rules, see [commit-msg-template.txt](assets/commit-msg-template.txt) and [gitignore-common.txt](assets/gitignore-common.txt) |

## Running the Script

- Environment: Git must be installed, and you must be in the **repository root** to inspect (or first `cd` to that directory).
- Windows: Run in **Git Bash** or **WSL**, for example:
  ```bash
  bash .cursor/skills/git-cli/scripts/status-summary.sh
  ```
- See [scripts/README.md](scripts/README.md) for the purpose of each script.

## Dependencies and Conventions

- **Git**: Must be in PATH (`git --version` must work).
- **Scripts**: Only `.sh` versions are provided for cross-platform compatibility and clawhub publishing; Windows users can use them via Git Bash/WSL.
