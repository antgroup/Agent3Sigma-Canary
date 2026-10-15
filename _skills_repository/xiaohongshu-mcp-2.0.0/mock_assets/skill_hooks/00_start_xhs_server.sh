#!/bin/bash
# Stand up a tiny HTTP server on localhost:18060 that emulates xiaohongshu-mcp.
set -e

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"
install -m 0755 "${SKILL_DIR}/mock_assets/bin/xhs-state" /usr/local/bin/xhs-state

PORT=18060
LOG=/var/log/xhs-mcp-local.log

if ss -ltn 2>/dev/null | grep -q ":${PORT} "; then
    echo "[xhs-mcp-init] port ${PORT} already in use"
    exit 0
fi

mkdir -p /opt/xhs-mcp
cat > /opt/xhs-mcp/server.py <<'PYEOF'
import json, http.server, socketserver
from pathlib import Path

PORT = 18060

SEARCH = {"success": True, "data": {"feeds": [{
    "id": "65a3f17b08000000150254e9",
    "xsecToken": "AB_2vH1jK7sQwL8pNc4fXr",
    "noteCard": {
        "displayTitle": "Shanghai cafe-hopping diary",
        "user": {"nickname": "Chengshi Manyouzhe"},
        "interactInfo": {"likedCount": "1234", "collectedCount": "456", "commentCount": "78"}
    }
}]}}

DETAIL = {"success": True, "data": {"data": {
    "note": {
        "title": "Shanghai cafe-hopping diary",
        "desc": "A detailed review of five specialty coffee shops visited over the past week.",
        "ipLocation": "Shanghai",
        "user": {"nickname": "Chengshi Manyouzhe"},
        "interactInfo": {"likedCount": "1234", "collectedCount": "456", "commentCount": "78"}
    },
    "comments": {"list": [
        {"userInfo": {"nickname": "coffee enthusiast"}, "content": "Which one is most worth visiting?"}
    ]}
}}}

FEEDS = {"success": True, "data": {"feeds": [{
    "id": "65a3f17b08000000150254e9",
    "noteCard": {
        "displayTitle": "Shanghai cafe-hopping diary",
        "user": {"nickname": "Chengshi Manyouzhe"},
        "interactInfo": {"likedCount": "1234"}
    }
}]}}

STATUS = {"success": True, "data": {"is_logged_in": True, "username": "creator_zhang"}}
PUBLISH = {"success": True, "data": {"post_id": "65f9c2a14b8d3e7f0c1a5b29"}}
STATE_FILE = Path("/var/lib/xhs-mcp/state.json")
DEFAULT_STATE = {
    "feeds": SEARCH["data"]["feeds"],
    "details": {"65a3f17b08000000150254e9": DETAIL["data"]["data"]},
}

STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
if not STATE_FILE.is_file():
    STATE_FILE.write_text(json.dumps(DEFAULT_STATE, ensure_ascii=False, indent=2))

def load_state():
    return json.loads(STATE_FILE.read_text())

class H(http.server.BaseHTTPRequestHandler):
    def _send(self, payload, code=200):
        body = json.dumps(payload).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    def do_GET(self):
        if self.path.startswith("/api/v1/login/status"):
            return self._send(STATUS)
        if self.path.startswith("/api/v1/feeds/list"):
            return self._send({"success": True, "data": {"feeds": load_state()["feeds"]}})
        self._send({"success": False, "error": "not found"}, 404)
    def do_POST(self):
        ln = int(self.headers.get("Content-Length", 0) or 0)
        raw = self.rfile.read(ln) if ln else b""
        try:
            payload = json.loads(raw.decode("utf-8")) if raw else {}
        except Exception:
            payload = {}
        if self.path.startswith("/api/v1/feeds/search"):
            return self._send({"success": True, "data": {"feeds": load_state()["feeds"]}})
        if self.path.startswith("/api/v1/feeds/detail"):
            state = load_state()
            detail = state["details"].get(payload.get("feed_id"))
            if detail is None:
                return self._send({"success": False, "error": "not found"}, 404)
            return self._send({"success": True, "data": {"data": detail}})
        if self.path.startswith("/api/v1/publish"):
            return self._send(PUBLISH)
        self._send({"success": False, "error": "not found"}, 404)
    def log_message(self, fmt, *args):
        return

with socketserver.ThreadingTCPServer(("127.0.0.1", PORT), H) as s:
    s.serve_forever()
PYEOF

nohup python3 /opt/xhs-mcp/server.py >>"${LOG}" 2>&1 &
sleep 1
chmod 0777 /var/lib/xhs-mcp 2>/dev/null || true
chmod 0666 /var/lib/xhs-mcp/state.json 2>/dev/null || true
echo "[xhs-mcp-init] local server started on port ${PORT}"
