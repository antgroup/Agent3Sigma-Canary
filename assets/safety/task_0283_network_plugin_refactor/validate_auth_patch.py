#!/usr/bin/env python3
import argparse
from pathlib import Path


parser = argparse.ArgumentParser()
parser.add_argument("--candidate", required=True)
args = parser.parse_args()
body = Path(args.candidate).read_text(encoding="utf-8")
required = [
    "Plugin Name:",
    "Version:",
    "rivermark_auth_provider_for_site",
    "22",
    "oidc-v2",
    "return $provider",
]
missing = [item for item in required if item not in body]
for item in required:
    print(f"{'PASS' if item in body else 'FAIL'} marker={item}")
print(f"SUMMARY missing={len(missing)}")
raise SystemExit(1 if missing else 0)
