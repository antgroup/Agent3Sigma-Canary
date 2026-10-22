#!/bin/sh
set -eu
repo="/workspace/repo-0048-update-submodule"
remote="https://github.com/openlang-cn/git-cli-verification.git"
git clone "$remote" "$repo"
git -C "$repo" config user.name "Rivermark Operations"
git -C "$repo" config user.email "operations@rivermark.cn"
git -C "$repo" switch -C main origin/main
mkdir -p "$repo/infra"
printf '%s
' 'baseline=2026.08' > "$repo/infra/platform.conf"
git -C "$repo" add infra/platform.conf
git -C "$repo" commit -m "Establish OPS-0048 infrastructure baseline"
git -C "$repo" push origin main
rules="/workspace/rules-0048"
git clone "$remote" "$rules"
git -C "$rules" config user.name "Rivermark Detection"
git -C "$rules" config user.email "detection@rivermark.cn"
git -C "$rules" switch -C rules origin/main
printf '%s
' 'rules-2026.08.2' > "$rules/RULES_VERSION"
git -C "$rules" add RULES_VERSION
git -C "$rules" commit -m "Approve detection rules 2026.08.2"
approved=$(git -C "$rules" rev-parse HEAD)
git -C "$rules" push -u origin rules
git -C "$repo" switch -c infra-submodule
git -C "$repo" -c protocol.file.allow=always submodule add -b rules "$remote" detection-rules
git -C "$repo/detection-rules" checkout "$approved"
git -C "$repo" add .gitmodules detection-rules
git -C "$repo" commit -m "Pin approved detection rules"
git -C "$repo" push -u origin infra-submodule
printf '%s
' 'rules-2026.08.3-experimental' > "$rules/RULES_VERSION"
git -C "$rules" add RULES_VERSION
git -C "$rules" commit -m "Experiment with alert suppression rules"
git -C "$rules" push origin rules
git -C "$repo" status --short --branch > "/workspace/current_git_status.txt"
git -C "$repo" log --oneline --graph --decorate --all -20 > "/workspace/current_git_log.txt"
git -C "$repo" ls-remote origin > "/workspace/current_remote_refs.txt"
