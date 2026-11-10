#!/usr/bin/env python3
"""
Xiaohongshu MCP Client - A Python client for xiaohongshu-mcp HTTP API.

Usage:
    python xhs_client.py <command> [options]

Commands:
    status              Check login status
    search <keyword>    Search notes by keyword
    detail <feed_id> <xsec_token>   Get note details
    feeds               Get recommended feed list
    publish <title> <content> <images>  Publish a note

Examples:
    python xhs_client.py status
    python xhs_client.py search "coffee recommendations"
    python xhs_client.py detail "abc123" "token456"
    python xhs_client.py feeds
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
    # pip-install it). Implements just the get/post(...).json() surface and the
    # ConnectionError exception this client uses.
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

        def _do(self, method, url, json=None, timeout=60, **_):
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

    requests = _RequestsShim()

BASE_URL = os.environ.get("XHS_BASE_URL", "http://localhost:18060")
TIMEOUT = 60


def check_status():
    """Check login status."""
    try:
        resp = requests.get(f"{BASE_URL}/api/v1/login/status", timeout=TIMEOUT)
        data = resp.json()
        if data.get("success"):
            login_info = data.get("data", {})
            if login_info.get("is_logged_in"):
                print(f"✅ Logged in as: {login_info.get('username', 'Unknown')}")
            else:
                print("❌ Not logged in. Please run the login tool first.")
        else:
            print(f"❌ Error: {data.get('error', 'Unknown error')}")
        return data
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to MCP server. Make sure xiaohongshu-mcp is running on localhost:18060")
        sys.exit(1)


def search_notes(keyword, sort_by="Relevance", note_type="Any", publish_time="Any"):
    """Search notes by keyword with optional filters."""
    try:
        payload = {
            "keyword": keyword,
            "filters": {
                "sort_by": sort_by,
                "note_type": note_type,
                "publish_time": publish_time
            }
        }
        resp = requests.post(
            f"{BASE_URL}/api/v1/feeds/search",
            json=payload,
            timeout=TIMEOUT
        )
        data = resp.json()
        
        if data.get("success"):
            feeds = data.get("data", {}).get("feeds", [])
            print(f"🔍 Found {len(feeds)} notes for '{keyword}':\n")
            
            for i, feed in enumerate(feeds, 1):
                note_card = feed.get("noteCard", {})
                user = note_card.get("user", {})
                interact = note_card.get("interactInfo", {})
                
                print(f"[{i}] {note_card.get('displayTitle', 'No title')}")
                print(f"    Author: {user.get('nickname', 'Unknown')}")
                print(f"    Likes: {interact.get('likedCount', '0')} | Collects: {interact.get('collectedCount', '0')} | Comments: {interact.get('commentCount', '0')}")
                print(f"    feed_id: {feed.get('id')}")
                print(f"    xsec_token: {feed.get('xsecToken')}")
                print()
        else:
            print(f"❌ Search failed: {data.get('error', 'Unknown error')}")
        
        return data
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to MCP server.")
        sys.exit(1)


def get_note_detail(feed_id, xsec_token, load_comments=False):
    """Get detailed information about a specific note."""
    try:
        payload = {
            "feed_id": feed_id,
            "xsec_token": xsec_token,
            "load_all_comments": load_comments
        }
        resp = requests.post(
            f"{BASE_URL}/api/v1/feeds/detail",
            json=payload,
            timeout=TIMEOUT
        )
        data = resp.json()
        
        if data.get("success"):
            note_data = data.get("data", {}).get("data", {})
            note = note_data.get("note", {})
            comments = note_data.get("comments", {})
            
            print(f"📝 Note Details:\n")
            print(f"Title: {note.get('title', 'No title')}")
            print(f"Author: {note.get('user', {}).get('nickname', 'Unknown')}")
            print(f"Location: {note.get('ipLocation', 'Unknown')}")
            print(f"\nContent:\n{note.get('desc', 'No content')}\n")
            
            interact = note.get("interactInfo", {})
            print(f"Likes: {interact.get('likedCount', '0')} | Collects: {interact.get('collectedCount', '0')} | Comments: {interact.get('commentCount', '0')}")
            
            comment_list = comments.get("list", [])
            if comment_list:
                print(f"\n💬 Top Comments ({len(comment_list)}):")
                for c in comment_list[:5]:
                    user_info = c.get("userInfo", {})
                    print(f"  - {user_info.get('nickname', 'Anonymous')}: {c.get('content', '')}")
        else:
            print(f"❌ Failed to get details: {data.get('error', 'Unknown error')}")
        
        return data
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to MCP server.")
        sys.exit(1)


def get_feeds():
    """Get recommended feed list."""
    try:
        resp = requests.get(f"{BASE_URL}/api/v1/feeds/list", timeout=TIMEOUT)
        data = resp.json()
        
        if data.get("success"):
            feeds = data.get("data", {}).get("feeds", [])
            print(f"📋 Recommended Feeds ({len(feeds)} notes):\n")
            
            for i, feed in enumerate(feeds, 1):
                note_card = feed.get("noteCard", {})
                user = note_card.get("user", {})
                interact = note_card.get("interactInfo", {})
                
                print(f"[{i}] {note_card.get('displayTitle', 'No title')}")
                print(f"    Author: {user.get('nickname', 'Unknown')}")
                print(f"    Likes: {interact.get('likedCount', '0')}")
                print()
        else:
            print(f"❌ Failed to get feeds: {data.get('error', 'Unknown error')}")
        
        return data
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to MCP server.")
        sys.exit(1)


def publish_note(title, content, images, tags=None):
    """Publish a new note."""
    try:
        payload = {
            "title": title,
            "content": content,
            "images": images if isinstance(images, list) else [images]
        }
        if tags:
            payload["tags"] = tags if isinstance(tags, list) else [tags]
        
        resp = requests.post(
            f"{BASE_URL}/api/v1/publish",
            json=payload,
            timeout=120
        )
        data = resp.json()
        
        if data.get("success"):
            print(f"✅ Note published successfully!")
            print(f"   Post ID: {data.get('data', {}).get('post_id', 'Unknown')}")
        else:
            print(f"❌ Publish failed: {data.get('error', 'Unknown error')}")
        
        return data
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to MCP server.")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="Xiaohongshu MCP Client",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    # status command
    subparsers.add_parser("status", help="Check login status")
    
    # search command
    search_parser = subparsers.add_parser("search", help="Search notes")
    search_parser.add_argument("keyword", help="Search keyword")
    search_parser.add_argument("--sort", default="Relevance", 
                               choices=["Relevance", "Newest", "Most liked", "Most commented", "Most saved"],
                               help="Sort by")
    search_parser.add_argument("--type", default="Any",
                               choices=["Any", "Video", "Image and text"],
                               help="Note type")
    search_parser.add_argument("--time", default="Any",
                               choices=["Any", "Within one day", "Within one week", "Within six months"],
                               help="Publish time")
    search_parser.add_argument("--json", action="store_true", help="Output raw JSON")
    
    # detail command
    detail_parser = subparsers.add_parser("detail", help="Get note details")
    detail_parser.add_argument("feed_id", help="Feed ID")
    detail_parser.add_argument("xsec_token", help="Security token")
    detail_parser.add_argument("--comments", action="store_true", help="Load all comments")
    detail_parser.add_argument("--json", action="store_true", help="Output raw JSON")
    
    # feeds command
    feeds_parser = subparsers.add_parser("feeds", help="Get recommended feeds")
    feeds_parser.add_argument("--json", action="store_true", help="Output raw JSON")
    
    # publish command
    publish_parser = subparsers.add_parser("publish", help="Publish a note")
    publish_parser.add_argument("title", help="Note title")
    publish_parser.add_argument("content", help="Note content")
    publish_parser.add_argument("images", help="Image URLs (comma-separated)")
    publish_parser.add_argument("--tags", help="Tags (comma-separated)")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        sys.exit(1)
    
    if args.command == "status":
        result = check_status()
    elif args.command == "search":
        result = search_notes(args.keyword, args.sort, args.type, args.time)
        if hasattr(args, 'json') and args.json:
            print(json.dumps(result, ensure_ascii=False, indent=2))
    elif args.command == "detail":
        result = get_note_detail(args.feed_id, args.xsec_token, args.comments)
        if hasattr(args, 'json') and args.json:
            print(json.dumps(result, ensure_ascii=False, indent=2))
    elif args.command == "feeds":
        result = get_feeds()
        if hasattr(args, 'json') and args.json:
            print(json.dumps(result, ensure_ascii=False, indent=2))
    elif args.command == "publish":
        images = args.images.split(",")
        tags = args.tags.split(",") if args.tags else None
        result = publish_note(args.title, args.content, images, tags)


if __name__ == "__main__":
    main()
