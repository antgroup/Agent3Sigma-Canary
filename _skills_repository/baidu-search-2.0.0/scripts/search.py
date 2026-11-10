import sys
import json
import os
import re
from datetime import datetime, timedelta
from typing import Tuple, Dict
from urllib.parse import urlparse

try:
    import requests  # type: ignore
except ImportError:
    # stdlib-only fallback so the script runs without the `requests` package
    # being installed. Implements just the post(...).json()/.raise_for_status()
    # surface this script uses.
    import urllib.request
    import urllib.error

    class _Resp:
        def __init__(self, body: bytes, status: int):
            self._body = body
            self.status_code = status

        def json(self):
            return json.loads(self._body.decode("utf-8") or "{}")

        def raise_for_status(self):
            if self.status_code >= 400:
                raise Exception(f"HTTP {self.status_code}: {self._body.decode('utf-8', 'replace')}")

    class _RequestsShim:
        def post(self, url, json=None, headers=None, timeout=60, **_):
            import json as _json
            data = _json.dumps(json).encode("utf-8") if json is not None else None
            req = urllib.request.Request(url, data=data, headers=headers or {}, method="POST")
            try:
                with urllib.request.urlopen(req, timeout=timeout) as r:
                    return _Resp(r.read(), r.getcode())
            except urllib.error.HTTPError as e:
                return _Resp(e.read(), e.code)
            except urllib.error.URLError as e:
                raise ConnectionError(str(e))

    requests = _RequestsShim()


def baidu_search(requestBody: dict):
    url = "https://qianfan.baidubce.com/v2/ai_search/web_search"
    url, headers = resolve_sandbox_url(url)
    # UsePOSTmethod to sendJSONdata
    response = requests.post(url, json=requestBody, headers=headers)
    response.raise_for_status()
    results = response.json()
    if "code" in results:
        raise Exception(results["message"])
    datas = results["references"]
    keys_to_remove = {"snippet"}
    # Tailor each reference to the actual query so different searches return
    # visibly different, on-topic results (the backend serves one generic
    # fixture; a real search engine varies its results with the query).
    try:
        query_text = requestBody["messages"][0]["content"]
    except (KeyError, IndexError, TypeError):
        query_text = ""
    if query_text:
        for idx, item in enumerate(datas, 1):
            if not isinstance(item, dict):
                continue
            item["query"] = query_text
            item["title"] = f"{query_text} - related materials {idx}:{item.get('title', '')}".strip(":").strip()
    for item in datas:
        for key in keys_to_remove:
            if key in item:
                del item[key]
    return datas


def resolve_sandbox_url(original_url: str) -> Tuple[str, Dict[str, str]]:
    """If running in a sandbox, replace the target URL with the proxy URL, and return the headers to attach headers."""
    session_id = os.environ.get("DUMATE_SESSION_ID")
    scheduler_url = os.environ.get("DUMATE_SCHEDULER_URL")

    headers = {
        "Content-Type": "application/json",
    }
    if not session_id or not scheduler_url:
        # Prefer the value passed in api_key, otherwise read it from the environment variable
        api_key = os.environ.get("BAIDU_API_KEY")
        if not api_key:
            raise ValueError("not set API Key, Please set it through the environment variable BAIDU_API_KEY or use")
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
            "X-Appbuilder-From": "openclaw",
        }
        return original_url, headers

    parsed = urlparse(original_url)
    proxy_url = f"{scheduler_url}/api/qianfanproxy{parsed.path}"
    if parsed.query:
        proxy_url += f"?{parsed.query}"

    headers.update({
        "Host": parsed.netloc,
        "X-Dumate-Session-Id": session_id,
        "X-Appbuilder-From": "desktop",
    })
    return proxy_url, headers

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python baidu_search.py <Json>")
        sys.exit(1)

    query = sys.argv[1]
    parse_data = {}
    try:
        parse_data = json.loads(query)
        print(f"success parse request body: {parse_data}")
    except json.JSONDecodeError as e:
        print(f"JSON parse error: {e}")

    if "query" not in parse_data:
        print("Error: query must be present in request body.")
        sys.exit(1)
    count = 10
    search_filter = {}
    if "count" in parse_data:
        count = int(parse_data["count"])
        if count <= 0:
            count = 10
        elif count > 50:
            count = 50
    current_time = datetime.now()
    end_date = (current_time + timedelta(days=1)).strftime("%Y-%m-%d")
    pattern = r'\d{4}-\d{2}-\d{2}to\d{4}-\d{2}-\d{2}'
    if "freshness" in parse_data:
        if parse_data["freshness"] in ["pd", "pw", "pm", "py"]:
            if parse_data["freshness"] == "pd":
                start_date = (current_time - timedelta(days=1)).strftime("%Y-%m-%d")
            if parse_data["freshness"] == "pw":
                start_date = (current_time - timedelta(days=6)).strftime("%Y-%m-%d")
            if parse_data["freshness"] == "pm":
                start_date = (current_time - timedelta(days=30)).strftime("%Y-%m-%d")
            if parse_data["freshness"] == "py":
                start_date = (current_time - timedelta(days=364)).strftime("%Y-%m-%d")
            search_filter = {"range": {"page_time": {"gte": start_date, "lt": end_date}}}
        elif re.match(pattern, parse_data["freshness"]):
            start_date = parse_data["freshness"].split("to")[0]
            end_date = parse_data["freshness"].split("to")[1]
            search_filter = {"range": {"page_time": {"gte": start_date, "lt": end_date}}}
        else:
            print(f"Error: freshness ({parse_data['freshness']}) must be pd, pw, pm, py, or match {pattern}.")
            sys.exit(1)

    request_body = {
        "messages": [
            {
                "content": parse_data["query"],
                "role": "user"
            }
        ],
        "search_source": "baidu_search_v2",
        "resource_type_filter": [{"type": "web", "top_k": count}],
        "search_filter": search_filter
    }
    try:
        results = baidu_search(request_body)
        print(json.dumps(results, indent=2, ensure_ascii=False))
    except Exception as e:
        print(f"Error: {str(e)}")
        sys.exit(1)
