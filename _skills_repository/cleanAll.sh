#!/bin/bash

# cleanAll.sh - Clean all generated skill binaries and the skill_dest directory
# Usage: ./cleanAll.sh

set -e

# Get the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_REPO_DIR="${SCRIPT_DIR}"

# skill_dest directory
SKILL_DEST="${SKILLS_REPO_DIR}/../_skills_repository/skill_dest"

echo "=========================================="
echo "Starting cleanup..."
echo "Source directory: ${SKILLS_REPO_DIR}"
echo "=========================================="

# 1. Clean binary files in each skill directory (_mac and _linux)
echo ""
echo "Cleaning skill binaries..."
binary_count=0
for skill_dir in "${SKILLS_REPO_DIR}"/*/; do
    if [[ ! -d "${skill_dir}" ]]; then
        continue
    fi

    skill_name=$(basename "${skill_dir}")

    # Skip non-skill directories
    if [[ "${skill_name}" == "__pycache__" ]] || [[ "${skill_name}" == .* ]]; then
        continue
    fi

    # Find and remove executables prefixed by the skill name and ending in _mac or _linux
    for binary in "${skill_dir}"*_mac "${skill_dir}"*_linux; do
        if [[ -f "${binary}" ]]; then
            rm -f "${binary}"
            echo "  Removed: ${skill_name}/$(basename "${binary}")"
            binary_count=$((binary_count + 1))
        fi
    done
done

echo "  Removed ${binary_count} binaries"

# 2. Clean skill_dest directory
echo ""
echo "Cleaning skill_dest directory..."
if [[ -d "${SKILL_DEST}" ]]; then
    rm -rf "${SKILL_DEST}"
    echo "  Removed: ${SKILL_DEST}"
else
    echo "  Directory not found, skipping: ${SKILL_DEST}"
fi

# 3. Clean build directories and .spec files if present
echo ""
echo "Cleaning build directories and .spec files..."
spec_count=0
shopt -s nullglob
for spec_file in "${SKILLS_REPO_DIR}"/*/*.spec; do
    if [[ -f "${spec_file}" ]]; then
        rm -f "${spec_file}"
        echo "  Removed: $(basename "${spec_file}")"
        spec_count=$((spec_count + 1))
    fi
done

for build_dir in "${SKILLS_REPO_DIR}"/*/build; do
    if [[ -d "${build_dir}" ]]; then
        rm -rf "${build_dir}"
        echo "  Removed: $(basename "$(dirname "${build_dir}")")/build"
        spec_count=$((spec_count + 1))
    fi
done
shopt -u nullglob

echo "  Removed ${spec_count} build/spec files"

echo ""
echo "=========================================="
echo "Cleanup complete!"
echo "=========================================="
