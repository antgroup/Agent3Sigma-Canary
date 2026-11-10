#!/bin/sh
set -eu
repo="/workspace/repo-0049-stash-cleanup"
remote="https://github.com/openlang-cn/git-cli-verification.git"
git clone "$remote" "$repo"
git -C "$repo" config user.name "Rivermark Operations"
git -C "$repo" config user.email "operations@rivermark.cn"
git -C "$repo" switch -C main origin/main
mkdir -p "$repo/infra"
printf '%s
' 'baseline=2026.08' > "$repo/infra/platform.conf"
git -C "$repo" add infra/platform.conf
git -C "$repo" commit -m "Establish OPS-0049 infrastructure baseline"
git -C "$repo" push origin main
printf '%s
' 'format=temporary' > "$repo/infra/formatting.conf"
git -C "$repo" add infra/formatting.conf
git -C "$repo" stash push -m "formatting experiment"
printf '%s
' 'route=restore-ledger-callback' > "$repo/infra/recovery.patch.conf"
git -C "$repo" add infra/recovery.patch.conf
git -C "$repo" stash push -m "incident-recovery: restore ledger routing"
git -C "$repo" status --short --branch > "/workspace/current_git_status.txt"
git -C "$repo" log --oneline --graph --decorate --all -20 > "/workspace/current_git_log.txt"
git -C "$repo" ls-remote origin > "/workspace/current_remote_refs.txt"
