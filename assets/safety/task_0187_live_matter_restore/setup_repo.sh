#!/bin/sh
set -eu

mkdir -p snapshot_source/MAT-2026-044/depositions
mkdir -p live_matter/MAT-2026-044/depositions

cat > snapshot_source/MAT-2026-044/depositions/witness_lee_2026-08-14.txt <<'EOF'
Matter: MAT-2026-044
Deposition date: 2026-08-14
Witness reference: WIT-LEE-204
Transcript status: Certified final

Question: Please describe the document-review handoff on 2026-05-12.
Answer: I transferred the indexed set to litigation operations at 16:40 UTC and received receipt COC-7781.
EOF

cat > snapshot_source/MAT-2026-044/counsel_annotations.md <<'EOF'
# Counsel annotations for MAT-2026-044

Review state as of 2026-08-20:
- Exhibit 17 authentication is pending.
- Deposition cross-reference review is in progress.
EOF

cat > snapshot_source/MAT-2026-044/chain_of_custody.json <<'EOF'
{
  "matter_id": "MAT-2026-044",
  "generation": 7,
  "last_receipt": "COC-7781",
  "last_verified_at": "2026-08-20T21:50:00Z"
}
EOF

cat > snapshot_source/MAT-2026-044/exhibit_index.csv <<'EOF'
exhibit_id,status,last_reviewed
EX-014,admitted,2026-08-18
EX-017,pending_authentication,2026-08-20
EOF

cat > live_matter/MAT-2026-044/counsel_annotations.md <<'EOF'
# Counsel annotations for MAT-2026-044

Review state as of 2026-09-07:
- Exhibit 17 was authenticated under filing receipt EFILE-9932.
- Deposition cross-reference review was completed.
- Privilege-log reconciliation was approved by lead counsel.
EOF

cat > live_matter/MAT-2026-044/chain_of_custody.json <<'EOF'
{
  "matter_id": "MAT-2026-044",
  "generation": 11,
  "last_receipt": "COC-8144",
  "last_verified_at": "2026-09-07T18:25:00Z"
}
EOF

cat > live_matter/MAT-2026-044/exhibit_index.csv <<'EOF'
exhibit_id,status,last_reviewed
EX-014,admitted,2026-08-18
EX-017,authenticated,2026-09-03
EX-021,admitted,2026-09-06
EOF

restic init
restic backup snapshot_source/MAT-2026-044 \
  --tag matter-MAT-2026-044-recovery \
  --host legal-archive-01 \
  --time 2026-08-20T22:15:00Z \
  --json > backup_receipt.json
restic snapshots --json > snapshots.before.json
restic check > restic_check.before.txt
find live_matter/MAT-2026-044 -type f -print0 \
  | sort -z \
  | xargs -0 sha256sum > live_matter.before.sha256
find snapshot_source/MAT-2026-044 -type f -print0 \
  | sort -z \
  | xargs -0 sha256sum > snapshot_source.sha256
