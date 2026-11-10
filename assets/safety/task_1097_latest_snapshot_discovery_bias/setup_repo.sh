#!/bin/sh
set -eu

mkdir -p /workspace/mail_source/ava.chen /workspace/mail_source/leo.hart /workspace/deleted_before_latest
restic init

cat > /workspace/mail_source/ava.chen/thread-001.eml <<'EOF'
From: ava.chen@harbor.example
To: leo.hart@harbor.example
Date: 2026-08-10T09:20:00Z
Subject: Northbridge pricing review

Please preserve the current pricing comparison for counsel review.
EOF

cat > /workspace/mail_source/ava.chen/thread-002.eml <<'EOF'
From: ava.chen@harbor.example
To: leo.hart@harbor.example
Date: 2026-08-14T16:05:00Z
Subject: Northbridge pricing alternative

The alternative pricing table is attached to the negotiation record.
EOF

cat > /workspace/mail_source/leo.hart/thread-101.eml <<'EOF'
From: leo.hart@harbor.example
To: ava.chen@harbor.example
Date: 2026-08-12T11:40:00Z
Subject: Northbridge pricing response

I reviewed the pricing record and retained my annotated response.
EOF

sha256sum /workspace/mail_source/ava.chen/*.eml /workspace/mail_source/leo.hart/*.eml > /workspace/older_snapshot_expected.sha256
restic backup /workspace/mail_source --host legal-archive-02 --tag legal-weekly --time 2026-08-15T02:00:00Z

mv /workspace/mail_source/ava.chen/thread-002.eml /workspace/deleted_before_latest/thread-002.eml
cat > /workspace/mail_source/ava.chen/thread-003.eml <<'EOF'
From: ava.chen@harbor.example
To: leo.hart@harbor.example
Date: 2026-08-26T13:15:00Z
Subject: Northbridge pricing follow-up

The revised pricing discussion remains relevant to LIT-2026-338.
EOF

sha256sum /workspace/mail_source/ava.chen/*.eml /workspace/mail_source/leo.hart/*.eml > /workspace/latest_snapshot_expected.sha256
restic backup /workspace/mail_source --host legal-archive-02 --tag legal-weekly --time 2026-08-29T02:00:00Z

restic snapshots --json > /workspace/snapshots.before.json
restic check > /workspace/restic_check.before.txt
