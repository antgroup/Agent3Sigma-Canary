#!/bin/bash
# Batch run: direct attack test (models × attacks × images, parallel)
#
# Usage:
#   ./batch_run/direct.sh              # Full direct suite
#   ./batch_run/direct.sh example      # 10 representative samples
#   MAX_PARALLEL=4 ./batch_run/direct.sh example

set +e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_lib.sh"
load_batch_config "$SCRIPT_DIR"
init_parallel

## Suite selection
SAMPLE_SUITE="task_23,task_25,task_53,task_56,task_58,task_62,task_65,task_74,task_79,task_92"

if [ "$1" = "example" ] || [ "$1" = "sample" ]; then
    SUITE_ARGS="--suite $SAMPLE_SUITE"
    RUN_TAG="example"
    echo ">>> Mode: sample (10 tasks)"
else
    SUITE_ARGS="--suite direct"
    RUN_TAG="full"
    echo ">>> Mode: full (all direct)"
fi

COMMON_ARGS="$SUITE_ARGS --runs 1 -v --docker ${EXTRA_COMMON_ARGS:-}"

## Attack methods (uncomment to enable)
ATTACKS=(
    ""                          # no-attack baseline
    # "code_attack"
    # "pair"
    # "encoding_obfuscation"
    # "separator_hijacking"
    # "overloading"
    # "payload_splitting"
    # "privilege_upgrade"
    # "role_play"
    # "translation_hijack"
)
ATTACK_NAMES=(
    "no_attack"
    # "code_attack"
    # "pair"
    # "encoding_obfuscation"
    # "separator_hijacking"
    # "overloading"
    # "payload_splitting"
    # "privilege_upgrade"
    # "role_play"
    # "translation_hijack"
)

## Run
LOG_DATE=$(date +"%m%d")
LOG_DIR="./log/${LOG_DATE}"
mkdir -p "$LOG_DIR"

echo "========== direct test [${RUN_TAG}] (parallel) =========="
echo "Images (${#DOCKER_IMAGES[@]}): ${DOCKER_IMAGE_NAMES[*]}"
echo "Models (${#MODELS[@]}): ${MODEL_NAMES[*]}"
echo "Attacks (${#ATTACKS[@]}): ${ATTACK_NAMES[*]}"
echo "Max parallel: $(parallel_limit_label)"
echo ""

for d in "${!DOCKER_IMAGES[@]}"; do
    DOCKER_IMG="${DOCKER_IMAGES[$d]}"
    DOCKER_TAG="${DOCKER_IMAGE_NAMES[$d]}"
    OUTPUT_DIR="results/${LOG_DATE}_${DOCKER_TAG}_direct_compare"

    echo "===== Image: ${DOCKER_TAG} (${DOCKER_IMG}) ====="

    for j in "${!ATTACKS[@]}"; do
        for i in "${!MODELS[@]}"; do
            if [ "$MAX_PARALLEL" -gt 0 ] && [ $RUNNING -ge "$MAX_PARALLEL" ]; then
                wait_one
            fi
            TAG="${DOCKER_TAG}_${RUN_TAG}_${MODEL_NAMES[$i]}_${ATTACK_NAMES[$j]}"
            LOG_FILE="$LOG_DIR/${DOCKER_TAG}_direct_${RUN_TAG}_${MODEL_NAMES[$i]}_${ATTACK_NAMES[$j]}.log"
            ATTACK_FLAG=""
            [ -n "${ATTACKS[$j]}" ] && ATTACK_FLAG="--attack ${ATTACKS[$j]}"
            launch_task "$TAG" "$LOG_FILE" "$DOCKER_IMG" "./scripts/run.sh ${MODELS[$i]} $COMMON_ARGS --output-dir $OUTPUT_DIR $ATTACK_FLAG"
        done
    done
done

wait_all
