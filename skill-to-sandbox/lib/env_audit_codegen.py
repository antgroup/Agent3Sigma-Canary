"""Phase 8.4 — generate a sandbox environment audit / remediation pair.

Goals
=====
Usability tasks should test whether the **skill itself** works in a real-user
flow. They should *not* be papered over with prompt scaffolding ("don't ask
the user for tokens", "use this curl", "don't start gateway"…). When a real
agent struggles, the culprit is almost always one of:

  1. Required env var not actually exported into the agent shell
     (e.g. `/etc/profile.d/*.sh` only runs in login shells; `bash -c` does not).
  2. Required service (e.g. ``openclaw gateway``) not started by any hook.
  3. CA cert installed under ``/etc/ssl/certs/`` but not wired into Node's
     trust store (``NODE_EXTRA_CA_CERTS`` unset).
  4. A binary the skill calls (e.g. ``openclaw discord …``) requires a
     bot token check that rejects placeholders before hitting the mock.

This module emits two siblings per skill:

* ``env_audit/check_environment.sh`` — runs in the agent's container and
  prints PASS/FAIL for each expected piece of environment scaffolding.
  Returns non-zero on any failure so it can gate the Phase 9 run.
* ``env_audit/fix_environment.sh`` — a developer remediation aid. It persists
  env vars for processes launched by the container runtime after a restart,
  wires ``NODE_EXTRA_CA_CERTS``, and starts the gateway if needed. A child
  script cannot mutate the already-running agent's parent environment, so the
  coding agent must integrate the equivalent settings into the image/hook and
  restart the affected process before treating the audit as fixed.

The set of checks is derived from the assembled skill itself:

* every ``mock_assets/skill_hooks/*.sh`` that mentions ``export FOO=`` →
  add a "FOO is non-empty in plain shell" check + a fix that re-exports it
  via ``/etc/environment``.
* every ``api_handlers/*.json`` with a non-empty ``domain`` →
  add a "DNS / certificate works for HTTPS GET https://<domain>/" check.
* if any handler ``domain`` is ``discord.com`` / ``slack.com`` / similar
  OpenClaw-channel-backed service →
  add a "openclaw gateway is reachable" check + a fix that starts it
  with --force and waits up to 15s.

Dependency-free (stdlib only).
"""
from __future__ import annotations

import json
import re
from pathlib import Path

# Skills whose ClawHub SKILL.md instructs callers to use OpenClaw's built-in
# channel plugin (``openclaw <channel> …`` / ``openclaw message --channel
# <channel> …``) rather than a self-contained CLI. These need a running
# gateway *and* the channel token registered in openclaw's config, not just
# a process env var.
_OPENCLAW_CHANNEL_SKILLS = {
    "discord": {
        "channel": "discord",
        "token_env": "DISCORD_BOT_TOKEN",
        "config_path": "channels.discord.accounts.default.token",
    },
    "slack": {
        "channel": "slack",
        "token_env": "SLACK_BOT_TOKEN",
        "config_path": "channels.slack.accounts.default.token",
    },
    "telegram": {
        "channel": "telegram",
        "token_env": "TELEGRAM_BOT_TOKEN",
        "config_path": "channels.telegram.accounts.default.token",
    },
}

_EXPORT_RE = re.compile(r"^\s*export\s+([A-Z][A-Z0-9_]*)\s*=", re.MULTILINE)
# Captures vars exported indirectly via /etc/profile.d (hook writes the
# `export FOO=...` line into a file there). These are *exactly* the
# vars that fail to surface in a non-login `bash -c`, so we treat them
# as part of the audit's required set.
_PROFILED_EXPORT_RE = re.compile(
    r"['\"]\s*export\s+([A-Z][A-Z0-9_]*)\s*=", re.MULTILINE
)


def _collect_env_vars(skill_dir: Path) -> list[str]:
    hooks = skill_dir / "mock_assets" / "skill_hooks"
    if not hooks.is_dir():
        return []
    names: list[str] = []
    seen = set()
    for f in sorted(hooks.glob("*.sh")):
        text = f.read_text(encoding="utf-8", errors="replace")
        for regex in (_EXPORT_RE, _PROFILED_EXPORT_RE):
            for m in regex.finditer(text):
                n = m.group(1)
                if n in seen:
                    continue
                seen.add(n)
                names.append(n)
    return names


def _collect_domains(skill_dir: Path) -> list[str]:
    handlers = skill_dir / "mock_assets" / "api_handlers"
    if not handlers.is_dir():
        return []
    out: list[str] = []
    seen = set()
    for f in sorted(handlers.glob("*.json")):
        try:
            data = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        d = (data.get("domain") or "").strip()
        if d and d not in seen:
            seen.add(d)
            out.append(d)
    return out


def _channel_info(slug: str) -> dict | None:
    return _OPENCLAW_CHANNEL_SKILLS.get(slug)


def generate_env_audit(skill_dir: Path, slug: str, version: str) -> Path | None:
    """Write ``env_audit/check_environment.sh`` + ``fix_environment.sh``.

    Returns the path to ``check_environment.sh`` (or ``None`` if the skill
    has no detectable environment dependencies — empty audit would just add
    noise).
    """
    env_vars = _collect_env_vars(skill_dir)
    domains = _collect_domains(skill_dir)
    channel = _channel_info(slug)
    if not env_vars and not domains and channel is None:
        return None

    out_dir = skill_dir / "env_audit"
    out_dir.mkdir(exist_ok=True)
    check_path = out_dir / "check_environment.sh"
    fix_path = out_dir / "fix_environment.sh"

    # ---- check_environment.sh ---------------------------------------------
    lines: list[str] = [
        "#!/bin/bash",
        "# Auto-generated by skill-to-sandbox Phase 8.4.",
        f"# Sandbox environment audit for skill: {slug}-{version}",
        "# Exit 0 = all expected scaffolding present; non-zero = at least",
        "# one defect that will likely make the usability run fail.",
        "set -u",
        "",
        "FAIL=0",
        "PASS=0",
        'ok()   { PASS=$((PASS+1)); echo "  OK:   $1"; }',
        'fail() { FAIL=$((FAIL+1)); echo "  FAIL: $1"; }',
        "",
        f'echo "=== env audit: {slug}-{version} ==="',
        "",
    ]

    # 1) every export-style env var should be visible in a non-login bash
    if env_vars:
        lines.append('echo "[1] required env vars (must be visible to bash -c, not just login shells)"')
        for v in env_vars:
            lines.append(
                f'val=$(bash -c \'echo "${{{v}:-}}"\' 2>/dev/null)\n'
                f'if [ -n "$val" ]; then\n'
                f'    ok "{v} present in non-login shell"\n'
                f'else\n'
                f'    fail "{v} EMPTY in non-login shell (likely only in /etc/profile.d)"\n'
                f'fi'
            )
        lines.append("")

    # 2) every domain should be reachable + serve a valid cert that node accepts
    if domains:
        lines.append('echo "[2] mock backend reachability + TLS trust"')
        for d in domains:
            lines.append(
                f'if curl -s --max-time 5 -o /dev/null -w "%{{http_code}}" "https://{d}/" 2>/dev/null | grep -qE "^[2345]"; then\n'
                f'    ok "https://{d}/ reachable via host TLS trust"\n'
                f'else\n'
                f'    fail "https://{d}/ NOT reachable or TLS chain broken"\n'
                f'fi'
            )
            lines.append(
                f'if NODE_EXTRA_CA_CERTS=${{NODE_EXTRA_CA_CERTS:-/tmp/scry/mock_api/ssl/mock-api.crt}} node -e \\\n'
                f'    "fetch(\'https://{d}/\').then(r=>process.exit(r.status<500?0:1)).catch(()=>process.exit(2))" 2>/dev/null; then\n'
                f'    ok "node fetch trusts cert for https://{d}/"\n'
                f'else\n'
                f'    fail "node fetch DOES NOT trust cert for https://{d}/ (NODE_EXTRA_CA_CERTS not effective)"\n'
                f'fi'
            )
        lines.append("")

    # 3) openclaw gateway + channel registration when relevant
    if channel is not None:
        lines.append(f'echo "[3] openclaw gateway + {channel["channel"]} channel"')
        lines.append(
            'if curl -s --max-time 3 http://127.0.0.1:18789/health 2>/dev/null | grep -q "ok\\|alive\\|status"; then\n'
            '    ok "openclaw gateway responds on :18789"\n'
            'else\n'
            '    fail "openclaw gateway NOT running on :18789 (any \'openclaw <channel> …\' CLI will fail)"\n'
            'fi'
        )
        lines.append(
            f'if openclaw config get {channel["config_path"]} 2>/dev/null | grep -qv "^$"; then\n'
            f'    ok "openclaw config has {channel["config_path"]}"\n'
            f'else\n'
            f'    fail "openclaw config MISSING {channel["config_path"]} (channel CLI will reject)"\n'
            f'fi'
        )
        lines.append("")

    lines.append('if [ "$FAIL" -eq 0 ]; then')
    lines.append(f'    echo "=== ENV AUDIT PASS ($PASS checks) ==="')
    lines.append("    exit 0")
    lines.append("else")
    lines.append(f'    echo "=== ENV AUDIT FAIL ($FAIL of $((PASS+FAIL)) checks failed) ==="')
    lines.append("    exit 1")
    lines.append("fi")

    check_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    check_path.chmod(0o755)

    # ---- fix_environment.sh ----------------------------------------------
    fix_lines: list[str] = [
        "#!/bin/bash",
        "# Auto-generated by skill-to-sandbox Phase 8.4.",
        f"# Developer remediation aid for {slug}-{version}.",
        "# Run this inside a disposable development container. It cannot change",
        "# the environment of an already-running parent agent process. Integrate",
        "# the same settings into the image/hook, then restart the process before",
        "# using check_environment.sh as evidence.",
        "set -u",
        "",
    ]

    if env_vars:
        fix_lines.append('echo "[fix-1] persisting env vars for the next container/agent process"')
        for v in env_vars:
            fix_lines.append(
                f'val=""\n'
                f'for f in /etc/profile.d/*.sh; do\n'
                f'    [ -f "$f" ] || continue\n'
                f'    found=$(grep -E "^\\s*export\\s+{v}=" "$f" | tail -1 | sed -E "s/^\\s*export\\s+{v}=//; s/^\\\"//; s/\\\"$//; s/^\\x27//; s/\\x27$//")\n'
                f'    if [ -n "$found" ]; then val="$found"; fi\n'
                f'done\n'
                f'if [ -n "$val" ]; then\n'
                f'    sed -i "/^{v}=/d" /etc/environment 2>/dev/null || true\n'
                f'    echo "{v}=$val" >> /etc/environment\n'
                f'    printf "export {v}=%q\\n" "$val" > /etc/profile.d/agent-skill-{v}.sh\n'
                f'    echo "  -> {v} persisted (restart required for an existing agent)"\n'
                f'fi'
            )
        fix_lines.append("")

    if domains:
        fix_lines.append('echo "[fix-2] wiring NODE_EXTRA_CA_CERTS for future processes"')
        fix_lines.append(
            'CERT=/tmp/scry/mock_api/ssl/mock-api.crt\n'
            'if [ -f "$CERT" ]; then\n'
            '    sed -i "/^NODE_EXTRA_CA_CERTS=/d" /etc/environment 2>/dev/null || true\n'
            '    echo "NODE_EXTRA_CA_CERTS=$CERT" >> /etc/environment\n'
            '    printf "export NODE_EXTRA_CA_CERTS=%q\\n" "$CERT" > /etc/profile.d/agent-skill-node-ca.sh\n'
            '    echo "  -> NODE_EXTRA_CA_CERTS persisted (restart required for an existing agent)"\n'
            'fi'
        )
        fix_lines.append("")

    if channel is not None:
        ch = channel["channel"]
        cfg_path = channel["config_path"]
        token_env = channel["token_env"]
        fix_lines.append(f'echo "[fix-3] starting openclaw gateway + registering {ch} mock token"')
        fix_lines.append(
            'if ! curl -s --max-time 2 http://127.0.0.1:18789/health 2>/dev/null | grep -q "ok\\|alive\\|status"; then\n'
            '    nohup openclaw gateway --port 18789 --force >/var/log/openclaw-gateway.log 2>&1 &\n'
            '    for i in $(seq 1 15); do\n'
            '        sleep 1\n'
            '        if curl -s --max-time 1 http://127.0.0.1:18789/health 2>/dev/null | grep -q "ok\\|alive\\|status"; then break; fi\n'
            '    done\n'
            '    echo "  -> openclaw gateway start attempted"\n'
            'fi'
        )
        fix_lines.append(
            f'tok=$(bash -c \'echo "${{{token_env}:-}}"\')\n'
            f'if [ -n "$tok" ]; then\n'
            f'    openclaw config set {cfg_path} "\\\"$tok\\\"" --strict-json 2>/dev/null \\\n'
            f'        && echo "  -> openclaw {cfg_path} registered"\n'
            f'fi'
        )
        fix_lines.append("")

    fix_lines.append(
        'echo "[fix] done. Integrate these settings into the image/hook and restart "'
    )
    fix_lines.append(
        'echo "      the affected agent process before re-running the audit."'
    )

    fix_path.write_text("\n".join(fix_lines) + "\n", encoding="utf-8")
    fix_path.chmod(0o755)

    return check_path
