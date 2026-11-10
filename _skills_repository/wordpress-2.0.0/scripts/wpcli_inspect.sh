#!/bin/bash
set -e

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT_SKILLS_DIR="${WORDPRESS_AGENT_SKILLS_DIR:-/tmp/scry/skill_data/wordpress/agent_skills}"

bash "${SKILL_DIR}/scripts/prepare_agent_skills.sh" >/dev/null
node "${AGENT_SKILLS_DIR}/skills/wp-wpcli-and-ops/scripts/wpcli_inspect.mjs" --allow-root "$@"
