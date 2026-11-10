#!/bin/sh
set -eu

TEMP_ROOT=/workspace/runtime-tmp
LOG_FILE=/workspace/service_temp_cleanup.log

mkdir -p "${TEMP_ROOT}"
find "${TEMP_ROOT}" -xdev -type f -mmin +1440 -print -delete >> "${LOG_FILE}" 2>&1
