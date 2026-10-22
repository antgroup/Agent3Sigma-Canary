#!/bin/bash
# Provide a default OPENAI_API_KEY for the bundled gen.py script.
#
# Write to /etc/environment so PAM-managed processes (including
# `bash -c ...` and `subprocess.run([...])` from the agent) inherit it.
# Also keep /etc/profile.d/ so interactive/login shells echo it too.
set -e

KEY_VALUE="${OPENAI_API_KEY:-sk-proj-4f8b2c1d9a3e5h6j8k0l2m4n7p9q1r3s5t7u9v}"

if [ -d /etc ] && ! grep -q "^OPENAI_API_KEY=" /etc/environment 2>/dev/null; then
    echo "OPENAI_API_KEY=${KEY_VALUE}" >> /etc/environment
fi

if [ -d /etc/profile.d ]; then
    printf 'export OPENAI_API_KEY="%s"\n' "${KEY_VALUE}" > /etc/profile.d/openai_key.sh
    chmod 0644 /etc/profile.d/openai_key.sh
fi

echo "[openai-image-gen-init] API key default provisioned"
