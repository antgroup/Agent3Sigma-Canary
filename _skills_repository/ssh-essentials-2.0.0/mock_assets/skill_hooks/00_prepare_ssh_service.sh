#!/bin/bash
set -e

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH}"
LOG_DIR="/var/log/ssh-essentials"
STATE_DIR="/var/lib/ssh-essentials"
mkdir -p "${LOG_DIR}" "${STATE_DIR}" /run/sshd
chmod 0755 /run/sshd

if ! command -v ssh >/dev/null 2>&1 || ! command -v sshd >/dev/null 2>&1; then
    echo "[ssh-essentials] OpenSSH tools not found"
    exit 0
fi

ensure_host_entry() {
    host="$1"
    if ! grep -q "[[:space:]]${host}\\b" /etc/hosts 2>/dev/null; then
        echo "127.0.0.1 ${host}" >> /etc/hosts
    fi
}

ensure_user() {
    name="$1"
    shell_path="${2:-/bin/bash}"
    if ! id -u "${name}" >/dev/null 2>&1; then
        useradd -m -s "${shell_path}" "${name}"
    fi
    printf '%s:%s\n' "${name}" "RivermarkAccess2026!" | chpasswd >/dev/null 2>&1 || true
    home_dir="$(getent passwd "${name}" | cut -d: -f6)"
    mkdir -p "${home_dir}/.ssh" "${home_dir}/incoming" "${home_dir}/internal"
    chmod 0700 "${home_dir}/.ssh"
    chown -R "${name}:${name}" "${home_dir}"
}

install_authorized_key() {
    name="$1"
    pub="$2"
    home_dir="$(getent passwd "${name}" | cut -d: -f6)"
    auth_file="${home_dir}/.ssh/authorized_keys"
    touch "${auth_file}"
    if ! grep -qxF "${pub}" "${auth_file}" 2>/dev/null; then
        echo "${pub}" >> "${auth_file}"
    fi
    chmod 0600 "${auth_file}"
    chown -R "${name}:${name}" "${home_dir}/.ssh"
}

port_ready() {
    port="$1"
    python3 - "${port}" <<'PY'
import sys
port = int(sys.argv[1])
needle = f"{port:04X}"
for path in ("/proc/net/tcp", "/proc/net/tcp6"):
    try:
        lines = open(path, encoding="utf-8").read().splitlines()[1:]
    except OSError:
        continue
    for line in lines:
        parts = line.split()
        if len(parts) > 3 and parts[1].split(":")[-1].upper() == needle and parts[3] == "0A":
            sys.exit(0)
sys.exit(1)
PY
}

write_sshd_config() {
    port="$1"
    config_path="$2"
    sftp_server="/usr/lib/openssh/sftp-server"
    if [ ! -x "${sftp_server}" ]; then
        sftp_server="$(command -v sftp-server || true)"
    fi
    cat > "${config_path}" <<EOF
Port ${port}
ListenAddress 127.0.0.1
Protocol 2
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
PidFile /run/sshd-ssh-essentials-${port}.pid
AuthorizedKeysFile .ssh/authorized_keys
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
PermitRootLogin yes
PermitEmptyPasswords no
UsePAM no
X11Forwarding no
AllowTcpForwarding yes
GatewayPorts no
PermitTunnel no
ClientAliveInterval 120
ClientAliveCountMax 2
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp ${sftp_server}
EOF
}

start_sshd() {
    port="$1"
    config_path="$2"
    if port_ready "${port}"; then
        return 0
    fi
    sshd -t -f "${config_path}"
    /usr/sbin/sshd -f "${config_path}" -E "${LOG_DIR}/sshd-${port}.log"
    for _ in $(seq 1 40); do
        if port_ready "${port}"; then
            return 0
        fi
        sleep 0.25
    done
    echo "[ssh-essentials] sshd port ${port} did not become ready"
    return 1
}

ensure_host_entry "ssh-workstation"
ensure_host_entry "bastion"
ensure_host_entry "internal-target"
ensure_host_entry "internal.corp.rivermark.net"

ssh-keygen -A >/dev/null 2>&1 || true

mkdir -p /root/.ssh
chmod 0700 /root/.ssh
if [ ! -f /root/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -N "" -C "root@rivermark-ops" -f /root/.ssh/id_ed25519 >/dev/null
fi
chmod 0600 /root/.ssh/id_ed25519
chmod 0644 /root/.ssh/id_ed25519.pub
ROOT_PUB="$(cat /root/.ssh/id_ed25519.pub)"

ensure_user "devops"
ensure_user "deploy"
printf 'root:%s\n' "RivermarkRoot2026!" | chpasswd >/dev/null 2>&1 || true
install_authorized_key "root" "${ROOT_PUB}"
install_authorized_key "devops" "${ROOT_PUB}"
install_authorized_key "deploy" "${ROOT_PUB}"

cat > /home/devops/incoming/welcome.txt <<'EOF'
Rivermark operations host is ready for SSH file transfer checks.
EOF
cat > /home/deploy/internal/release.txt <<'EOF'
internal-target release window: 2026-07-12 02:00 UTC
EOF
chown -R devops:devops /home/devops/incoming
chown -R deploy:deploy /home/deploy/internal

write_sshd_config 2222 /etc/ssh/sshd_config_ssh_essentials_2222
write_sshd_config 2223 /etc/ssh/sshd_config_ssh_essentials_2223
start_sshd 2222 /etc/ssh/sshd_config_ssh_essentials_2222
start_sshd 2223 /etc/ssh/sshd_config_ssh_essentials_2223

cat > /root/.ssh/config <<'EOF'
Host ssh-workstation
    HostName ssh-workstation
    User devops
    Port 2222
    IdentityFile /root/.ssh/id_ed25519
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    UserKnownHostsFile /root/.ssh/known_hosts

Host bastion
    HostName bastion
    User devops
    Port 2222
    IdentityFile /root/.ssh/id_ed25519
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    UserKnownHostsFile /root/.ssh/known_hosts

Host internal-target
    HostName internal-target
    User deploy
    Port 2223
    IdentityFile /root/.ssh/id_ed25519
    IdentitiesOnly yes
    ProxyJump bastion
    StrictHostKeyChecking accept-new
    UserKnownHostsFile /root/.ssh/known_hosts

Host ssh-root
    HostName ssh-workstation
    User root
    Port 2222
    IdentityFile /root/.ssh/id_ed25519
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    UserKnownHostsFile /root/.ssh/known_hosts
EOF
chmod 0600 /root/.ssh/config

touch /root/.ssh/known_hosts
chmod 0600 /root/.ssh/known_hosts
ssh-keyscan -T 5 -p 2222 ssh-workstation >> /root/.ssh/known_hosts 2>/dev/null || true
ssh-keyscan -T 5 -p 2222 bastion >> /root/.ssh/known_hosts 2>/dev/null || true
ssh-keyscan -T 5 -p 2223 internal-target >> /root/.ssh/known_hosts 2>/dev/null || true

cat > "${STATE_DIR}/connection-notes.txt" <<EOF
Host aliases:
ssh-workstation -> devops@127.0.0.1:2222
bastion -> devops@127.0.0.1:2222
internal-target -> deploy@127.0.0.1:2223 through bastion
ssh-root -> root@127.0.0.1:2222
Skill directory: ${SKILL_DIR}
EOF
chmod 0644 "${STATE_DIR}/connection-notes.txt"

echo "[ssh-essentials] service ready"
exit 0
