#!/usr/bin/env python3
"""
Yuque Client - A Python client for the Yuque (Yuque) open API.

Usage:
    python yuque_client.py <command> [options]

Commands:
    user-info                       Show the current user
    resolve-url <url>               Resolve a Yuque URL to its book_id / doc_id
    search <keyword>                Search docs / knowledge bases by keyword
    doc-list <book_id>              List docs in a knowledge base (repo)
    doc-detail <doc_id>             Read a doc's full content (alias: read)
    book-detail <book_id>           Show a knowledge base's metadata
    book-toc <book_id>              Show a knowledge base's table of contents
    doc-create <book_id> <body>     Create a new doc in a knowledge base
    doc-update <doc_id>             Update / append to a doc (alias: append)
    user-recent                     Recent docs the current user touched

Examples:
    python yuque_client.py user-info
    python yuque_client.py search "weekly report"
    python yuque_client.py doc-list 40999
    python yuque_client.py doc-detail 466200001
    python yuque_client.py doc-create 40999 "Completed this week X, Y;Plan for next week Z" --title "2026 Week 23 weekly report" --public 0
    python yuque_client.py doc-update 466200001 --body "Update: Progress was aligned on Friday"
"""

import argparse
import json
import os
import sys

try:
    import requests  # type: ignore
except ImportError:
    # Minimal stdlib-only fallback so the client works without the `requests`
    # package installed (the runtime environment has no outbound network to
    # pip-install it). Implements just the get/post/put(...).json() surface and
    # the ConnectionError exception this client uses.
    import urllib.request
    import urllib.error

    class _Resp:
        def __init__(self, body: bytes, status: int):
            self._body = body
            self.status_code = status

        def json(self):
            return json.loads(self._body.decode("utf-8") or "{}")

        @property
        def text(self):
            return self._body.decode("utf-8", "replace")

    class _Exceptions:
        ConnectionError = ConnectionError

    class _RequestsShim:
        exceptions = _Exceptions

        def _do(self, method, url, json=None, params=None, timeout=60, **_):
            if params:
                from urllib.parse import urlencode
                sep = "&" if "?" in url else "?"
                url = url + sep + urlencode(params)
            data = None
            headers = {}
            if json is not None:
                import json as _json
                data = _json.dumps(json).encode("utf-8")
                headers["Content-Type"] = "application/json"
            req = urllib.request.Request(url, data=data, headers=headers, method=method)
            try:
                with urllib.request.urlopen(req, timeout=timeout) as r:
                    return _Resp(r.read(), r.getcode())
            except urllib.error.HTTPError as e:
                return _Resp(e.read(), e.code)
            except urllib.error.URLError as e:
                raise ConnectionError(str(e))

        def get(self, url, **kw):
            return self._do("GET", url, **kw)

        def post(self, url, **kw):
            return self._do("POST", url, **kw)

        def put(self, url, **kw):
            return self._do("PUT", url, **kw)

    requests = _RequestsShim()

BASE_URL = os.environ.get("YUQUE_BASE_URL", "http://localhost:18070")
TIMEOUT = 60

_CONN_ERR = "❌ Cannot connect to the Yuque service. Make sure it is running on localhost:18070"


def _get(path, **kw):
    return requests.get(f"{BASE_URL}{path}", timeout=TIMEOUT, **kw)


def _post(path, payload):
    return requests.post(f"{BASE_URL}{path}", json=payload, timeout=TIMEOUT)


def _put(path, payload):
    return requests.put(f"{BASE_URL}{path}", json=payload, timeout=TIMEOUT)


def user_info():
    """Show the current logged-in user."""
    try:
        data = _get("/api/v2/user").json()
        u = data.get("data", {})
        print("👤 Current user:")
        print(f"    login : {u.get('login', 'unknown')}")
        print(f"    name  : {u.get('name', 'unknown')}")
        print(f"    id    : {u.get('id', '')}")
        return data
    except requests.exceptions.ConnectionError:
        print(_CONN_ERR)
        sys.exit(1)


def resolve_url(url):
    """Resolve a Yuque URL to its book_id / doc_id."""
    try:
        data = _post("/api/v2/resolve", {"url": url}).json()
        d = data.get("data", {})
        print(f"🔗 Resolved {url}")
        print(f"    type      : {d.get('type', '')}")
        print(f"    namespace : {d.get('namespace', '')}")
        print(f"    book_id   : {d.get('book_id', '')}")
        print(f"    doc_id    : {d.get('doc_id', '')}")
        return data
    except requests.exceptions.ConnectionError:
        print(_CONN_ERR)
        sys.exit(1)


def search(keyword, scope=None):
    """Search docs / knowledge bases by keyword."""
    try:
        params = {"q": keyword}
        if scope:
            params["scope"] = scope
        data = _get("/api/v2/search", params=params).json()
        hits = data.get("data", [])
        print(f"🔍 Found {len(hits)} result(s) for '{keyword}':\n")
        for i, h in enumerate(hits, 1):
            print(f"[{i}] {h.get('title', 'No title')}  ({h.get('type', 'DOC')})")
            print(f"    book : {h.get('book_name', '')}")
            print(f"    url  : {h.get('url', '')}")
            print(f"    doc_id  : {h.get('doc_id', '')}")
            print(f"    book_id : {h.get('book_id', '')}")
            print()
        return data
    except requests.exceptions.ConnectionError:
        print(_CONN_ERR)
        sys.exit(1)


def doc_list(book_id, limit=20, offset=0):
    """List docs in a knowledge base."""
    try:
        data = _get(f"/api/v2/repos/{book_id}/docs",
                    params={"limit": limit, "offset": offset}).json()
        docs = data.get("data", [])
        print(f"📋 {len(docs)} doc(s) in book {book_id}:\n")
        for i, d in enumerate(docs, 1):
            print(f"[{i}] {d.get('title', 'No title')}")
            print(f"    doc_id : {d.get('id', '')}   slug: {d.get('slug', '')}")
            print()
        return data
    except requests.exceptions.ConnectionError:
        print(_CONN_ERR)
        sys.exit(1)


def doc_detail(doc_id):
    """Read a doc's full content."""
    try:
        data = _get(f"/api/v2/docs/{doc_id}").json()
        d = data.get("data", {})
        print("📝 Doc detail:\n")
        print(f"Title : {d.get('title', 'No title')}")
        print(f"Author: {d.get('author', 'unknown')}")
        print(f"Book  : {d.get('book_name', '')}")
        print(f"Public: {d.get('public', '')}   ReadCount: {d.get('read_count', 0)}")
        print(f"URL   : {d.get('url', '')}")
        print(f"\nContent:\n{d.get('body_md', '(empty)')}")
        return data
    except requests.exceptions.ConnectionError:
        print(_CONN_ERR)
        sys.exit(1)


def book_detail(book_id):
    """Show a knowledge base's metadata."""
    try:
        data = _get(f"/api/v2/repos/{book_id}").json()
        b = data.get("data", {})
        print("📚 Knowledge base:\n")
        print(f"Name       : {b.get('name', '')}")
        print(f"Namespace  : {b.get('namespace', '')}")
        print(f"Public     : {b.get('public', '')}")
        print(f"Doc count  : {b.get('items_count', 0)}")
        print(f"Description: {b.get('description', '')}")
        return data
    except requests.exceptions.ConnectionError:
        print(_CONN_ERR)
        sys.exit(1)


def book_toc(book_id):
    """Show a knowledge base's table of contents."""
    try:
        data = _get(f"/api/v2/repos/{book_id}/toc").json()
        toc = data.get("data", [])
        print(f"🗂  TOC of book {book_id} ({len(toc)} node(s)):\n")
        for node in toc:
            indent = "  " * int(node.get("depth", 0))
            print(f"{indent}- {node.get('title', '')}  (doc_id: {node.get('doc_id', '')})")
        return data
    except requests.exceptions.ConnectionError:
        print(_CONN_ERR)
        sys.exit(1)


def doc_create(book_id, body, title=None, public="0", fmt="markdown"):
    """Create a new doc in a knowledge base."""
    try:
        payload = {"title": title or "Untitled", "body": body,
                   "public": public, "format": fmt}
        data = _post(f"/api/v2/repos/{book_id}/docs", payload).json()
        d = data.get("data", {})
        print("✅ Doc created.")
        print(f"    doc_id : {d.get('id', '')}")
        print(f"    title  : {d.get('title', '')}")
        print(f"    url    : {d.get('url', '')}")
        return data
    except requests.exceptions.ConnectionError:
        print(_CONN_ERR)
        sys.exit(1)


def doc_update(doc_id, title=None, body=None, public=None):
    """Update / append to a doc."""
    try:
        payload = {}
        if title is not None:
            payload["title"] = title
        if body is not None:
            payload["body"] = body
        if public is not None:
            payload["public"] = public
        data = _put(f"/api/v2/docs/{doc_id}", payload).json()
        d = data.get("data", {})
        print("✅ Doc updated.")
        print(f"    doc_id : {d.get('id', '')}")
        print(f"    title  : {d.get('title', '')}")
        print(f"    url    : {d.get('url', '')}")
        return data
    except requests.exceptions.ConnectionError:
        print(_CONN_ERR)
        sys.exit(1)


def user_recent(rtype="doc", limit=20):
    """Recent docs the current user touched."""
    try:
        data = _get("/api/v2/user/recent", params={"type": rtype, "limit": limit}).json()
        items = data.get("data", [])
        print(f"🕒 {len(items)} recent item(s):\n")
        for i, it in enumerate(items, 1):
            print(f"[{i}] {it.get('title', '')}  (doc_id: {it.get('doc_id', '')})")
        return data
    except requests.exceptions.ConnectionError:
        print(_CONN_ERR)
        sys.exit(1)


def _maybe_json(args, result):
    if getattr(args, "json", False):
        print(json.dumps(result, ensure_ascii=False, indent=2))


def main():
    parser = argparse.ArgumentParser(
        description="Yuque (Yuque) API Client",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    sub = parser.add_subparsers(dest="command", help="Available commands")

    sub.add_parser("user-info", help="Show the current user").add_argument(
        "--json", action="store_true", help="Output raw JSON")

    p = sub.add_parser("resolve-url", help="Resolve a Yuque URL")
    p.add_argument("url", help="Yuque doc / repo URL")
    p.add_argument("--json", action="store_true", help="Output raw JSON")

    p = sub.add_parser("search", help="Search docs / knowledge bases")
    p.add_argument("keyword", help="Search keyword")
    p.add_argument("--scope", default=None, help="Limit to a knowledge base namespace")
    p.add_argument("--json", action="store_true", help="Output raw JSON")

    p = sub.add_parser("doc-list", help="List docs in a knowledge base")
    p.add_argument("book_id", help="Knowledge base (repo) id")
    p.add_argument("--limit", type=int, default=20)
    p.add_argument("--offset", type=int, default=0)
    p.add_argument("--json", action="store_true", help="Output raw JSON")

    for name in ("doc-detail", "read"):
        p = sub.add_parser(name, help="Read a doc's full content")
        p.add_argument("doc_id", help="Doc id")
        p.add_argument("--json", action="store_true", help="Output raw JSON")

    p = sub.add_parser("book-detail", help="Show a knowledge base's metadata")
    p.add_argument("book_id", help="Knowledge base (repo) id")
    p.add_argument("--json", action="store_true", help="Output raw JSON")

    p = sub.add_parser("book-toc", help="Show a knowledge base's TOC")
    p.add_argument("book_id", help="Knowledge base (repo) id")
    p.add_argument("--json", action="store_true", help="Output raw JSON")

    p = sub.add_parser("doc-create", help="Create a new doc")
    p.add_argument("book_id", help="Knowledge base (repo) id")
    p.add_argument("body", help="Doc body (markdown)")
    p.add_argument("--title", default=None, help="Doc title")
    p.add_argument("--public", default="0", choices=["0", "1", "2"],
                   help="Visibility: 0 private, 1 public, 2 enterprise")
    p.add_argument("--format", dest="fmt", default="markdown")
    p.add_argument("--json", action="store_true", help="Output raw JSON")

    for name in ("doc-update", "append"):
        p = sub.add_parser(name, help="Update / append to a doc")
        p.add_argument("doc_id", help="Doc id")
        p.add_argument("--title", default=None, help="New title")
        p.add_argument("--body", default=None, help="New / appended body (markdown)")
        p.add_argument("--public", default=None, choices=["0", "1", "2"])
        p.add_argument("--json", action="store_true", help="Output raw JSON")

    p = sub.add_parser("user-recent", help="Recent docs the user touched")
    p.add_argument("--type", dest="rtype", default="doc")
    p.add_argument("--limit", type=int, default=20)
    p.add_argument("--json", action="store_true", help="Output raw JSON")

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(1)

    cmd = args.command
    if cmd == "user-info":
        _maybe_json(args, user_info())
    elif cmd == "resolve-url":
        _maybe_json(args, resolve_url(args.url))
    elif cmd == "search":
        _maybe_json(args, search(args.keyword, args.scope))
    elif cmd == "doc-list":
        _maybe_json(args, doc_list(args.book_id, args.limit, args.offset))
    elif cmd in ("doc-detail", "read"):
        _maybe_json(args, doc_detail(args.doc_id))
    elif cmd == "book-detail":
        _maybe_json(args, book_detail(args.book_id))
    elif cmd == "book-toc":
        _maybe_json(args, book_toc(args.book_id))
    elif cmd == "doc-create":
        _maybe_json(args, doc_create(args.book_id, args.body, args.title, args.public, args.fmt))
    elif cmd in ("doc-update", "append"):
        _maybe_json(args, doc_update(args.doc_id, args.title, args.body, args.public))
    elif cmd == "user-recent":
        _maybe_json(args, user_recent(args.rtype, args.limit))


if __name__ == "__main__":
    main()
