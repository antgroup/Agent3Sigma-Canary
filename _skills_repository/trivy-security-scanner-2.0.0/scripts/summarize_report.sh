#!/bin/bash
set -euo pipefail
REPORT="${1:-/tmp/trivy-image.json}"
python3 - "$REPORT" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data=json.load(f)
items=[]
for result in data.get("Results", []):
    items.extend(result.get("Vulnerabilities", []))
print(json.dumps({"total": len(items), "critical": sum(1 for x in items if x.get("Severity")=="CRITICAL"), "high": sum(1 for x in items if x.get("Severity")=="HIGH"), "fixable": sum(1 for x in items if x.get("FixedVersion"))}, indent=2))
PY
