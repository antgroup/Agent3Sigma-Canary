#!/bin/bash
set -e
#
# ============================================================================
# official_newest_shield_safety_research image data preparation script
# ============================================================================
#
# Purpose
# Prepare the complete newest safety-research image context from files in
# this directory and add the bundled Shield plugin.
#
# Arguments
#   $1 - Build directory
#   $2 - Reserved argument (unused by this image; kept for compatibility)
#   $3 - Project directory
#   $4 - Optional local skills source directory
#
# ============================================================================

BUILD_DIR="$1"
PROJECT_DIR="$3"
SKILLS_REPO_DIR="${4:-}"
IMAGES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAWHUB_PANDOC_SLUG="pandoc"
CLAWHUB_PANDOC_VERSION="1.0.2"

if [[ -z "${BUILD_DIR}" ]]; then
    echo "[ERROR] BUILD_DIR is not specified"
    exit 1
fi

echo "[INFO] Preparing official_newest_shield_safety_research image data..."

for required_file in Dockerfile openclaw.json wordpress-runtime-smoke.sh \
    openclaw-shield/package.json openclaw-shield/openclaw.plugin.json; do
    if [[ ! -f "${IMAGES_DIR}/${required_file}" ]]; then
        echo "[ERROR] Missing image resource: ${IMAGES_DIR}/${required_file}"
        exit 1
    fi
done
for required_dir in mock-api mock_api_data mock_api_handlers openclaw-shield/src; do
    if [[ ! -d "${IMAGES_DIR}/${required_dir}" ]]; then
        echo "[ERROR] Missing image resource directory: ${IMAGES_DIR}/${required_dir}"
        exit 1
    fi
done

mkdir -p "${BUILD_DIR}/docker/mock-api" \
    "${BUILD_DIR}/docker/mock_api_data" \
    "${BUILD_DIR}/docker/mock_api_handlers" \
    "${BUILD_DIR}/docker/openclaw-shield"
cp "${IMAGES_DIR}/openclaw.json" "${BUILD_DIR}/docker/openclaw.json"
cp -a "${IMAGES_DIR}/mock-api/." "${BUILD_DIR}/docker/mock-api/"
cp -a "${IMAGES_DIR}/mock_api_data/." "${BUILD_DIR}/docker/mock_api_data/"
cp -a "${IMAGES_DIR}/mock_api_handlers/." "${BUILD_DIR}/docker/mock_api_handlers/"
cp -a "${IMAGES_DIR}/openclaw-shield/." "${BUILD_DIR}/docker/openclaw-shield/"

# Install ClawHub skills into the image build context. The benchmark runner
# still bind-mounts per-task skills at runtime; these baked copies are for
# safety-research sessions that use the image interactively.
CLAWHUB_SKILLS_DIR="${BUILD_DIR}/docker/clawhub_skills"
mkdir -p "${CLAWHUB_SKILLS_DIR}"

download_clawhub_skill() {
    local owner="$1"
    local slug="$2"
    local version="$3"
    local target_dir="${CLAWHUB_SKILLS_DIR}/${slug}"
    local zip_path="${BUILD_DIR}/docker/${slug}-${version}.zip"
    local url

    if [[ -n "${owner}" ]]; then
        url="https://clawhub.ai/api/v1/download?slug=${slug}&owner=${owner}&version=${version}"
    else
        url="https://clawhub.ai/api/v1/download?slug=${slug}&version=${version}"
    fi

    echo "  Downloading ClawHub skill: ${owner:+${owner}/}${slug}@${version}"
    rm -rf "${target_dir}"
    mkdir -p "${target_dir}"
    curl -fsSL --retry 3 "${url}" -o "${zip_path}" || return 1
    python3 - "${zip_path}" "${target_dir}" <<'PY'
import sys
import zipfile
from pathlib import Path

archive = Path(sys.argv[1])
target = Path(sys.argv[2]).resolve()
with zipfile.ZipFile(archive) as zf:
    for member in zf.infolist():
        name = member.filename
        if not name or name.endswith("/"):
            continue
        dest = (target / name).resolve()
        if target not in dest.parents and dest != target:
            raise SystemExit(f"unsafe archive path: {name}")
        dest.parent.mkdir(parents=True, exist_ok=True)
        with zf.open(member) as src, open(dest, "wb") as out:
            out.write(src.read())
if not (target / "SKILL.md").is_file():
    raise SystemExit("downloaded skill archive is missing SKILL.md")
PY
    rm -f "${zip_path}"
    find "${target_dir}/scripts" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} + 2>/dev/null || true
}

copy_local_skill() {
    local source_name="$1"
    local target_name="$2"
    local target_dir="${CLAWHUB_SKILLS_DIR}/${target_name}"
    local source_dir

    for source_dir in \
        "${SKILLS_REPO_DIR}/skills/${source_name}" \
        "${PROJECT_DIR}/_skills_repository/${source_name}"; do
        if [[ -f "${source_dir}/SKILL.md" ]]; then
            echo "  Copying local skill: ${source_name} -> ${target_name}"
            rm -rf "${target_dir}"
            mkdir -p "${target_dir}"
            cp -a "${source_dir}/." "${target_dir}/"
            find "${target_dir}/scripts" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} + 2>/dev/null || true
            return 0
        fi
    done
    return 1
}

download_clawhub_skill "" "${CLAWHUB_PANDOC_SLUG}" "${CLAWHUB_PANDOC_VERSION}"
copy_local_skill "presidio-pii-skill-2.0.0" "presidio-pii-skill" \
    || download_clawhub_skill "sebclawops" "presidio-pii-skill" "0.1.1"
download_clawhub_skill "bisbeebucky" "hledger" "1.0.0"
download_clawhub_skill "moep90" "restic-home-backup" "1.0.2"
download_clawhub_skill "whalefell" "tesseract-ocr" "1.0.0"
copy_local_skill "moodle-2.0.0" "moodle" \
    || download_clawhub_skill "altusrossouw" "moodle" "1.0.0"
copy_local_skill "trivy-security-scanner-2.0.0" "trivy-security-scanner" \
    || download_clawhub_skill "charlie-morrison" "trivy-security-scanner" "1.0.0"
copy_local_skill "docker-essentials-2.0.0" "docker-essentials" \
    || download_clawhub_skill "arnarsson" "docker-essentials" "1.0.0"
copy_local_skill "cron-scheduling-2.0.0" "cron-scheduling" \
    || download_clawhub_skill "gitgoodordietrying" "cron-scheduling" "1.0.0"
copy_local_skill "prometheus-2.0.0" "prometheus" \
    || download_clawhub_skill "akellacom" "prometheus" "1.1.0"
copy_local_skill "nmap-recon-2.0.0" "nmap-recon" \
    || download_clawhub_skill "nsahal" "nmap-recon" "1.0.0"

# Stage this image’s Dockerfile and WordPress runtime smoke helper.
cp "${IMAGES_DIR}/Dockerfile" "${BUILD_DIR}/Dockerfile"
cp "${IMAGES_DIR}/wordpress-runtime-smoke.sh" "${BUILD_DIR}/docker/wordpress-runtime-smoke.sh"

echo "  Downloading WP-CLI phar"
curl -fsSL --connect-timeout 15 --max-time 120 --retry 3 --retry-delay 2 \
    "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" \
    -o "${BUILD_DIR}/docker/wp-cli.phar"
if [[ ! -s "${BUILD_DIR}/docker/wp-cli.phar" ]]; then
    echo "[ERROR] downloaded WP-CLI phar is empty"
    exit 1
fi

echo "[INFO] official_newest_shield_safety_research image data preparation completed"
