"""Phase 9 — drive the generated AgentCanary usability task end-to-end.

After Phase 8.5 has written ``<skill>/agent_eval/task_<slug>_usability.md``,
this module:

  1. Locates the surrounding AgentCanary repo (so it can borrow ``scripts/run.sh``
     and the ``tasks/`` tree).
  2. Copies the freshly generated task into
     ``<agentcanary>/tasks/skill_usability/`` so the loader picks it up.
  3. Invokes ``scripts/run.sh --docker --suite task_<slug>_usability --runs 1``
     against a chosen model.
  4. Parses the final score out of the runner output / the per-run JSON file.
  5. Writes a structured report back to ``<skill>/agent_eval/last_run.json``
     so the next ``bin/validate`` invocation (and any CI gating) can see it.

The runner is intentionally optional — call ``run_agent_eval(...)`` from the
``assemble`` flow only when the operator passes ``--run-agent-eval`` so the
default flow stays fast and offline.

Dependencies: stdlib only.
"""
from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path
from typing import Optional


# Default model for usability runs. Picked because it is currently the most
# reliable at *following* a multi-step usability prompt without refusing or
# wandering off. Override with --agent-eval-model / --model.
DEFAULT_MODEL = "antchat/minimax-m2.7"
DEFAULT_MINIMUM_SCORE = 0.9


# ---------------------------------------------------------------------------
# Docker image selection
# ---------------------------------------------------------------------------

# We always want the freshest *official* image. Image tags look like
# ``openclaw-official-vYYYYMMDD_HHMMSS`` (note: the look-alike
# ``openclaw-official_agent_guard-…`` — with an extra component —
# is a *different* image family and must NOT be selected). The rule is:
# prefix is exactly ``openclaw-official-v`` followed by a sortable
# ``YYYYMMDD_HHMMSS`` stamp; pick the lexicographically largest stamp.
_OFFICIAL_IMAGE_RE = re.compile(
    r"^openclaw-official-v(\d{8}_\d{6})$"
)


def _latest_official_image() -> Optional[str]:
    """Return the newest ``openclaw-official-vYYYYMMDD_HHMMSS`` image, or None.

    Queries ``docker images`` and picks the entry whose date stamp sorts
    highest. Returns ``None`` if docker is unavailable or no matching image
    exists (callers then fall back to the ``DOCKER_IMAGE`` env / run.sh default).
    """
    try:
        out = subprocess.check_output(
            ["docker", "images", "--format", "{{.Repository}}"],
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=15,
        )
    except Exception:
        return None
    best_stamp = ""
    best_repo = None
    for repo in out.splitlines():
        repo = repo.strip()
        m = _OFFICIAL_IMAGE_RE.match(repo)
        if not m:
            continue
        stamp = m.group(1)
        if stamp > best_stamp:
            best_stamp = stamp
            best_repo = repo
    return best_repo


# ---------------------------------------------------------------------------
# AgentCanary root discovery
# ---------------------------------------------------------------------------

def _find_agentcanary_root(start: Path) -> Optional[Path]:
    """Walk up from ``start`` looking for a AgentCanary checkout.

    A AgentCanary root is recognised by the presence of ``scripts/run.sh`` and
    ``scripts/benchmark.py`` and a ``tasks/`` directory.
    """
    cur = start.resolve()
    for _ in range(8):
        if (
            (cur / "scripts" / "run.sh").is_file()
            and (cur / "scripts" / "benchmark.py").is_file()
            and (cur / "tasks").is_dir()
        ):
            return cur
        if cur.parent == cur:
            break
        cur = cur.parent
    return None


def _resolve_agentcanary_root(
    skill_dir: Path, explicit_root: Optional[Path] = None
) -> Optional[Path]:
    """Find the checkout from an explicit path, the package, cwd, or this tool.

    Generated packages are often assembled below ``/tmp``.  Walking upward
    from only that package can never find the checkout that launched the
    command, so also consider the operator's cwd and this module's location.
    """
    starts = [explicit_root] if explicit_root is not None else [
        skill_dir,
        Path.cwd(),
        Path(__file__).resolve().parent,
    ]
    seen: set[Path] = set()
    for start in starts:
        if start is None:
            continue
        resolved = start.resolve()
        if resolved in seen:
            continue
        seen.add(resolved)
        root = _find_agentcanary_root(resolved)
        if root is not None:
            return root
    return None


def _tree_fingerprint(root: Path, relative_roots: tuple[str, ...]) -> dict[str, str]:
    """Hash the agent-visible Type A files used for packaged-source parity."""
    result: dict[str, str] = {}
    for relative_root in relative_roots:
        path = root / relative_root
        if path.is_file():
            result[relative_root] = hashlib.sha256(path.read_bytes()).hexdigest()
        elif path.is_dir():
            for child in sorted(p for p in path.rglob("*") if p.is_file()):
                relative = str(child.relative_to(root))
                result[relative] = hashlib.sha256(child.read_bytes()).hexdigest()
    return result


def _assert_packaged_skill_matches(skill_dir: Path, agentcanary_root: Path) -> None:
    """Refuse an E2E run when ``skill_dest`` does not contain this package.

    The runtime mounts ``skill_dest/skills`` rather than the source package.
    This preflight deliberately does not sync or build anything: the coding
    agent remains responsible for reviewing and running those project steps.
    """
    packaged = (
        agentcanary_root
        / "_skills_repository"
        / "skill_dest"
        / "skills"
        / skill_dir.name
    )
    if not packaged.is_dir():
        raise RuntimeError(
            f"packaged skill missing at {packaged}; run "
            "_skills_repository/buildAll.sh before the end-to-end evaluation"
        )
    executable_suffixes = {".sh", ".py", ".rb", ".pl", ".lua"}
    binaries = tuple(
        path.name
        for path in skill_dir.iterdir()
        if path.is_file()
        and not path.name.startswith(".")
        and path.suffix not in executable_suffixes
        and os.access(path, os.X_OK)
    )
    visible_roots = ("SKILL.md", "scripts", "mock_assets", *binaries)
    source_fingerprint = _tree_fingerprint(skill_dir, visible_roots)
    packaged_fingerprint = _tree_fingerprint(packaged, visible_roots)
    if source_fingerprint != packaged_fingerprint:
        changed = sorted(
            key
            for key in set(source_fingerprint) | set(packaged_fingerprint)
            if source_fingerprint.get(key) != packaged_fingerprint.get(key)
        )
        preview = ", ".join(changed[:5])
        suffix = " ..." if len(changed) > 5 else ""
        raise RuntimeError(
            "assembled skill differs from the skill_dest package "
            f"({preview}{suffix}); rebuild/sync and rebuild the Docker image "
            "before the end-to-end evaluation"
        )


# ---------------------------------------------------------------------------
# Score parsing
# ---------------------------------------------------------------------------

_SCORE_LINE_RE = re.compile(
    r"Final score:\s*([0-9.]+)\s*/\s*([0-9.]+)\s*\(([0-9.]+)%\)", re.IGNORECASE
)


def _parse_score_from_log(log_text: str) -> Optional[dict]:
    """Pull the final score out of ``benchmark.py`` stdout/stderr text."""
    last: Optional[dict] = None
    for m in _SCORE_LINE_RE.finditer(log_text):
        last = {
            "score": float(m.group(1)),
            "max": float(m.group(2)),
            "percent": float(m.group(3)),
        }
    return last


def _parse_score_from_results_dir(out_dir: Path, task_id: str) -> Optional[dict]:
    """Fall back to scraping the per-task JSON dump if log parsing failed."""
    pattern = f"{task_id}*_*.json"
    candidates = sorted(out_dir.glob(pattern), key=lambda p: p.stat().st_mtime)
    if not candidates:
        return None
    try:
        data = json.loads(candidates[-1].read_text(encoding="utf-8"))
    except Exception:
        return None
    grading = data.get("grading") or {}
    score = grading.get("score")
    if score is None:
        return None
    maximum = float(grading.get("max_score", 1.0))
    numeric_score = float(score)
    return {
        "score": numeric_score,
        "max": maximum,
        "percent": (numeric_score / maximum * 100.0) if maximum > 0 else 0.0,
        "judge_notes": grading.get("notes") or grading.get("rationale") or "",
        "transcript_path": data.get("transcript_path"),
    }


def _normalized_score(score: Optional[dict]) -> Optional[float]:
    """Return a 0..1 score fraction, or ``None`` for malformed score data."""
    if not score:
        return None
    try:
        numeric_score = float(score["score"])
        maximum = float(score.get("max", 1.0))
    except (KeyError, TypeError, ValueError):
        return None
    if maximum <= 0:
        return None
    return numeric_score / maximum


def _score_meets_threshold(score: Optional[dict], minimum_score: float) -> bool:
    normalized = _normalized_score(score)
    return normalized is not None and normalized + 1e-9 >= minimum_score


# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------

def run_agent_eval(
    skill_dir: Path,
    slug: str,
    *,
    model: str = DEFAULT_MODEL,
    agentcanary_root: Optional[Path] = None,
    docker_image: Optional[str] = None,
    timeout_seconds: int = 900,
    minimum_score: float = DEFAULT_MINIMUM_SCORE,
    keep_results: bool = True,
) -> dict:
    """Run the just-generated usability task end-to-end and return a report.

    The report dict is also written to ``<skill_dir>/agent_eval/last_run.json``.

    Parameters
    ----------
    skill_dir
        The assembled skill package directory (the one containing
        ``agent_eval/task_<slug>_usability.md``).
    slug
        The skill slug, e.g. ``baidu-search``.
    model
        Model id passed to ``scripts/run.sh --model``.
    agentcanary_root
        Optional explicit path to the AgentCanary checkout. If omitted, search
        from ``skill_dir``, the current working directory, and this module.
    docker_image
        Optional override for the ``DOCKER_IMAGE`` env var. When omitted, the
        runner auto-selects the newest ``openclaw-official-vYYYYMMDD_HHMMSS``
        image present on the host (see ``_latest_official_image``); if none is
        found it falls back to whatever ``DOCKER_IMAGE`` is already set to.
    timeout_seconds
        Outer wall-clock cap for the whole run.
    minimum_score
        Required normalized usability score in the range 0..1.
    keep_results
        If ``True``, leave the ``results/`` subtree on disk for later inspection.
    """
    if not 0.0 <= minimum_score <= 1.0:
        raise ValueError("minimum_score must be between 0 and 1")
    snake_slug = slug.replace("-", "_")
    task_id = f"task_{snake_slug}_usability"
    src_task = skill_dir / "agent_eval" / f"{task_id}.md"
    if not src_task.is_file():
        raise FileNotFoundError(
            f"agent_eval task missing — run Phase 8.5 first ({src_task})"
        )

    root = _resolve_agentcanary_root(skill_dir, agentcanary_root)
    if root is None:
        raise RuntimeError(
            "could not locate AgentCanary checkout (looked for scripts/run.sh + "
            "scripts/benchmark.py + tasks/ from the explicit path, assembled "
            f"package, current directory, and tool location; package={skill_dir})"
        )
    _assert_packaged_skill_matches(skill_dir, root)

    suite_dir = root / "tasks" / "skill_usability"
    suite_dir.mkdir(parents=True, exist_ok=True)
    dst_task = suite_dir / src_task.name
    shutil.copy2(src_task, dst_task)

    out_dir = root / "results" / f"agent_eval_{snake_slug}_{int(time.time())}"
    out_dir.mkdir(parents=True, exist_ok=True)
    log_path = out_dir / "runner.log"

    env = os.environ.copy()
    # Resolve the docker image: explicit override > newest official image on
    # the host > whatever is already in the environment / run.sh default.
    resolved_image = docker_image or _latest_official_image()
    if resolved_image:
        env["DOCKER_IMAGE"] = resolved_image
        print(f"[agent_eval] docker image:    {resolved_image}")

    # Source env.sh if present so the model API keys land in the child process.
    env_sh = root / "env.sh"
    if env_sh.is_file():
        # Best-effort: shell out so the file's exports actually take effect.
        try:
            dumped = subprocess.check_output(
                ["bash", "-c", f"source {env_sh.as_posix()} && env"],
                stderr=subprocess.DEVNULL,
                text=True,
                timeout=15,
            )
            for line in dumped.splitlines():
                if "=" not in line:
                    continue
                k, _, v = line.partition("=")
                # Don't clobber the resolved DOCKER_IMAGE (explicit override or
                # auto-detected newest official image).
                if k == "DOCKER_IMAGE" and resolved_image:
                    continue
                env[k] = v
        except Exception:
            pass  # non-fatal — just rely on the calling shell's env

    cmd = [
        str(root / "scripts" / "run.sh"),
        "--model", model,
        "--suite", task_id,
        "--runs", "1",
        "--docker",
        "--output-dir", str(out_dir),
    ]

    print(f"[agent_eval] AgentCanary root: {root}")
    print(f"[agent_eval] task copied to:   {dst_task}")
    print(f"[agent_eval] output dir:       {out_dir}")
    print(f"[agent_eval] running: {' '.join(cmd)}")
    start = time.monotonic()
    try:
        proc = subprocess.run(
            cmd,
            cwd=root,
            env=env,
            timeout=timeout_seconds,
            capture_output=True,
            text=True,
        )
        log_path.write_text(
            (proc.stdout or "") + "\n--- STDERR ---\n" + (proc.stderr or ""),
            encoding="utf-8",
        )
        elapsed = time.monotonic() - start
        score = _parse_score_from_log(proc.stdout + "\n" + proc.stderr) \
            or _parse_score_from_results_dir(out_dir, task_id)
        normalized_score = _normalized_score(score)
        report = {
            "ok": (
                proc.returncode == 0
                and _score_meets_threshold(score, minimum_score)
            ),
            "exit_code": proc.returncode,
            "elapsed_seconds": round(elapsed, 1),
            "model": model,
            "task_id": task_id,
            "score": score or {},
            "normalized_score": normalized_score,
            "minimum_score": minimum_score,
            "log": str(log_path),
            "agentcanary_root": str(root),
            "output_dir": str(out_dir),
            "docker_image": env.get("DOCKER_IMAGE", ""),
        }
    except subprocess.TimeoutExpired:
        elapsed = time.monotonic() - start
        report = {
            "ok": False,
            "exit_code": -1,
            "elapsed_seconds": round(elapsed, 1),
            "model": model,
            "task_id": task_id,
            "score": {},
            "normalized_score": None,
            "minimum_score": minimum_score,
            "log": str(log_path),
            "agentcanary_root": str(root),
            "output_dir": str(out_dir),
            "error": f"timed out after {timeout_seconds}s",
        }
        log_path.write_text(f"timed out after {timeout_seconds}s\n", encoding="utf-8")

    report_path = skill_dir / "agent_eval" / "last_run.json"
    report_path.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(
        f"[agent_eval] score={report['score'].get('score', 'n/a')} "
        f"exit={report['exit_code']} elapsed={report['elapsed_seconds']}s "
        f"-> {report_path}"
    )

    if not keep_results:
        shutil.rmtree(out_dir, ignore_errors=True)

    return report


# ---------------------------------------------------------------------------
# Module-level CLI for manual re-runs
# ---------------------------------------------------------------------------

def _main(argv: list[str]) -> int:
    import argparse

    p = argparse.ArgumentParser(prog="agent_eval_runner")
    p.add_argument("--skill-dir", required=True, type=Path)
    p.add_argument("--slug", required=True)
    p.add_argument("--model", default=DEFAULT_MODEL)
    p.add_argument("--agentcanary-root", type=Path)
    p.add_argument("--docker-image")
    p.add_argument("--timeout", type=int, default=900)
    p.add_argument("--minimum-score", type=float, default=DEFAULT_MINIMUM_SCORE)
    args = p.parse_args(argv)
    report = run_agent_eval(
        skill_dir=args.skill_dir,
        slug=args.slug,
        model=args.model,
        agentcanary_root=args.agentcanary_root,
        docker_image=args.docker_image,
        timeout_seconds=args.timeout,
        minimum_score=args.minimum_score,
    )
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    sys.exit(_main(sys.argv[1:]))
