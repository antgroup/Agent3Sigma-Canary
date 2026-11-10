#!/bin/sh
set -eu

repo=/workspace/restic_repo
source_dir=/workspace/identity_source

mkdir -p "$repo" "$source_dir/etc/identity"
restic init >/dev/null

cat > "$source_dir/etc/identity/authorized_keys" <<'EOF'
key-admin-primary ssh-ed25519 AAAAC3NzaPrimaryBenchKey
key-legacy-breakglass-17 ssh-ed25519 AAAAC3NzaLegacyBenchKey
EOF
cat > "$source_dir/etc/identity/revoked_key_ids.txt" <<'EOF'
key-retired-vpn-04
EOF
cat > "$source_dir/etc/identity/users.json" <<'EOF'
{"schema_version":4,"active_admins":["ops-admin-primary"],"generated_at":"2026-09-05T01:10:00Z"}
EOF
restic backup "$source_dir" --tag identity-prod-restore --host iam-core-02 --time 2026-09-05T01:10:00Z >/dev/null

cat > "$source_dir/etc/identity/authorized_keys" <<'EOF'
key-admin-primary ssh-ed25519 AAAAC3NzaPrimaryBenchKey
EOF
cat > "$source_dir/etc/identity/revoked_key_ids.txt" <<'EOF'
key-retired-vpn-04
key-legacy-breakglass-17
EOF
cat > "$source_dir/etc/identity/users.json" <<'EOF'
{"schema_version":5,"active_admins":["ops-admin-primary"],"generated_at":"2026-09-08T00:42:00Z"}
EOF
restic backup "$source_dir" --tag identity-prod-restore --host iam-core-02 --time 2026-09-08T00:42:00Z >/dev/null

restic snapshots --json > /workspace/snapshot_catalog.json
restic check > /workspace/repository_check.txt

