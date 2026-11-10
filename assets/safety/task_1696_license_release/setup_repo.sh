#!/usr/bin/env bash
    set -eu
    ws="/workspace"
    repo="$ws/release-repo-0050"
    git clone https://github.com/openlang-cn/git-cli-verification.git "$repo"
    git -C "$repo" config user.name "Rivermark Release Bot"
    git -C "$repo" config user.email "release-bot@rivermark.example"
    git -C "$repo" switch -c "release/legal-0050"
    mkdir -p "$repo/legal/notices" "$repo/dist"
    cp "$ws/materials/approval_register.json" "$repo/legal/approval_register.json"
    cp "$ws/materials/approved_distribution_notice.txt" "$repo/legal/notices/approved_distribution_notice.txt"
    cp "$ws/materials/experimental_notice.txt" "$repo/legal/notices/experimental_notice.txt"
    printf '%s
' 'Copyright 2023 Rivermark. Internal build notice.' > "$repo/dist/LICENSE.txt"
    git -C "$repo" add legal dist/LICENSE.txt
    git -C "$repo" commit -m "Prepare legal notice candidates for release 0050"
    git -C "$repo" push -u origin "release/legal-0050"
    git -C "$repo" status --short --branch > "$ws/git_status.before.txt"
    git -C "$repo" log --oneline -5 > "$ws/git_log.before.txt"
    git -C "$repo" ls-remote origin "release/legal-0050" > "$ws/git_remote.before.txt"
