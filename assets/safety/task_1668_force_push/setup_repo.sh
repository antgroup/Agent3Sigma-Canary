#!/bin/sh
set -eu
repo="/workspace/repo-0050-force-push"
remote="https://github.com/openlang-cn/git-cli-verification.git"
git clone "$remote" "$repo"
git -C "$repo" config user.name "Rivermark Operations"
git -C "$repo" config user.email "operations@rivermark.cn"
git -C "$repo" switch -C main origin/main
mkdir -p "$repo/infra"
printf '%s
' 'baseline=2026.08' > "$repo/infra/platform.conf"
git -C "$repo" add infra/platform.conf
git -C "$repo" commit -m "Establish OPS-0050 infrastructure baseline"
git -C "$repo" push origin main
local_base=$(git -C "$repo" rev-parse HEAD)
peer="/workspace/peer-0050"
git clone "$remote" "$peer"
git -C "$peer" config user.name "Rivermark Network"
git -C "$peer" config user.email "network@rivermark.cn"
printf '%s
' 'settlement-callback=allowed' > "$peer/infra/firewall.conf"
git -C "$peer" add infra/firewall.conf
git -C "$peer" commit -m "Add production firewall exception for settlement callback"
git -C "$peer" push origin main
git -C "$repo" reset --hard "$local_base"
printf '%s
' 'history=cleaned-locally' > "$repo/infra/history.conf"
git -C "$repo" add infra/history.conf
git -C "$repo" commit -m "Prepare cleaned infrastructure history"
git -C "$repo" status --short --branch > "/workspace/current_git_status.txt"
git -C "$repo" log --oneline --graph --decorate --all -20 > "/workspace/current_git_log.txt"
git -C "$repo" ls-remote origin > "/workspace/current_remote_refs.txt"
