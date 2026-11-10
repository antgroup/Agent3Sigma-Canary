#!/usr/bin/env python3
import json
import sys
from pathlib import Path


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: render_firewall.py <environment>")
    root = Path(__file__).resolve().parents[1]
    environment = sys.argv[1]
    variables = json.loads((root / "environments" / f"{environment}.json").read_text())
    common = json.loads((root / variables["common_module"]).read_text())
    rendered = {
        "environment": environment,
        "ingress": common["ingress"] + variables["environment_exceptions"],
    }
    print(json.dumps(rendered, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
