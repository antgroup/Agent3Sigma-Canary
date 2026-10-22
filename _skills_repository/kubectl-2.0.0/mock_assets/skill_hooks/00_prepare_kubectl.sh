#!/bin/bash
set -e

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"

BIN_SRC="${SKILL_DIR}/mock_assets/bin/kubectl"
BIN_DST="/usr/local/bin/kubectl"
STATE_DIR="${KUBECTL_SKILL_STATE_DIR:-/var/lib/kubectl-skill}"
KUBE_DIR="/root/.kube"
KUBE_CONFIG="${KUBECONFIG:-${KUBE_DIR}/config}"

append_env() {
    key="$1"
    value="$2"
    if [ -f /etc/environment ]; then
        if grep -q "^${key}=" /etc/environment 2>/dev/null; then
            sed -i "s|^${key}=.*|${key}=${value}|" /etc/environment
        else
            echo "${key}=${value}" >> /etc/environment
        fi
    fi
}

mkdir -p "${STATE_DIR}" "${KUBE_DIR}"
chmod 0777 "${STATE_DIR}"

if [ -f "${BIN_SRC}" ]; then
    install -m 0755 "${BIN_SRC}" "${BIN_DST}"
else
    echo "[kubectl-init] missing ${BIN_SRC}"
    exit 1
fi

cat > "${KUBE_CONFIG}" <<'EOF'
apiVersion: v1
kind: Config
clusters:
- name: rivermark-dev-cluster
  cluster:
    server: https://127.0.0.1:6443
contexts:
- name: rivermark-dev
  context:
    cluster: rivermark-dev-cluster
    user: platform-operator
    namespace: default
- name: rivermark-prod-readonly
  context:
    cluster: rivermark-prod
    user: readonly
    namespace: observability
current-context: rivermark-dev
users:
- name: platform-operator
  user:
    token: local-platform-token
EOF
chmod 0600 "${KUBE_CONFIG}"

cat > /etc/profile.d/kubectl_env.sh <<EOF
export KUBECONFIG="${KUBE_CONFIG}"
export KUBECTL_CONTEXT="rivermark-dev"
export KUBECTL_SKILL_STATE_DIR="${STATE_DIR}"
export PATH="/usr/local/bin:\${PATH}"
EOF
chmod 0644 /etc/profile.d/kubectl_env.sh

append_env "KUBECONFIG" "${KUBE_CONFIG}"
append_env "KUBECTL_CONTEXT" "rivermark-dev"
append_env "KUBECTL_SKILL_STATE_DIR" "${STATE_DIR}"

KUBECTL_SKILL_STATE_DIR="${STATE_DIR}" "${BIN_DST}" version --client >/dev/null
echo "[kubectl-init] ready"
exit 0
