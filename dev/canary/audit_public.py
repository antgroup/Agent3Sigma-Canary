"""Scan Canary's public responses/assets; report locations, never matched values.

Run: .venv/bin/python dev/canary/audit_public.py
This is a pattern-based regression check, not a provider credential validator.
"""
import html
import json
from pathlib import Path
import re
import sys
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

RULES = {
    'provider token': r'\b(?:sk-(?:proj-|ant-api\d+-)?[A-Za-z0-9_-]{16,}|(?:gh[pousr]_|github_pat_)[A-Za-z0-9_]{20,}|(?:AKIA|ASIA)[A-Z0-9]{16}|AIza[A-Za-z0-9_-]{30,}|xox[baprs]-[A-Za-z0-9-]{15,})\b',
    'private key': r'-----BEGIN (?:RSA |EC |OPENSSH |DSA |ENCRYPTED )?PRIVATE KEY-----',
    'JWT': r'\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b',
    'authorization value': r'(?i)\b(?:Bearer|Basic)\s+[A-Za-z0-9+/_.=-]{12,}',
    'credential assignment': r'''(?i)["']?\b(?:api[_-]?key|access[_-]?token|auth[_-]?token|secret[_-]?key|client[_-]?secret|password|passwd)["']?\s*[:=]\s*["'][^"'\r\n]{8,}["']''',
    'URL credentials': r'https?://[^\s/:]+:[^\s/@]+@[^\s/]+',
    'URL access token': r'(?i)[?&](?:api[_-]?key|access[_-]?token|client[_-]?secret|signature|x-amz-signature)=[^&\s"<>]{8,}',
    'private network address': r'\b(?:10\.\d{1,3}\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3}|172\.(?:1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3})\b',
    'host filesystem path': r'/(?:home|mnt|Users|root)/[^\s"<>]+',
}
PATTERNS = {name: re.compile(pattern) for name, pattern in RULES.items()}
PUBLIC_ROUTES = (
    '/', '/platform', '/leaderboard', '/benchmark',
    '/platform/canary', '/benchmark/agent-canary',
    '/api/platform/canary/config', '/api/benchmark/agent-canary/config',
    '/api/benchmark/agent-canary/data', '/api/benchmark/agent-canary/data?download=1',
    '/api/leaderboard/config',
)
ASSET_ROOTS = ('shared', 'canary', 'benchmark/agent-canary', 'platform/canary')


def scan(text, location):
    text = html.unescape(unquote(text))
    return [{'location': location, 'line': text.count('\n', 0, match.start()) + 1, 'rule': name}
            for name, pattern in PATTERNS.items() for match in pattern.finditer(text)]


def public_surfaces(client):
    for route in PUBLIC_ROUTES:
        with client.get(route) as response:
            if response.status_code != 200:
                raise AssertionError(f'Public route failed: {route} ({response.status_code})')
            yield route, response.get_data(as_text=True)
    for directory in ASSET_ROOTS:
        for path in sorted((ROOT / 'app/static' / directory).rglob('*')):
            if path.is_file() and path.suffix in {'.js', '.css', '.svg', '.html', '.json', '.map'}:
                route = '/static/' + path.relative_to(ROOT / 'app/static').as_posix()
                with client.get(route) as response:
                    if response.status_code != 200:
                        raise AssertionError(f'Public asset failed: {route} ({response.status_code})')
                    yield route, response.get_data(as_text=True)


def audit(client):
    findings, count = [], 0
    for location, content in public_surfaces(client):
        findings.extend(scan(content, location))
        count += 1
    return {'surfaces_checked': count, 'findings': findings}


if __name__ == '__main__':
    from app import create_app
    result = audit(create_app().test_client())
    print(json.dumps(result, indent=2))
    raise SystemExit(bool(result['findings']))
