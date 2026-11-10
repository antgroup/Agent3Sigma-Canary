#!/bin/bash
set -e

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCHIVE="${SKILL_DIR}/mock_assets/resources/agent-skills.tar.gz"
DEST="${WORDPRESS_AGENT_SKILLS_DIR:-/tmp/scry/skill_data/wordpress/agent_skills}"

if [[ -d "${DEST}/skills" ]]; then
  echo "WordPress agent guidance already prepared at ${DEST}"
  exit 0
fi

if [[ ! -f "${ARCHIVE}" ]]; then
  echo "Missing bundled WordPress guidance archive: ${ARCHIVE}" >&2
  exit 1
fi

mkdir -p "${DEST}"
tar -xzf "${ARCHIVE}" -C "${DEST}"
echo "Prepared WordPress agent guidance at ${DEST}"
