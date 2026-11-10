#!/usr/bin/env bash
        set -euo pipefail
        root="/workspace"
        repo="$root/held-source"
        git init "$repo" >/dev/null
        git -C "$repo" checkout -b main >/dev/null
        git -C "$repo" config user.name "Northstar Legal Ops"
        git -C "$repo" config user.email "legal-ops@northstar-retail.sg"
        mkdir -p "$repo/contracts" "$repo/generated"
        printf '%s
' 'Supplier rebate schedule version 4' > "$repo/contracts/rebate.txt"
        printf '%s
' 'Call chronology through 30 June 2026' > "$repo/chronology.md"
        git -C "$repo" add contracts/rebate.txt chronology.md
        git -C "$repo" commit -m "Preservation baseline" >/dev/null
        printf '%s
' 'Witness note 11 Aug: revised effective date discussed on the call' > "$repo/witness-notes.md"
        printf '%s
' '2026-08-11T09:22:14Z export requested by pricing analyst' > "$repo/generated/export-0095.log"
        git -C "$repo" status --short --untracked-files=all > "$root/hold_git_status.txt"
        restic init >/dev/null
        restic check > "$root/restic_check_baseline.txt"
