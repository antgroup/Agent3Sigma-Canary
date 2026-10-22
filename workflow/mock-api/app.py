#!/usr/bin/env python3
"""
Mock API Server with transparent API proxy support.

Serves two roles:
1. Static file server from data directory (original behavior)
2. API mock proxy — routes requests by Host header to skill-specific
   mock handlers, enabling transparent DNS-level interception of real
   API domains (e.g., api.maton.ai → 127.0.0.1:80).

When a request arrives with a Host header matching a registered skill
domain, the server dispatches it to the corresponding mock handler
loaded from /tmp/scry/mock_api/api_handlers/<domain>.json.

This means the agent's skill binary (unchanged from real version) makes
HTTPS requests to api.maton.ai, but DNS/iptables redirects the traffic
to this local mock server, which responds with fixture data.
"""

import glob
import json
import os
import re
import time
from pathlib import Path
from typing import Any
from flask import Flask, Response, request, jsonify

app = Flask(__name__)

# Global config
config = {}

# ---------------------------------------------------------------------------
# API mock handler registry
# ---------------------------------------------------------------------------
# Maps (domain, path_prefix) → handler config loaded from JSON files.
# Each handler config has:
#   - domain: e.g. "api.maton.ai"
#   - path_prefix: e.g. "/google-drive"  (can be empty for root)
#   - routes: list of {method, path, response, status_code}
#   - fixtures: dict of fixture data for dynamic responses
_api_handlers: dict[str, dict] = {}  # domain → handler config
_audit_log: list[dict] = []          # audit trail of all API calls

def _not_found_response() -> tuple:
    """Return a neutral 404 without exposing mock implementation details."""
    return jsonify({"error": "Not Found"}), 404


def _internal_error_response() -> tuple:
    """Return a neutral 500 without exposing storage or filesystem details."""
    return jsonify({"error": "Internal Server Error"}), 500


@app.errorhandler(500)
def handle_internal_server_error(_error):
    """Sanitize unexpected Flask failures as well as explicit storage errors."""
    return _internal_error_response()


import uuid
import mimetypes as _mimetypes

# Runtime file registry: domain → list of file records created by uploads.
# These are merged into $fixture.files_list on GET /...files (list) and used to
# resolve a fileId → stored filename for downloads, so uploaded files actually
# appear in listings and can be downloaded back. Persisted to a sidecar JSON so
# __reload_handlers does not lose them.
_runtime_files: dict[str, list[dict]] = {}
_RUNTIME_STATE_PATH = Path("/tmp/scry/mock_api/runtime_state.json")

def load_api_handlers():
    """Load API mock handlers from /tmp/scry/mock_api/api_handlers/."""
    global _api_handlers
    _api_handlers = {}
    handlers_dir = Path("/tmp/scry/mock_api/api_handlers")
    load_runtime_state()
    if not handlers_dir.exists():
        return

    for handler_file in handlers_dir.glob("*.json"):
        try:
            with open(handler_file, "r", encoding="utf-8") as f:
                handler_config = json.load(f)
            domain = handler_config.get("domain", "")
            if domain:
                _api_handlers[domain] = handler_config
                print(f"  [API Mock] Loaded handler for {domain} from {handler_file.name}")
        except Exception as e:
            print(f"  [API Mock] Error loading {handler_file.name}: {e}")

    if _api_handlers:
        print(f"  [API Mock] {len(_api_handlers)} domain handler(s) loaded")
        for domain in _api_handlers:
            routes = _api_handlers[domain].get("routes", [])
            print(f"    {domain}: {len(routes)} route(s)")


def load_runtime_state():
    """Load persisted runtime state (file registry) from sidecar."""
    global _runtime_files
    _runtime_files = {}
    try:
        if _RUNTIME_STATE_PATH.is_file():
            data = json.loads(_RUNTIME_STATE_PATH.read_text(encoding="utf-8"))
            if isinstance(data, dict):
                _runtime_files = data.get("files", {})
    except Exception as e:
        print(f"  [API Mock] Error loading runtime state: {e}")


def save_runtime_state():
    """Persist runtime state (file registry) to the sidecar."""
    try:
        _RUNTIME_STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
        _RUNTIME_STATE_PATH.write_text(json.dumps({
            "files": _runtime_files,
        }, ensure_ascii=False, indent=2), encoding="utf-8")
    except Exception as e:
        print(f"  [API Mock] Error saving runtime state: {e}")


def _safe_seg(name: str) -> str:
    """Make a domain/collection name safe to use as a single path segment."""
    return re.sub(r"[^A-Za-z0-9._-]", "_", str(name))


def _storage_dir_for(handler: dict) -> Path:
    """Per-domain storage directory: STORAGE_DIR/<safe-domain>/.

    Files are sharded by domain so two skills uploading the same filename do
    not collide (mirroring Type B's per-skill data dir).
    """
    d = STORAGE_DIR / _safe_seg(_domain_of(handler) or "_default")
    d.mkdir(parents=True, exist_ok=True)
    return d


def _domain_of(handler: dict) -> str:
    return handler.get("domain", "")


def _path_param(path: str, pattern: str) -> dict:
    """Return {param: value} extracted from path against a {param} pattern."""
    if path == pattern:
        return {}
    out: dict[str, str] = {}
    ps = path.strip("/").split("/")
    qs = pattern.strip("/").split("/")
    if len(ps) != len(qs):
        return out
    for seg, tok in zip(ps, qs):
        m = re.fullmatch(r"\{([^}]+)\}", tok)
        if m and tok.startswith("{"):
            out[m.group(1)] = seg
    return out


def _runtime_lookup_view(handler: dict, file_id: str) -> dict | None:
    """Return the stored file record for file_id, or None."""
    for rec in _runtime_files.get(_domain_of(handler), []):
        if rec.get("id") == file_id:
            return rec
    return None


def _match_route(handler: dict, method: str, path: str) -> dict | None:
    """Find a matching route in the handler config.

    Supports exact path matching, path patterns with {param} placeholders, and
    a last-resort prefix match. Exact and pattern matches always beat prefix
    matches (so a `/v1/pages/{pageId}` route wins over a `/v1/pages` route for
    `/v1/pages/abc123`), and within a kind the *first* declared route wins.
    """
    routes = handler.get("routes", [])

    # Pass 1: exact + pattern (most specific).
    for route in routes:
        route_method = route.get("method", "GET").upper()
        if route_method != method.upper():
            continue
        route_path = route.get("path", "")
        if route_path == path:
            return route
        if "{" in route_path:
            pattern = re.sub(r"\{[^}]+\}", r"[^/]+", route_path)
            pattern = f"^{pattern}$"
            if re.match(pattern, path):
                return route

    # Pass 2: prefix match (least specific).
    for route in routes:
        route_method = route.get("method", "GET").upper()
        if route_method != method.upper():
            continue
        route_path = route.get("path", "")
        if path.startswith(route_path.rstrip("/") + "/") or path == route_path.rstrip("/"):
            return route

    return None


def _build_response(route: dict, handler: dict, path: str) -> tuple:
    """Build a Flask response from a matched route config."""
    # --- File storage layer (serve_file / store_file) ---------------------
    # A route may declare "serve_file" to return real file bytes from the
    # mock storage directory (so a "download / export" actually produces a
    # file instead of an empty body), or "store_file" to persist the request
    # body into storage (so an "upload" really lands a file). This keeps the
    # mock stateful for file blobs while route/fixture JSON stays unchanged.
    sf = route.get("serve_file")
    if sf is not None:
        return _serve_storage_file(sf, route, handler, path)
    if route.get("store_file"):
        return _store_upload(route, handler, path)

    # Static response from route
    response_data = route.get("response")
    status_code = route.get("status_code", 200)

    # If response is a string, try to load from fixtures
    if isinstance(response_data, str) and response_data.startswith("$fixture."):
        fixture_key = response_data[len("$fixture."):]
        fixtures = handler.get("fixtures", {})
        if fixture_key in fixtures:
            response_data = fixtures[fixture_key]

    # If response has a "list" key, apply query filtering
    if isinstance(response_data, dict):
        # Deep copy first so runtime merges / query filtering never mutate the
        # loaded fixture objects (shared across requests).
        import copy
        response_data = copy.deepcopy(response_data)

        # --- Runtime state: uploaded files --------------------------------
        # Merge uploaded-file records into list responses (`files`, `items`,
        # any list field of dicts that have an "id"), so uploads appear in
        # listings. Also override single-file view responses when the requested
        # fileId matches a runtime record.
        domain = _domain_of(handler)
        rt = _runtime_files.get(domain, [])
        if rt:
            view_id = _path_param(path, route.get("path", "")).get("fileId", "")
            if view_id:
                rec = _runtime_lookup_view(handler, view_id)
                if rec:
                    response_data = copy.deepcopy(rec)
                    return jsonify(response_data), status_code
            for key, list_data in response_data.items():
                if isinstance(list_data, list):
                    response_data[key] = list(list_data) + [
                        r for r in rt if not any(
                            i.get("id") == r.get("id") for i in list_data)]

        # Apply simple query param filtering for list endpoints
        for key, list_data in response_data.items():
            if isinstance(list_data, list) and request.args:
                # Support ?q= query filtering
                q = request.args.get("q", "").lower()
                if q and len(list_data) > 0 and isinstance(list_data[0], dict):
                    filtered = []
                    for item in list_data:
                        # Search across all string fields
                        for v in item.values():
                            if isinstance(v, str) and q in v.lower():
                                filtered.append(item)
                                break
                    response_data[key] = filtered

                # Support ?pageSize= limit
                page_size = request.args.get("pageSize") or request.args.get("page_size")
                if page_size:
                    try:
                        limit = int(page_size)
                        response_data[key] = list_data[:limit]
                    except (ValueError, TypeError):
                        pass

    # If no response data, return a generic success
    if response_data is None:
        response_data = {"success": True, "message": "Mock response"}

    return jsonify(response_data), status_code

STORAGE_DIR = Path("/tmp/scry/mock_api/storage")


def _resolve_storage_filename(value, handler: dict) -> str:
    """Resolve a serve_file value to a storage filename.

    value may be a bare filename, "$fixture.<key>[/.<subpath>]" (taken from
    the handler's fixtures), "$param.<name>" (taken from the request path,
    resolved against the route pattern), or a dict
    {"filename": ..., "from_fixture": "<key>", "lookup_fileid": "<param name>"}.
    """
    if isinstance(value, dict):
        name = value.get("filename") or ""
        fk = value.get("from_fixture")
        if fk and not name:
            ref = fk[len("$fixture."):] if fk.startswith("$fixture.") else fk
            node: Any = handler.get("fixtures", {})
            for seg in ref.split("."):
                node = node.get(seg) if isinstance(node, dict) else node
            if isinstance(node, str):
                name = node
        return name
    if isinstance(value, str) and value.startswith("$fixture."):
        node: Any = handler.get("fixtures", {})
        for seg in value[len("$fixture."):].split("."):
            node = node.get(seg) if isinstance(node, dict) else node
        return node if isinstance(node, str) else ""
    return str(value) if value else ""


def _serve_storage_file(sf, route: dict, handler: dict, path: str) -> tuple:
    """Serve a real file from STORAGE_DIR as a download.

    If serve_file is {"lookup_fileid": "<param>"} the served filename is taken
    from the runtime registry (the file uploaded under that fileId), so an
    uploaded file can be downloaded back by its id. Otherwise serve_file is
    resolved statically (file / fixture name).
    """
    status_code = route.get("status_code", 200)
    filename = ""
    if isinstance(sf, dict) and sf.get("lookup_fileid"):
        fid = _path_param(path, route.get("path", "")).get(sf["lookup_fileid"], "")
        # 1. runtime registry (uploaded file)
        rec = _runtime_lookup_view(handler, fid)
        if rec:
            filename = rec.get("name", "")
        # 2. static id→file map shipped as a fixture (initial files)
        if not filename and sf.get("fallback_fixture"):
            fmap = handler.get("fixtures", {}).get(sf["fallback_fixture"])
            if isinstance(fmap, dict):
                filename = fmap.get(fid, "")
    if not filename:
        filename = _resolve_storage_filename(sf, handler)
    if not filename:
        return _internal_error_response()
    safe = Path(filename).name  # prevent traversal — basename only
    fp = _storage_dir_for(handler) / safe
    if not fp.is_file():
        return _not_found_response()
    try:
        content = fp.read_bytes()
    except OSError:
        return _internal_error_response()
    resp = Response(content, mimetype=get_content_type(safe))
    resp.headers["Content-Disposition"] = f'attachment; filename="{safe}"'
    return resp, status_code


def _store_upload(route: dict, handler: dict, path: str) -> tuple:
    """Persist an uploaded body into STORAGE_DIR and register a file record.

    The filename is taken from the `?filename=` query param or the
    `X-Filename` header (provided by the mock CLI), defaulting to a generated
    name. A Drive-shaped file record (id / name / mimeType / size / createdTime
    / modifiedTime / parents / owners / shared / starred ...) is appended to the
    runtime registry for this domain, so the uploaded file appears in the next
    `GET /files` listing and can be downloaded back by its id. The route's
    inline `response` is reused as a template and enriched with the real id /
    name / size so the caller sees a believable, self-consistent result.
    """
    status_code = route.get("status_code", 200)
    sdir = _storage_dir_for(handler)
    filename = request.args.get("filename") or request.headers.get("X-Filename") or ""
    safe = Path(filename).name if filename else f"upload_{int(time.time()*1000)}.bin"
    body = request.get_data() or b""
    try:
        (sdir / safe).write_bytes(body)
    except OSError:
        return _internal_error_response()

    now = time.strftime("%Y-%m-%dT%H:%M:%S.000Z", time.gmtime())
    file_id = "1" + uuid.uuid4().hex[:20]
    mime_type = get_content_type(safe) or "application/octet-stream"
    record = {
        "kind": "drive#file",
        "id": file_id,
        "name": safe,
        "mimeType": mime_type,
        "size": str(len(body)),
        "createdTime": now,
        "modifiedTime": now,
        "parents": [],
        "owners": [{"kind": "drive#user", "displayName": "user", "emailAddress": "user@company.com", "me": True}],
        "shared": False,
        "starred": False,
        "trashed": False,
        "viewedByMe": True,
        "modifiedByMeTime": now,
        "fullFileExtension": Path(safe).suffix.lstrip("."),
        "fileExtension": Path(safe).suffix.lstrip("."),
        "capabilities": {"canEdit": True, "canComment": True, "canShare": True,
                          "canDownload": True, "canRename": True, "canDelete": True},
    }
    domain = _domain_of(handler)
    _runtime_files.setdefault(domain, []).append(record)
    save_runtime_state()

    response_data = route.get("response")
    if isinstance(response_data, dict):
        import copy
        response_data = copy.deepcopy(response_data)
        response_data.setdefault("kind", "drive#file")
        response_data["id"] = file_id
        response_data["name"] = safe
        response_data["mimeType"] = mime_type
        response_data.setdefault("size", len(body))
        response_data.setdefault("createdTime", now)
        response_data.setdefault("modifiedTime", now)
    return jsonify(response_data), status_code


# ---------------------------------------------------------------------------
# Host-first API handler dispatch
# ---------------------------------------------------------------------------
# Flask resolves concrete routes such as POST /upload before the catch-all
# /<path:path> route.  Without this hook, an intercepted upstream API whose
# real route is also /upload is handled by this server's legacy local upload
# endpoint and never reaches its skill handler.  Dispatch registered external
# hosts before Flask invokes any endpoint so the Host namespace, not route
# specificity, decides whether a request belongs to a simulated API.

def _dispatch_registered_api_handler():
    """Dispatch the current request when its Host has a registered handler.

    Return ``None`` only for an unregistered Host, allowing Flask to continue
    to local data routes such as /upload and /content.
    A registered Host always receives a handler response (including a handler
    404), so local control/data endpoints cannot shadow upstream API paths.
    """
    host = request.headers.get("Host", "").split(":")[0]
    handler = _api_handlers.get(host)
    if handler is None:
        return None

    method = request.method
    full_path = request.path or "/"

    path_prefix = handler.get("path_prefix", "")
    effective_path = full_path
    if path_prefix and effective_path.startswith(path_prefix):
        effective_path = effective_path[len(path_prefix):] or "/"

    route = _match_route(handler, method, full_path)
    if route is None:
        route = _match_route(handler, method, effective_path)

    call_record = {
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "domain": host,
        "method": method,
        "path": full_path,
        "query": dict(request.args),
        "matched": route is not None,
    }
    if method in ("POST", "PUT", "PATCH"):
        try:
            body = request.get_json(silent=True)
            if body is None:
                body = request.get_data(as_text=True)[:500]
            call_record["request_body"] = body
        except Exception:
            pass
    _audit_log.append(call_record)

    if route is not None:
        resp, status = _build_response(route, handler, full_path)
        call_record["status_code"] = status
        return resp, status

    call_record["status_code"] = 404
    return _not_found_response()


@app.before_request
def dispatch_registered_api_handler_first():
    """Give registered external API hosts priority over local Flask routes."""
    return _dispatch_registered_api_handler()


# Content-Type mappings
CONTENT_TYPES = {
    '.html': 'text/html; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.js': 'application/javascript; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.txt': 'text/plain; charset=utf-8',
    '.xml': 'application/xml; charset=utf-8',
    '.zip': 'application/zip',
    '.pdf': 'application/pdf',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon',
}


def load_config():
    """Load configuration from config.json"""
    global config
    config_file = Path(__file__).parent / "config.json"

    if not config_file.exists():
        print(f"Warning: {config_file} not found, using defaults")
        config = {
            "server": {"host": "0.0.0.0", "port": 8000},
            "data": {"path": "./data"}
        }
        return

    with open(config_file, "r", encoding="utf-8") as f:
        config = json.load(f)

    print(f"Loaded config from {config_file}")


def get_data_dir():
    """Get data directory path"""
    data_path = config.get("data", {}).get("path", "./data")
    return Path(__file__).parent / data_path


def get_content_type(filename):
    """Get Content-Type based on file extension"""
    ext = Path(filename).suffix.lower()
    return CONTENT_TYPES.get(ext, 'application/octet-stream')


def find_file(filename):
    """Find file in data directory by name (without extension)"""
    data_dir = get_data_dir()

    # Try exact match first
    exact_path = data_dir / filename
    if exact_path.exists() and exact_path.is_file():
        return exact_path

    # Try to find file with any supported extension
    for ext in CONTENT_TYPES.keys():
        file_path = data_dir / f"{filename}{ext}"
        if file_path.exists() and file_path.is_file():
            return file_path

    return None


@app.route('/content/<filename>')
def serve_content(filename):
    """Serve static files from data directory by filename (without extension)"""
    data_dir = get_data_dir()

    # Find matching file
    file_path = find_file(filename)

    if file_path is None:
        return _not_found_response()

    # Security check: ensure file is within data directory
    try:
        file_path.resolve().relative_to(data_dir.resolve())
    except ValueError:
        return jsonify({
            "error": "Forbidden",
            "message": "Access denied"
        }), 403

    # Read file content
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Get content type based on actual file extension
    content_type = get_content_type(file_path.name)

    return Response(content, mimetype=content_type)


@app.route('/__list', methods=['GET'])
def list_files():
    """List all available files in data directory"""
    data_dir = get_data_dir()

    if not data_dir.exists():
        return jsonify({"count": 0, "files": []})

    files = []
    for f in data_dir.iterdir():
        if f.is_file():
            files.append(f.name)

    return jsonify({
        "count": len(files),
        "files": sorted(files)
    })


@app.route('/__reload', methods=['POST'])
def reload_config():
    """Reload configuration"""
    load_config()
    return jsonify({"status": "ok", "message": "Configuration reloaded"})


@app.route('/download/<path:filename>')
def download_file(filename):
    """Serve file for download by exact filename (with extension)"""
    data_dir = get_data_dir()

    # Security check: prevent path traversal
    if '..' in filename:
        return jsonify({
            "error": "Forbidden",
            "message": "Invalid filename"
        }), 403

    # Exact match in data directory
    file_path = data_dir / filename

    # Check if file exists and is a file
    if not file_path.exists() or not file_path.is_file():
        return _not_found_response()

    # Security check: ensure file is within data directory
    try:
        file_path.resolve().relative_to(data_dir.resolve())
    except ValueError:
        return jsonify({
            "error": "Forbidden",
            "message": "Access denied"
        }), 403

    # Get content type
    content_type = get_content_type(file_path.name)

    # Read file content as binary
    with open(file_path, 'rb') as f:
        content = f.read()

    # Create response with download header
    response = Response(content, mimetype=content_type)
    response.headers['Content-Disposition'] = f'attachment; filename="{file_path.name}"'
    return response


@app.route('/site/<path:filepath>')
def serve_site(filepath):
    """Serve files from data directory with full path support (for website testing)"""
    data_dir = get_data_dir()

    # Security check: prevent path traversal
    if '..' in filepath:
        return jsonify({
            "error": "Forbidden",
            "message": "Invalid path"
        }), 403

    # Build file path
    file_path = data_dir / filepath

    # Check if file exists and is a file
    if not file_path.exists() or not file_path.is_file():
        return _not_found_response()

    # Security check: ensure file is within data directory
    try:
        file_path.resolve().relative_to(data_dir.resolve())
    except ValueError:
        return jsonify({
            "error": "Forbidden",
            "message": "Access denied"
        }), 403

    # Get content type
    content_type = get_content_type(file_path.name)

    # Read file content as binary (supports all file types)
    with open(file_path, 'rb') as f:
        content = f.read()

    # Return content directly (no download header, for display in browser)
    return Response(content, mimetype=content_type)


@app.route('/upload', methods=['POST'])
def upload_file():
    """Upload a file to the data directory"""
    data_dir = get_data_dir()

    # Ensure data directory exists
    data_dir.mkdir(parents=True, exist_ok=True)

    # Check if file is in request
    if 'file' not in request.files:
        return jsonify({
            "error": "Bad Request",
            "message": "No file provided. Use 'file' field in multipart form."
        }), 400

    file = request.files['file']

    # Check if filename is empty
    if file.filename == '':
        return jsonify({
            "error": "Bad Request",
            "message": "No file selected"
        }), 400

    filename = file.filename

    # Security check: prevent path traversal
    if '..' in filename or '/' in filename or '\\' in filename:
        return jsonify({
            "error": "Forbidden",
            "message": "Invalid filename"
        }), 403

    # Save file
    save_path = data_dir / filename
    file.save(save_path)

    # Get file size
    file_size = save_path.stat().st_size

    return jsonify({
        "status": "ok",
        "message": "File uploaded successfully",
        "file": {
            "name": filename,
            "size": file_size,
            "path": f"/content/{filename}"
        }
    })


@app.route('/__api_handlers', methods=['GET'])
def list_api_handlers():
    """List all registered API mock handlers."""
    result = {}
    for domain, handler in _api_handlers.items():
        routes = handler.get("routes", [])
        result[domain] = {
            "domain": domain,
            "path_prefix": handler.get("path_prefix", ""),
            "routes_count": len(routes),
            "routes": [{"method": r.get("method", "GET"), "path": r.get("path", "/")} for r in routes],
        }
    return jsonify({
        "count": len(result),
        "handlers": result,
    })


@app.route('/__api_audit', methods=['GET'])
def get_api_audit():
    """Get audit log of all API mock calls."""
    return jsonify({
        "count": len(_audit_log),
        "calls": _audit_log[-100:],  # Last 100 calls
    })


@app.route('/__api_audit', methods=['DELETE'])
def clear_api_audit():
    """Clear the API mock audit log."""
    _audit_log.clear()
    return jsonify({"status": "ok", "message": "Audit log cleared"})


@app.route('/__reload_handlers', methods=['POST'])
def reload_handlers():
    """Reload API mock handlers from disk."""
    load_api_handlers()
    return jsonify({"status": "ok", "handlers": len(_api_handlers)})


# ---------------------------------------------------------------------------
# Catch-all fallback for unregistered hosts
# ---------------------------------------------------------------------------
# Registered API domains have already been handled by the Host-first
# before_request hook above. Keep this route last as the local/static fallback.
# ---------------------------------------------------------------------------

@app.route('/<path:path>', methods=['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS', 'HEAD'])
def api_mock_catchall(path):
    """Catch-all fallback for requests without a registered API Host.

    Registered API hosts are dispatched by ``dispatch_registered_api_handler_first``
    before Flask selects a concrete local route. Reaching this function means
    the Host is not registered; preserve the legacy static-file fallback and
    otherwise return a diagnostic 404.
    """
    host = request.headers.get("Host", "").split(":")[0]  # Strip port
    full_path = "/" + path if path else "/"

    # No handler for this host — check if it's a static file request
    # (preserve backward compatibility with the original mock-api behavior)
    if path and not host:
        file_path = find_file(path)
        if file_path is not None:
            content_type = get_content_type(file_path.name)
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                return Response(content, mimetype=content_type)
            except Exception:
                pass

    return _not_found_response()


@app.route('/')
def root():
    """Do not expose service metadata for an unregistered Host."""
    return _not_found_response()


def start_https_server(host: str, https_port: int):
    """Start an HTTPS server in a background thread for transparent API mocking.

    When iptables redirects port 443 to our HTTPS port, the agent's skill
    binary connects to it thinking it's the real server. The self-signed
    cert must be trusted or the skill binary must skip cert verification.
    """
    import ssl
    import threading

    cert_dir = Path("/tmp/scry/mock_api/ssl")
    cert_file = cert_dir / "mock-api.crt"
    key_file = cert_dir / "mock-api.key"

    if not cert_file.exists() or not key_file.exists():
        print(f"  [HTTPS] No SSL cert found at {cert_dir}, HTTPS server not started")
        return

    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(str(cert_file), str(key_file))

    from werkzeug.serving import make_server
    https_server = make_server(host, https_port, app, ssl_context=ctx)

    def serve():
        print(f"  [HTTPS] Mock API HTTPS server running on {host}:{https_port}")
        https_server.serve_forever()

    t = threading.Thread(target=serve, daemon=True)
    t.start()


if __name__ == '__main__':
    # Load config on startup
    load_config()

    # Load API mock handlers
    print("Loading API mock handlers...")
    load_api_handlers()

    # Get settings from config
    host = config.get("server", {}).get("host", "0.0.0.0")
    port = config.get("server", {}).get("port", 80)
    https_port = config.get("server", {}).get("https_port", 443)

    data_dir = get_data_dir()
    print(f"\nMock API Server starting on {host}:{port}")
    print(f"Data directory: {data_dir}")
    print(f"API handlers: {list(_api_handlers.keys())}")
    print(f"Available endpoints:")
    print(f"  - GET /content/<filename> : Serve file (without extension)")
    print(f"  - GET /download/<filename>: Download file (exact filename)")
    print(f"  - GET /site/<path>        : Serve file with full path (website)")
    print(f"  - GET /__list             : List available files")
    print(f"  - POST /__reload          : Reload configuration")
    print(f"  - POST /__reload_handlers : Reload API mock handlers")
    print(f"  - GET /__api_handlers     : List API mock handlers")
    print(f"  - GET /__api_audit        : API call audit log")
    print(f"  - POST /upload            : Upload a file")
    print(f"  - ANY /<path>             : API mock proxy (by Host header)")

    # HTTPS is required for intercepted skill APIs and for the configured web
    # simulation origin (Claude WebFetch may upgrade HTTP URLs to HTTPS).
    if _api_handlers or os.environ.get("WEB_SIM_BASE_URL"):
        start_https_server(host, https_port)

    print()
    app.run(host=host, port=port, debug=False)
