#!/bin/bash
# Batch run: safety test (models × images, parallel, no attacker)
#
# Usage:
#   ./batch_run/safety.sh              # Full safety suite (41 tasks)
#   ./batch_run/safety.sh example      # 8 representative samples
#   MAX_PARALLEL=4 ./batch_run/safety.sh example

set +e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_lib.sh"
load_batch_config "$SCRIPT_DIR"
init_parallel

## Suite selection
# Sample covers one task per failure-cause/scenario family for quick smoke runs.
SAMPLE_SUITE="task_40001,task_40002,task_40008,task_40010,task_40037,task_40040,task_40048,task_40051"

if [ "$1" = "example" ] || [ "$1" = "sample" ]; then
    SUITE_ARGS="--suite $SAMPLE_SUITE"
    RUN_TAG="example"
    echo ">>> Mode: sample (8 tasks)"
else
    SUITE_ARGS="--suite safety"
    RUN_TAG="full"
    echo ">>> Mode: full (all safety, 41 tasks)"
fi

COMMON_ARGS="$SUITE_ARGS --runs 1 -v --docker ${EXTRA_COMMON_ARGS:-}"

## Run
LOG_DATE=$(date +"%m%d")
LOG_DIR="./log/${LOG_DATE}"
mkdir -p "$LOG_DIR"

echo "========== safety test [${RUN_TAG}] (parallel) =========="
echo "Images (${#DOCKER_IMAGES[@]}): ${DOCKER_IMAGE_NAMES[*]}"
echo "Models (${#MODELS[@]}): ${MODEL_NAMES[*]}"
echo "Max parallel: $(parallel_limit_label)"
echo ""

for d in "${!DOCKER_IMAGES[@]}"; do
    DOCKER_IMG="${DOCKER_IMAGES[$d]}"
    DOCKER_TAG="${DOCKER_IMAGE_NAMES[$d]}"
    OUTPUT_DIR="results/${LOG_DATE}_${DOCKER_TAG}_safety_compare"

    echo "===== Image: ${DOCKER_TAG} (${DOCKER_IMG}) ====="

    for i in "${!MODELS[@]}"; do
        if [ "$MAX_PARALLEL" -gt 0 ] && [ $RUNNING -ge "$MAX_PARALLEL" ]; then
            wait_one
        fi
        TAG="${DOCKER_TAG}_${RUN_TAG}_${MODEL_NAMES[$i]}"
        LOG_FILE="$LOG_DIR/${DOCKER_TAG}_safety_${RUN_TAG}_${MODEL_NAMES[$i]}.log"
        launch_task "$TAG" "$LOG_FILE" "$DOCKER_IMG" "./scripts/run.sh ${MODELS[$i]} $COMMON_ARGS --output-dir $OUTPUT_DIR"
    done
done

wait_all
