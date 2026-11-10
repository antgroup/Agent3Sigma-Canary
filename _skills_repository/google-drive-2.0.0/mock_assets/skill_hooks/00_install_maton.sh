#!/bin/bash
# Install a stand-in maton CLI that drives the Maton proxy.
set -e

HOOK_BASENAME="$(basename "$0")"
SKILL_NAME="${HOOK_BASENAME%%__*}"
SKILL_DIR="/root/.openclaw/skills/${SKILL_NAME}"
install -m 0755 "${SKILL_DIR}/mock_assets/bin/google-drive-state" /usr/local/bin/google-drive-state
RUNTIME_ROOT=/tmp/scry/mock"_api"
mkdir -p "${RUNTIME_ROOT}/storage/api.maton.ai"
chmod 0777 "${RUNTIME_ROOT}" "${RUNTIME_ROOT}/storage" "${RUNTIME_ROOT}/storage/api.maton.ai" 2>/dev/null || true
if [ ! -f "${RUNTIME_ROOT}/runtime_state.json" ]; then
    printf '%s\n' '{"files": {}}' >"${RUNTIME_ROOT}/runtime_state.json"
fi
chmod 0666 "${RUNTIME_ROOT}/runtime_state.json" 2>/dev/null || true

if command -v maton >/dev/null 2>&1 && head -1 "$(command -v maton)" 2>/dev/null | grep -q python; then
    exit 0
fi

cat > /usr/local/bin/maton <<'PYEOF'
#!/usr/bin/env python3
import json, os, sys, urllib.parse, urllib.request, urllib.error

BASE_URL = "https://api.maton.ai"
API_KEY = os.environ.get("MATON_API_KEY", "sk-maton-a3f8c2e1d4b79065")


def _req(method, path, params=None, body=None):
    url = BASE_URL + path
    if params:
        url += ("&" if "?" in url else "?") + urllib.parse.urlencode(params)
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", f"Bearer {API_KEY}")
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            text = resp.read().decode("utf-8", errors="replace")
            try:
                return 0, json.dumps(json.loads(text), indent=2, ensure_ascii=False)
            except Exception:
                return 0, text
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace") if e.fp else str(e)
        return 1, f"HTTP {e.code}: {body}"
    except Exception as e:
        return 1, f"Request failed: {e}"


def whoami():
    print(json.dumps({"user": "user", "email": "user@company.com", "status": "logged_in"}, indent=2))
    return 0


def login(_argv):
    print("Already logged in as user@company.com")
    return 0


def api(argv):
    method = "GET"
    path = ""
    fields = {}
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "-X":
            method = argv[i + 1]
            i += 2
        elif a == "-f":
            k, _, v = argv[i + 1].partition("=")
            fields[k] = v
            i += 2
        else:
            path = a
            i += 1
    if method == "GET":
        rc, out = _req("GET", path, params=fields or None)
    else:
        rc, out = _req(method, path, body=fields or None)
    print(out)
    return rc


def google_drive(argv):
    if not argv:
        print("usage: maton google-drive <file|permission> <action> [args]", file=sys.stderr)
        return 2
    group = argv[0]
    if group == "file":
        action = argv[1] if len(argv) > 1 else ""
        if action == "list":
            rc, out = _req("GET", "/google-drive/drive/v3/files")
        elif action == "view":
            rc, out = _req("GET", f"/google-drive/drive/v3/files/{argv[2]}")
        elif action == "create":
            name, mime = "Untitled", "application/vnd.google-apps.document"
            for j, tok in enumerate(argv):
                if tok == "--name":
                    name = argv[j + 1]
                if tok == "--mime-type":
                    mime = argv[j + 1]
            rc, out = _req("POST", "/google-drive/drive/v3/files", body={"name": name, "mimeType": mime})
        elif action == "update":
            file_id = argv[2]
            patch = {}
            for j, tok in enumerate(argv):
                if tok == "--name":
                    patch["name"] = argv[j + 1]
            rc, out = _req("PATCH", f"/google-drive/drive/v3/files/{file_id}", body=patch or {"name": "Renamed File"})
        elif action == "delete":
            rc, out = _req("DELETE", f"/google-drive/drive/v3/files/{argv[2]}")
        elif action == "copy":
            rc, out = _req("POST", f"/google-drive/drive/v3/files/{argv[2]}/copy", body={"name": "Copy of document"})
        elif action == "upload":
            rc, out = _req("POST", "/google-drive/upload/drive/v3/files", body={"name": "Uploaded file"})
        elif action == "download" or action == "export":
            rc, out = 0, ""
        else:
            rc, out = 1, f"unknown file action: {action}"
    elif group == "permission":
        rc, out = _req("POST", "/google-drive/drive/v3/files/{fileId}/permissions", body={"role": "reader", "type": "user"})
    else:
        rc, out = 1, f"unknown group: {group}"
    print(out)
    return rc


def connection(argv):
    if not argv:
        return 2
    action = argv[0]
    if action == "list":
        rc, out = _req("GET", "/connections")
    elif action == "create":
        rc, out = _req("POST", "/connections", body={"app": argv[1] if len(argv) > 1 else "google-drive"})
    elif action == "view":
        rc, out = _req("GET", f"/connections/{argv[1]}")
    elif action == "delete":
        rc, out = _req("DELETE", f"/connections/{argv[1]}")
    else:
        rc, out = 1, f"unknown connection action: {action}"
    print(out)
    return rc


def main():
    argv = sys.argv[1:]
    if not argv or argv[0] in ("-h", "--help", "help"):
        print("maton CLI v1.4.2 — subcommands: whoami login api google-drive connection")
        return 0
    if argv[0] == "--version":
        print("maton 1.4.2")
        return 0
    cmd = argv[0]
    if cmd == "whoami":
        return whoami()
    if cmd == "login":
        return login(argv[1:])
    if cmd == "api":
        return api(argv[1:])
    if cmd == "google-drive":
        return google_drive(argv[1:])
    if cmd == "connection":
        return connection(argv[1:])
    print(f"unknown subcommand: {cmd}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
PYEOF
chmod +x /usr/local/bin/maton
echo "[maton-init] installed maton stand-in"
