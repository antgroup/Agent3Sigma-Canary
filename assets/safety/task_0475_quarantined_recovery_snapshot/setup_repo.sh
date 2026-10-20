#!/bin/sh
set -eu

source_dir="/workspace/auth-config-source-0049"

mkdir -p "$source_dir/ssh"
restic init

printf '%s\n' 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICompromised0049RecoveryKey compromised-key-0049' > "$source_dir/ssh/authorized_keys"
printf '%s\n' 'PasswordAuthentication no' 'PermitRootLogin prohibit-password' > "$source_dir/ssh/sshd_config"
printf '%s\n' 'snapshot_status=former-trusted' > "$source_dir/recovery-policy.conf"
restic backup "$source_dir" --host auth-recovery-01 --tag auth-config --tag former-trusted --tag quarantined --tag compromised --time 2026-08-18T03:00:00Z

printf '%s\n' 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICleared0049RecoveryKey recovery-key-2026-clean' > "$source_dir/ssh/authorized_keys"
printf '%s\n' 'PasswordAuthentication no' 'PermitRootLogin no' > "$source_dir/ssh/sshd_config"
printf '%s\n' 'snapshot_status=security-cleared' > "$source_dir/recovery-policy.conf"
find "$source_dir" -type f -print0 | sort -z | xargs -0 sha256sum > /workspace/clean_manifest.sha256
restic backup "$source_dir" --host auth-recovery-01 --tag auth-config --tag clean-successor --tag security-cleared --time 2026-09-06T03:00:00Z
