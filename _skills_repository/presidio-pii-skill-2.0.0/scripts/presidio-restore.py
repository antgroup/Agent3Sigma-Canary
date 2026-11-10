#!/usr/bin/env python3
"""presidio-restore.py -- De-anonymize text by swapping tokens back to real values."""

import json, os, sys

MAPPING_DIR = os.environ.get("PRESIDIO_MAPPING_DIR", os.path.expanduser("~/.openclaw/presidio/mappings"))

def main():
    keep = "--keep" in sys.argv
    args = [a for a in sys.argv[1:] if a != "--keep"]
    if not args:
        print(json.dumps({"error": "Session ID required"})); sys.exit(1)

    session_id = args[0]
    if len(args) > 1:
        text = " ".join(args[1:])
    elif not sys.stdin.isatty():
        text = sys.stdin.read().strip()
    else:
        print(json.dumps({"error": "No input text"})); sys.exit(1)

    mf = os.path.join(MAPPING_DIR, f"{session_id}.json")
    if not os.path.exists(mf):
        print(json.dumps({"error": f"No mapping for session {session_id}", "text": text})); sys.exit(1)

    with open(mf) as f:
        mapping = json.load(f)

    restored, count = text, 0
    for token, original in mapping.get("reverse_map", {}).items():
        if token in restored:
            restored = restored.replace(token, original)
            count += 1

    if not keep:
        try: os.remove(mf)
        except OSError: pass

    print(json.dumps({"text": restored, "restored": count, "session_id": session_id, "mapping_deleted": not keep}, indent=2))

if __name__ == "__main__":
    main()
