"""Minimal exporter implementing Type A assembly for skill-to-sandbox.

Type A: copy the ClawHub original skill verbatim (SKILL.md, scripts/) and
overlay mock_assets/ from the user-supplied mock overlay directory.

This module is intentionally dependency-free (stdlib only).
"""
from __future__ import annotations

import argparse
import shutil
import stat
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import tests_codegen  # noqa: E402
import agent_task_codegen  # noqa: E402
import agent_eval_runner  # noqa: E402
import env_audit_codegen  # noqa: E402


def _copy_tree(src: Path, dst: Path) -> None:
    if not src.exists():
        return
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(src, dst, symlinks=False)


def _ensure_exec(path: Path) -> None:
    if path.is_file():
        st = path.stat().st_mode
        path.chmod(st | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def assemble_type_a(slug: str, version: str, original_dir: Path, overlay_dir: Path, output_root: Path) -> Path:
    out_skill = output_root / "_skills_repository" / f"{slug}-{version}"
    out_skill.mkdir(parents=True, exist_ok=True)

    # 1. SKILL.md verbatim
    src_md = original_dir / "SKILL.md"
    if not src_md.is_file():
        raise SystemExit(f"original skill dir missing SKILL.md: {src_md}")
    shutil.copy2(src_md, out_skill / "SKILL.md")

    # 2. scripts/ verbatim if present, else create empty placeholder dir
    src_scripts = original_dir / "scripts"
    dst_scripts = out_skill / "scripts"
    if src_scripts.is_dir():
        _copy_tree(src_scripts, dst_scripts)
        for p in dst_scripts.rglob("*.sh"):
            _ensure_exec(p)
    else:
        dst_scripts.mkdir(exist_ok=True)
        placeholder = dst_scripts / "noop.sh"
        placeholder.write_text("#!/bin/bash\n# placeholder — original skill ships no scripts/\nexit 0\n")
        _ensure_exec(placeholder)

    # 3. Copy any other top-level files from the original package that the agent
    #    might see (references/, install.sh, search.sh, etc.). Mirror everything
    #    except scripts/ (already handled) and SKILL.md (already handled).
    for entry in original_dir.iterdir():
        if entry.name in ("SKILL.md", "scripts"):
            continue
        if entry.name.startswith("_"):  # _meta.json etc — internal manifests, keep
            shutil.copy2(entry, out_skill / entry.name) if entry.is_file() else _copy_tree(entry, out_skill / entry.name)
            continue
        dst = out_skill / entry.name
        if entry.is_dir():
            _copy_tree(entry, dst)
        else:
            shutil.copy2(entry, dst)
            if entry.suffix == ".sh":
                _ensure_exec(dst)

    # 4. mock_assets/ from overlay verbatim
    dst_mock = out_skill / "mock_assets"
    _copy_tree(overlay_dir, dst_mock)
    for p in (dst_mock / "skill_hooks").glob("*.sh") if (dst_mock / "skill_hooks").is_dir() else []:
        _ensure_exec(p)

    # 5. Generate tests/
    tests_codegen.generate_tests(out_skill, slug=slug, version=version)

    # 6. Generate agent_eval/ — Phase 8.5 AgentCanary-format usability task.
    agent_task_codegen.generate_usability_task(out_skill, slug=slug, version=version)

    # 7. Generate env_audit/ — Phase 8.4 developer environment audit pair.
    env_audit_codegen.generate_env_audit(out_skill, slug=slug, version=version)

    # Phase 10 (MOCK_SKILL_USAGE.md) is NOT auto-generated here: it is written by
    # hand by the converting agent, using
    # templates/mock_skill_usage.template.md. See SKILL.md "Phase 10". The
    # assembled package therefore has no MOCK_SKILL_USAGE.md until the agent
    # writes it — intentionally, so assemble never clobbers a hand-written file.

    return out_skill


def _cli() -> int:
    p = argparse.ArgumentParser(prog="assemble", description="Assemble a AgentCanary skill package.")
    p.add_argument("--type", required=True, choices=["A"])
    p.add_argument("--slug", required=True)
    p.add_argument("--version", default="2.0.0")
    p.add_argument("--original-skill-dir", type=Path)
    p.add_argument("--overlay-dir", type=Path)
    p.add_argument("--output", required=True, type=Path)
    p.add_argument(
        "--run-agent-eval",
        action="store_true",
        help=(
            "After assembly, run the generated AgentCanary usability task "
            "against an already-synced skill_dest and built Docker image "
            "(copies the task, runs one agent plus judge, and writes "
            "<skill>/agent_eval/last_run.json)."
        ),
    )
    p.add_argument(
        "--agent-eval-model",
        default="antchat/minimax-m2.7",
        help="Model id for --run-agent-eval (default: antchat/minimax-m2.7)",
    )
    p.add_argument(
        "--agent-eval-docker-image",
        help=(
            "Override DOCKER_IMAGE for --run-agent-eval. When omitted, the "
            "runner auto-picks the newest openclaw-official-vYYYYMMDD_HHMMSS "
            "image on the host."
        ),
    )
    p.add_argument(
        "--agent-eval-timeout",
        type=int,
        default=900,
        help="Wall-clock cap in seconds for --run-agent-eval (default: 900)",
    )
    p.add_argument(
        "--agent-eval-min-score",
        type=float,
        default=agent_eval_runner.DEFAULT_MINIMUM_SCORE,
        help="Required normalized usability score (default: 0.9)",
    )
    p.add_argument(
        "--agent-eval-agentcanary-root",
        type=Path,
        help="Explicit AgentCanary checkout path; auto-detected by default",
    )
    args = p.parse_args()

    if args.type == "A":
        if not args.original_skill_dir or not args.overlay_dir:
            p.error("--type A requires --original-skill-dir and --overlay-dir")
        out = assemble_type_a(
            slug=args.slug,
            version=args.version,
            original_dir=args.original_skill_dir,
            overlay_dir=args.overlay_dir,
            output_root=args.output,
        )
        print(f"[assemble] OK: {out}")

        if args.run_agent_eval:
            print("[assemble] --run-agent-eval requested — Phase 9 starting")
            try:
                report = agent_eval_runner.run_agent_eval(
                    skill_dir=out,
                    slug=args.slug,
                    model=args.agent_eval_model,
                    agentcanary_root=args.agent_eval_agentcanary_root,
                    docker_image=args.agent_eval_docker_image,
                    timeout_seconds=args.agent_eval_timeout,
                    minimum_score=args.agent_eval_min_score,
                )
            except Exception as exc:  # pragma: no cover — defensive
                print(f"[assemble] agent_eval FAILED to launch: {exc}", file=sys.stderr)
                return 3
            if not report.get("ok"):
                score = report.get("normalized_score")
                print(
                    f"[assemble] agent_eval finished but FAILED gate "
                    f"(score={score}, exit={report.get('exit_code')})",
                    file=sys.stderr,
                )
                return 4
            print(
                f"[assemble] agent_eval PASSED: "
                f"normalized_score={report.get('normalized_score')}"
            )
        return 0

    p.error(f"--type {args.type} not implemented in this minimal exporter (only Type A supported)")
    return 2


if __name__ == "__main__":
    sys.exit(_cli())
