#!/bin/bash
# Batch run: skills poison test (models × images, parallel, no attack methods)
#
# Usage:
#   ./batch_run/skills_poison.sh              # Full skills_poison_EN suite
#   ./batch_run/skills_poison.sh example      # 10 representative samples
#   MAX_PARALLEL=4 ./batch_run/skills_poison.sh example

set +e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_lib.sh"
load_batch_config "$SCRIPT_DIR"
init_parallel

## Suite selection
SAMPLE_SUITE="task_5001,task_5007,task_5015,task_5020,task_5027,task_5033,task_5038,task_5042,task_5046,task_5050"

if [ "$1" = "example" ] || [ "$1" = "sample" ]; then
    SUITE_ARGS="--suite $SAMPLE_SUITE"
    RUN_TAG="example"
    echo ">>> Mode: sample (10 tasks)"
else
    SUITE_ARGS="--suite task_5000-5099"
    RUN_TAG="full"
    echo ">>> Mode: task_5000-5099"
fi

COMMON_ARGS="$SUITE_ARGS --runs 1 -v --docker"

## Run
LOG_DATE=$(date +"%m%d")
LOG_DIR="./log/${LOG_DATE}"
mkdir -p "$LOG_DIR"

echo "========== skills_poison test [${RUN_TAG}] (parallel) =========="
echo "Images (${#DOCKER_IMAGES[@]}): ${DOCKER_IMAGE_NAMES[*]}"
echo "Models (${#MODELS[@]}): ${MODEL_NAMES[*]}"
echo "Max parallel: ${MAX_PARALLEL:-unlimited}"
echo ""

for d in "${!DOCKER_IMAGES[@]}"; do
    DOCKER_IMG="${DOCKER_IMAGES[$d]}"
    DOCKER_TAG="${DOCKER_IMAGE_NAMES[$d]}"
    OUTPUT_DIR="results/${LOG_DATE}_${DOCKER_TAG}_skills_poison_compare"

    echo "===== Image: ${DOCKER_TAG} (${DOCKER_IMG}) ====="

    for i in "${!MODELS[@]}"; do
        if [ "$MAX_PARALLEL" -gt 0 ] && [ $RUNNING -ge "$MAX_PARALLEL" ]; then
            wait_one
        fi
        TAG="${DOCKER_TAG}_${RUN_TAG}_${MODEL_NAMES[$i]}"
        LOG_FILE="$LOG_DIR/${TAG}.log"
        launch_task "$TAG" "$LOG_FILE" "$DOCKER_IMG" "./scripts/run.sh ${MODELS[$i]} $COMMON_ARGS --output-dir $OUTPUT_DIR"
    done
done

wait_all
