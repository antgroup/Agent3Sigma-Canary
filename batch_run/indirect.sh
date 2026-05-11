#!/bin/bash
# Batch run: indirect injection test (models × attacks × context modes × images, parallel)
#
# Usage:
#   ./batch_run/indirect.sh              # Full indirect suite
#   ./batch_run/indirect.sh sample       # 20 representative samples
#   MAX_PARALLEL=4 ./batch_run/indirect.sh sample

set +e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_lib.sh"
load_batch_config "$SCRIPT_DIR"
init_parallel

## Suite selection
SAMPLE_SUITE="task_10001,task_10025,task_10052,task_10078,task_10097,task_10124,task_10148,task_10184,task_10215,task_10236,task_10252,task_10313,task_10329,task_10346,task_10380,task_10467,task_10500,task_10534,task_10550,task_10551"

if [ "$1" = "sample" ]; then
    SUITE_ARGS="--suite $SAMPLE_SUITE"
    RUN_TAG="sample"
    echo ">>> Mode: sample (20 tasks)"
else
    SUITE_ARGS="--suite indirect"
    RUN_TAG="full"
    echo ">>> Mode: full (all indirect)"
fi

COMMON_ARGS="$SUITE_ARGS --runs 1 -v --docker"

## Attack methods and context modes
ATTACKS=("important_message")
ATTACK_NAMES=("important_message")
NO_CONTEXT_FLAGS=("--no-context")
NO_CONTEXT_NAMES=("no_context")

## Run
LOG_DATE=$(date +"%m%d")
LOG_DIR="./log/${LOG_DATE}"
mkdir -p "$LOG_DIR"

echo "========== indirect test [${RUN_TAG}] (parallel) =========="
echo "Images (${#DOCKER_IMAGES[@]}): ${DOCKER_IMAGE_NAMES[*]}"
echo "Models (${#MODELS[@]}): ${MODEL_NAMES[*]}"
echo "Attacks: ${ATTACK_NAMES[*]}"
echo "Context modes: ${NO_CONTEXT_NAMES[*]}"
echo "Max parallel: ${MAX_PARALLEL:-unlimited}"
echo ""

for d in "${!DOCKER_IMAGES[@]}"; do
    DOCKER_IMG="${DOCKER_IMAGES[$d]}"
    DOCKER_TAG="${DOCKER_IMAGE_NAMES[$d]}"
    OUTPUT_DIR="results/${LOG_DATE}_${DOCKER_TAG}_indirect_compare"

    echo "===== Image: ${DOCKER_TAG} (${DOCKER_IMG}) ====="

    for j in "${!ATTACKS[@]}"; do
        for c in "${!NO_CONTEXT_FLAGS[@]}"; do
            for i in "${!MODELS[@]}"; do
                if [ "$MAX_PARALLEL" -gt 0 ] && [ $RUNNING -ge "$MAX_PARALLEL" ]; then
                    wait_one
                fi
                TAG="${DOCKER_TAG}_${RUN_TAG}_${MODEL_NAMES[$i]}_${ATTACK_NAMES[$j]}_${NO_CONTEXT_NAMES[$c]}"
                LOG_FILE="$LOG_DIR/${TAG}.log"
                launch_task "$TAG" "$LOG_FILE" "$DOCKER_IMG" "./scripts/run.sh ${MODELS[$i]} $COMMON_ARGS --output-dir $OUTPUT_DIR --attack '${ATTACKS[$j]}' ${NO_CONTEXT_FLAGS[$c]}"
            done
        done
    done
done

wait_all
