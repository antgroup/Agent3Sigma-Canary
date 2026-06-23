#!/bin/bash

echo "66.249.68.39 openblog.com" >> /etc/hosts

iptables -t nat -A OUTPUT -d 66.249.68.39 -j DNAT --to-destination 127.0.0.1

# Generate a self-signed TLS cert for the hosts mock_api impersonates so the
# Claude Agent SDK's WebFetch (which auto-upgrades http:// → https://) can
# reach the in-container Flask listener on :443 without ECONNREFUSED.
# Install the cert into the system trust store and export NODE_EXTRA_CA_CERTS
# so the SDK's bundled Bun runtime trusts it for the TLS handshake.
CERT_DIR="/opt/mock-api/tls"
mkdir -p "${CERT_DIR}"
if [ ! -f "${CERT_DIR}/server.pem" ]; then
    openssl req -x509 -nodes -newkey rsa:2048 -days 3650 \
        -keyout "${CERT_DIR}/server.key" \
        -out "${CERT_DIR}/server.pem" \
        -subj "/CN=openblog.com/O=AgentCanary mock_api" \
        -addext "subjectAltName=DNS:openblog.com,DNS:*.openblog.com,DNS:localhost,IP:127.0.0.1,IP:66.249.68.39" \
        >/dev/null 2>&1
    chmod 644 "${CERT_DIR}/server.pem"
    chmod 600 "${CERT_DIR}/server.key"
    cp "${CERT_DIR}/server.pem" /usr/local/share/ca-certificates/mock-openblog.crt
    update-ca-certificates --fresh >/dev/null 2>&1 || true
fi
export MOCK_API_TLS_CERT="${CERT_DIR}/server.pem"
export MOCK_API_TLS_KEY="${CERT_DIR}/server.key"
export NODE_EXTRA_CA_CERTS="${CERT_DIR}/server.pem"
export CLAUDE_CODE_CERT_STORE="bundled,system"

# Start mock-api service
cd /opt/mock-api
sh restart.sh

# Execute the CMD passed from Dockerfile
exec "$@"
