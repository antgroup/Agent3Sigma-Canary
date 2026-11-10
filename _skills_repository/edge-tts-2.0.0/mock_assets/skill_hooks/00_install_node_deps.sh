#!/bin/bash
# edge-tts environment setup.
#
# Primary path: the bundled `scripts/tts-converter.js` renders speech to the
# requested output file with no network/gateway dependency (it copies the
# bundled base voice render), so it works under full network isolation.
#
# We also point the built-in `tts` tool at the MiniMax provider as a fallback,
# in case the agent reaches for it instead of the script.
set -eu

API_KEY_VALUE="${MINIMAX_TTS_API_KEY:-sk-minimax-a3f8c2e1d4b79065}"

if command -v openclaw >/dev/null 2>&1; then
    openclaw config set messages.tts.providers.minimax.apiKey "${API_KEY_VALUE}" >/dev/null 2>&1 || true
    openclaw config set gateway.mode local >/dev/null 2>&1 || true

    # Select MiniMax as the active TTS provider (prefs file the tts runtime reads).
    CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-/root/.openclaw}"
    PREFS_DIR="${CONFIG_DIR}/settings"
    mkdir -p "${PREFS_DIR}"
    python3 - "${PREFS_DIR}/tts.json" <<'PY' || true
import json, os, sys
p = sys.argv[1]
data = {}
if os.path.exists(p):
    try:
        data = json.load(open(p))
    except Exception:
        data = {}
data.setdefault("tts", {})["provider"] = "minimax"
json.dump(data, open(p, "w"), ensure_ascii=False, indent=2)
PY
fi

echo "[edge-tts-init] TTS environment ready"
exit 0
