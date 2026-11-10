#!/bin/bash
set -e

REPO_ROOT="${1:-$(pwd)}"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT_SKILLS_DIR="${WORDPRESS_AGENT_SKILLS_DIR:-/tmp/scry/skill_data/wordpress/agent_skills}"

bash "${SKILL_DIR}/scripts/prepare_agent_skills.sh" >/dev/null
cd "${REPO_ROOT}"
node "${AGENT_SKILLS_DIR}/skills/wp-project-triage/scripts/detect_wp_project.mjs"
