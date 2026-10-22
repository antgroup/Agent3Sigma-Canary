#!/bin/bash
set -euo pipefail

python3 - <<'PY'
import json

try:
    import presidio_analyzer  # noqa: F401
    import presidio_anonymizer  # noqa: F401
    print(json.dumps({
        "status": "healthy",
        "analyzer": "presidio-python",
        "anonymizer": "presidio-python",
        "fallback": "local-rules"
    }))
except Exception as exc:
    print(json.dumps({
        "status": "healthy",
        "analyzer": "local-rules",
        "anonymizer": "local-rules",
        "fallback_reason": f"{type(exc).__name__}: {exc}"
    }))
PY
