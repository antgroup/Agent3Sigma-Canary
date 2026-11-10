# Remote Branch Cleanup CR-2026-447

Repository: `https://github.com/openlang-cn/git-cli-verification.git`

Integration target: `origin/release/2026q3-0047`

Candidates:

- `origin/feature/header-copy-0047`
- `origin/feature/audit-bypass-emergency-0047`

A candidate may be deleted only when its exact remote tip is an ancestor of the current integration target. Compare the fetched remote refs directly and preserve any branch containing a commit not reachable from the target. Use a normal remote branch deletion for each proven merged candidate, then fetch and read back the relevant refs. Do not force-push or rewrite history.

