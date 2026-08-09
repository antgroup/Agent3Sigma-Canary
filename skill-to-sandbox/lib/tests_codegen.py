"""Render templates/tests/*.template into <skill>/tests/.

Parameters are inferred from the assembled skill package (CLI name from
mock_assets/bin/, expected domains from api_handlers/*.json, lifecycle
keywords from scripts/install.sh + scripts/login.sh, subcommands grepped
from the CLI source).
"""
from __future__ import annotations

import json
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
TEMPLATE_DIR = HERE.parent / "templates" / "tests"

INSTALL_KEYWORDS = ["已安装", "已存在", "已经安装", "already installed", "already in PATH"]
LOGIN_KEYWORDS = ["已登录", "已认证", "already logged in", "already authenticated"]


def _read_template(name: str) -> str:
    p = TEMPLATE_DIR / name
    return p.read_text(encoding="utf-8")


def _infer_cli_name(skill_dir: Path, slug: str) -> str:
    bin_dir = skill_dir / "mock_assets" / "bin"
    if not bin_dir.is_dir():
        return ""
    candidates = [p for p in bin_dir.iterdir() if p.is_file()]
    if not candidates:
        return ""
    for c in candidates:
        if c.name.startswith(slug.split("-")[0]):
            return c.name
    return candidates[0].name


def _infer_domains(skill_dir: Path) -> list[str]:
    handlers = skill_dir / "mock_assets" / "api_handlers"
    if not handlers.is_dir():
        return []
    out = []
    for f in sorted(handlers.glob("*.json")):
        try:
            data = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        d = data.get("domain")
        if d:
            out.append(d)
    return out


def _grep_first(path: Path, needles: list[str]) -> str:
    if not path.is_file():
        return ""
    text = path.read_text(encoding="utf-8", errors="replace")
    for needle in needles:
        if needle in text:
            return needle
    return ""


def _infer_subcommands(cli_path: Path) -> list[str]:
    if not cli_path.is_file():
        return []
    text = cli_path.read_text(encoding="utf-8", errors="replace")
    return re.findall(r"add_parser\(['\"]([a-zA-Z0-9_-]+)['\"]", text)


def _substitute(text: str, **subs) -> str:
    for k, v in subs.items():
        text = text.replace(f"__{k.upper()}__", v)
    return text


def generate_tests(skill_dir: Path, slug: str, version: str) -> None:
    tests_dir = skill_dir / "tests"
    tests_dir.mkdir(exist_ok=True)

    cli_name = _infer_cli_name(skill_dir, slug)
    domains = _infer_domains(skill_dir)
    domains_json = json.dumps(domains)

    install_kw = _grep_first(skill_dir / "scripts" / "install.sh", INSTALL_KEYWORDS)
    login_kw = _grep_first(skill_dir / "scripts" / "login.sh", LOGIN_KEYWORDS)

    cli_source = (skill_dir / "mock_assets" / "bin" / cli_name) if cli_name else None
    subcommands = _infer_subcommands(cli_source) if cli_source else []
    subcommands_json = json.dumps(subcommands)

    common_subs = dict(
        slug=slug,
        version=version,
        cli_name=cli_name,
        cli_upper=cli_name.upper().replace("-", "_") if cli_name else "",
        expected_domains=domains_json,
        install_keyword=install_kw,
        login_keyword=login_kw,
        subcommands=subcommands_json,
    )

    # Always-rendered tests
    for tpl_name, out_name in (
        ("__init__.py.template", "__init__.py"),
        ("test_audit.py.template", "test_audit.py"),
        ("test_api_handlers.py.template", "test_api_handlers.py"),
        ("test_hooks.py.template", "test_hooks.py"),
        ("test_lifecycle.py.template", "test_lifecycle.py"),
    ):
        try:
            tpl = _read_template(tpl_name)
        except FileNotFoundError:
            continue
        rendered = _substitute(tpl, **common_subs)
        (tests_dir / out_name).write_text(rendered, encoding="utf-8")

    # Only render test_cli.py if a CLI ships under mock_assets/bin/
    if cli_name:
        try:
            tpl = _read_template("test_cli.py.template")
            (tests_dir / "test_cli.py").write_text(_substitute(tpl, **common_subs), encoding="utf-8")
        except FileNotFoundError:
            pass
