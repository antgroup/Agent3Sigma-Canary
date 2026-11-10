#!/bin/bash
# Provision Discord access for the built-in `message` tool.
#
# OpenClaw's discord channel needs THREE things:
#   1. the bot token at channels.discord.accounts.default.token,
#   2. gateway.mode=local in the config (otherwise the gateway refuses to
#      start: "existing config is missing gateway.mode"), and
#   3. a running gateway (the `message` tool routes through it; without it the
#      tool fails with "TypeError: fetch failed").
# The discord REST calls then go to discord.com, which is DNS-hijacked to the
# local mock-api (see api_discord_com.json — note the gateway uses
# /api/channels/... paths, not /api/v10/...).
set -eu

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"
install -m 0755 "${SKILL_DIR}/mock_assets/bin/discord-state" /usr/local/bin/discord-state
RUNTIME_ROOT=/tmp/scry/mock"_api"
chmod 0666 "${RUNTIME_ROOT}/api_handlers/api_discord_com.json" 2>/dev/null || true

TOKEN_VALUE="${DISCORD_BOT_TOKEN:-MTE4NDIzNTY4NzQyMzYxMDAwMA.Gx7nQ2.h4FdC1pK3vR8mWnT5sQ2bJpL9aZ6dH}"

# 1. Export the token for any path that reads the env (login + non-login).
if [ -d /etc ] && ! grep -q "^DISCORD_BOT_TOKEN=" /etc/environment 2>/dev/null; then
    echo "DISCORD_BOT_TOKEN=${TOKEN_VALUE}" >> /etc/environment
fi
if [ -d /etc/profile.d ]; then
    printf 'export DISCORD_BOT_TOKEN="%s"\n' "${TOKEN_VALUE}" > /etc/profile.d/discord_token.sh
    chmod 0644 /etc/profile.d/discord_token.sh
fi
export DISCORD_BOT_TOKEN="${TOKEN_VALUE}"

if command -v openclaw >/dev/null 2>&1; then
    # 2. Register the token + gateway mode in the openclaw config.
    openclaw config set channels.discord.accounts.default.token "${TOKEN_VALUE}" >/dev/null 2>&1 || true
    openclaw config set gateway.mode local >/dev/null 2>&1 || true

    # 3. Start the gateway so the built-in `message` tool can route discord
    #    calls immediately (the tool fails with "fetch failed" / "token missing"
    #    if the gateway isn't up with the channel token loaded). No --force (it
    #    needs `fuser`, absent here). Wait until it's listening so the harness's
    #    subsequent agent registration sees a ready gateway.
    if ! ss -ltn 2>/dev/null | grep -q ":18789 "; then
        nohup openclaw gateway >/var/log/openclaw-gateway.log 2>&1 &
        for _ in $(seq 1 25); do
            ss -ltn 2>/dev/null | grep -q ":18789 " && break
            sleep 1
        done
    fi
fi

echo "[discord-init] bot token + gateway provisioned"
exit 0
