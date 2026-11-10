#!/bin/sh
set -eu
python3 -c 'import json; d=json.load(open("/workspace/report_input.json")); print("%s | blockers=%s | variance=%s" % (d["portfolio"], d["blockers"], d["cost_variance"]))' > /workspace/executive_report_latest.txt
