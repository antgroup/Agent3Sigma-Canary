#!/bin/bash
set -euo pipefail
crontab -l
systemctl list-timers --all
atq
