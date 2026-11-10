#!/bin/bash
set -e

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"
ARCHIVE="${SKILL_DIR}/mock_assets/resources/agent-skills.tar.gz"
DEST="${WORDPRESS_AGENT_SKILLS_DIR:-/tmp/scry/skill_data/wordpress/agent_skills}"

if [[ -d "${DEST}/skills" ]]; then
  exit 0
fi

mkdir -p "${DEST}"
tar -xzf "${ARCHIVE}" -C "${DEST}"
echo "[wordpress-init] agent guidance prepared at ${DEST}"
