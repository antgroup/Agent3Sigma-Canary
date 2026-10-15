#!/usr/bin/env python3
"""
AgentCanary - OpenClaw Agent Benchmarking System

This script orchestrates benchmarking of OpenClaw agents using tasks loaded
from the tasks/ directory.
"""
from __future__ import annotations

# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "pyyaml>=6.0.1",
#     "openai>=1.0.0",
# ]
# ///

# Add project root to sys.path before any imports
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import argparse
import hashlib
import json
import logging
import os
import re
import statistics
import subprocess
import sys
import time
import traceback
import uuid
from pathlib import Path
from typing import Dict, List, Optional, Any

import lib_docker as docker
import lib_tracee as tracee
import tracee_correlate
from lib_tracee_grading import grade_tracee_correlation, TraceeGradingResult, generate_tracee_grading_report
from lib_agent import (
    cleanup_agent_sessions,
    ensure_agent_exists,
    execute_openclaw_task,
    slugify_model,
    _resolve_required_skills,
    _resolve_framework_skill_mounts,
    _strip_skill_version,
    _inject_skill_data,
)
from lib_attacks import get_attack_method, is_pair_attack, validate_attack_compatibility
from lib_grading import GradeResult, grade_task, make_ungraded_result
from lib_tasks import Task, TaskLoader
from lib_task_validation import missing_task_inputs


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler(sys.stdout), logging.FileHandler("benchmark.log")],
)

logger = logging.getLogger("benchmark")
REPO_ROOT = Path(__file__).resolve().parent.parent


class OpenClawAgent:
    """Scaffold for OpenClaw agent creation and execution."""

    def __init__(self, agent_id: str, config: Optional[Dict[str, Any]] = None):
        self.agent_id = agent_id
        self.config = config or {}
        logger.info(f"Initialized OpenClawAgent: {agent_id}")

    def execute_task(self, task: Task, simulate: bool = False) -> Dict[str, Any]:
        """
        Execute a task with this agent.

        Args:
            task: The Task object to execute
            simulate: If True, simulates execution for demonstration

        Returns:
            Dictionary containing execution results
        """
        if simulate:
            logger.info("Simulate flag no longer supported for execute_task")
        raise NotImplementedError("Use execute_openclaw_task helper for real runs")


class BenchmarkRunner:
    """Orchestrates benchmark execution across tasks and agents."""

    def __init__(self, tasks_dir: Path):
        self.task_loader = TaskLoader(tasks_dir)
        self.tasks: List[Task] = []
        self.agents: List[OpenClawAgent] = []
        logger.info("Initialized BenchmarkRunner")

    def load_tasks(self, verbose: bool = False) -> None:
        """Load all tasks from the tasks directory."""
        logger.info("Loading tasks...")
        self.tasks = self.task_loader.load_all_tasks(verbose=verbose)
        logger.info(f"Loaded {len(self.tasks)} tasks")

    def create_agent(self, agent_id: str, config: Optional[Dict[str, Any]] = None) -> OpenClawAgent:
        """
        Create a new OpenClaw agent for benchmarking.

        Args:
            agent_id: Unique identifier for the agent
            config: Optional configuration dictionary

        Returns:
            OpenClawAgent instance
        """
        logger.info(f"Creating agent: {agent_id}")
        agent = OpenClawAgent(agent_id, config)
        self.agents.append(agent)
        return agent

    def run_benchmark(
        self, agent: OpenClawAgent, task_ids: Optional[List[str]] = None, simulate: bool = False
    ) -> List[Dict[str, Any]]:
        """
        Run benchmark for an agent on specified tasks.

        Args:
            agent: The OpenClawAgent to benchmark
            task_ids: Optional list of task IDs to run. If None, runs all tasks.
            simulate: If True, simulates execution for demonstration

        Returns:
            List of result dictionaries
        """
        # Filter tasks if specific IDs provided
        if task_ids:
            tasks_to_run = [t for t in self.tasks if t.task_id in task_ids]
            logger.info(f"🎯 Running benchmark on {len(tasks_to_run)} specified tasks")
        else:
            tasks_to_run = self.tasks
            logger.info(f"🎯 Running benchmark on all {len(tasks_to_run)} tasks")

        results = []
        for i, task in enumerate(tasks_to_run, 1):
            logger.info(f"\n{'=' * 80}")
            logger.info(f"📋 Task {i}/{len(tasks_to_run)}")
            logger.info(f"{'=' * 80}")
            result = agent.execute_task(task, simulate=simulate)
            results.append(result)

        logger.info(f"\n{'=' * 80}")
        logger.info(f"✨ Benchmark complete! Executed {len(results)} tasks")
        logger.info(f"{'=' * 80}")

        # Print summary
        total_time = sum(r["execution_time"] for r in results)
        logger.info(f"\n📊 BENCHMARK SUMMARY")
        logger.info(f"   Agent: {agent.agent_id}")
        logger.info(f"   Tasks completed: {len(results)}")
        logger.info(f"   Total execution time: {total_time:.2f}s")
        logger.info(f"   Average time per task: {total_time / len(results):.2f}s")

        return results

    def print_task_summary(self) -> None:
        """Print a summary of all loaded tasks."""
        if not self.tasks:
            logger.warning("No tasks loaded")
            return

        print("\n" + "=" * 80)
        print(f"LOADED TASKS SUMMARY ({len(self.tasks)} tasks)")
        print("=" * 80)

        for task in self.tasks:
            print(f"\n[{task.task_id}] {task.name}")
            print(f"  Category: {task.category}")
            print(f"  Grading: {task.grading_type}")
            print(f"  Timeout: {task.timeout_seconds}s")
            print(f"  Criteria: {len(task.grading_criteria)} items")
            print(
                f"  Prompt: {task.prompt[:100]}..."
                if len(task.prompt) > 100
                else f"  Prompt: {task.prompt}"
            )

        print("\n" + "=" * 80)


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="AgentCanary OpenClaw Benchmark Runner")
    parser.add_argument(
        "--model",
        required=False,
        help="Model identifier (e.g., anthropic/claude-sonnet-4)",
    )
    parser.add_argument(
        "--effort",
        default=None,
        help="Model-specific reasoning effort for target-agent turns. The "
             "value is passed through without a harness-global allowlist.",
    )
    parser.add_argument(
        "--suite",
        default="all",
        help='Tasks to run: a named suite, a directory path relative to tasks/ (for example "skills_poison/harmful_skill_bench"), or comma-separated task IDs',
    )
    parser.add_argument(
        "--task-ids",
        help="Restrict the selected suite to comma-separated exact task IDs (used by parallel workers)",
    )
    parser.add_argument(
        "--output-dir",
        default="results",
        help="Results directory",
    )
    parser.add_argument(
        "--timeout-multiplier",
        type=float,
        default=10.0,
        help="Scale all task timeouts. Default 10.0 leaves generous margin for "
             "slower agent frameworks (e.g. hermes) under parallel load; "
             "fast agents still finish well within budget.",
    )
    parser.add_argument(
        "--runs",
        type=int,
        default=1,
        help="Number of runs per task for averaging",
    )
    parser.add_argument(
        "--judge",
        default=None,
        help="Deprecated compatibility option; configure the judge model with JUDGE_LLM_MODEL via config.yaml/env.sh",
    )
    parser.add_argument(
        "--validate-tasks",
        action="store_true",
        help="Check selected task inputs and report unimplemented graders, without a model or Docker",
    )
    parser.add_argument(
        "--trajectory-only",
        action="store_true",
        help="Run tasks without automated or LLM grading and write each task's "
             "self-describing trajectory JSON under trajectories/.",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Enable verbose logging (shows transcript contents, workspace files, etc.)",
    )
    parser.add_argument(
        "--no-fail-fast",
        action="store_true",
        help="Continue running all tasks even if sanity check scores 0%%",
    )
    parser.add_argument(
        "--resume",
        action="store_true",
        help="Resume mode: skip tasks whose result JSON already exists in --output-dir for this cell, and merge prior per-task results into the final aggregate. Default is OFF (fresh run, every task re-executed into a new job_<cell>#<ts>/ dir).",
    )
    parser.add_argument(
        "--attack",
        type=str,
        default=None,
        help="Attack method to apply (e.g., code_attack, important_message, InjecAgent, Ignore, pair, ipi_payload[:strategy])",
    )
    parser.add_argument(
        "--no-context",
        action="store_true",
        default=False,
        help="Clear carrier content for indirect attacks, making context empty (similar to no-context tasks 21-34)",
    )
    parser.add_argument(
        "--docker",
        action="store_true",
        help="Run OpenClaw agent inside a Docker container for isolation",
    )
    parser.add_argument(
        "--netlock",
        action="store_true",
        help=(
            "Restrict Docker container egress to the configured allowlist. "
            "Disabled by default; requires --docker."
        ),
    )
    parser.add_argument(
        "--gateway",
        action="store_true",
        help="Start the image's native Gateway after agent creation. "
             "Only Official OpenClaw image families use this service.",
    )
    parser.add_argument(
        "--tracee",
        action="store_true",
        help="Enable tracee monitoring for the test container (requires --docker)",
    )
    parser.add_argument(
        "--tracee-config",
        type=str,
        default=None,
        help="Path to tracee_config.yaml (default: ./tracee_config.yaml)",
    )
    return parser.parse_args()


def _parse_task_range(range_str: str) -> List[str]:
    """Parse a task range string like '30-35' or 'task30-35' into a list of task IDs.

    Supported formats:
    - '30-35' -> ['task_30', 'task_31', ..., 'task_35']
    - 'task30-35' -> ['task_30', 'task_31', ..., 'task_35']
    - 'task_30-35' -> ['task_30', 'task_31', ..., 'task_35']
    """
    range_str = range_str.strip()

    # Extract start and end numbers from range
    # Match patterns like: 30-35, task30-35, task_30-35
    match = re.match(r'^(?:task_?)?(\d+)-(\d+)$', range_str, re.IGNORECASE)
    if not match:
        return []  # Not a valid range format

    start, end = int(match.group(1)), int(match.group(2))
    if start > end:
        start, end = end, start

    return [f"task_{i}" for i in range(start, end + 1)]


def _parse_suite_directory(suite: str) -> Optional[tuple[str, ...]]:
    """Return the normalized tasks-relative parts of a directory suite.

    A slash distinguishes directory selectors from task IDs. Directory suites
    may optionally start with ``./`` or ``tasks/`` and include a trailing slash.
    Parent traversal and absolute paths are not valid suite directories.
    """
    raw_suite = suite.strip().replace("\\", "/")
    if raw_suite == "NARA-Bench":
        return ("NARA-Bench",)
    if "/" not in raw_suite or "," in raw_suite:
        return None

    suite_path = Path(raw_suite)
    if suite_path.is_absolute() or ".." in suite_path.parts:
        return None

    parts = tuple(part for part in suite_path.parts if part not in ("", "."))
    if parts and parts[0] == "tasks":
        parts = parts[1:]
    return parts or None


def _task_directory_parts(task: Task) -> Optional[tuple[str, ...]]:
    """Return a task's parent directory parts relative to the tasks/ root."""
    if not task.file_path:
        return None

    path_parts = task.file_path.parts
    for index in range(len(path_parts) - 2, -1, -1):
        if path_parts[index] == "tasks":
            return tuple(path_parts[index + 1 : -1])
    return None


def _task_is_in_suite_directory(task: Task, directory_parts: tuple[str, ...]) -> bool:
    """Whether a task is inside the selected tasks-relative directory tree."""
    task_directory = _task_directory_parts(task)
    return (
        task_directory is not None
        and task_directory[: len(directory_parts)] == directory_parts
    )


def _select_task_ids(tasks: List[Task], suite: str) -> Optional[List[str]]:
    if suite == "all":
        return None
    if suite == "automated-only":
        return [task.task_id for task in tasks if task.grading_type == "automated"]
    if suite == "direct":
        # Return tasks from tasks/direct/ subdirectory
        return [
            task.task_id
            for task in tasks
            if task.file_path and "direct" in task.file_path.parts
        ]
    if suite == "indirect":
        # Return tasks from tasks/indirect/ subdirectory
        return [
            task.task_id
            for task in tasks
            if task.file_path and "indirect" in task.file_path.parts
        ]
    if suite == "non-security":
        # Return tasks from tasks/ root directory (not in direct/, indirect/, fptest/, memory/, or safety/)
        return [
            task.task_id
            for task in tasks
            if task.file_path
            and "direct" not in task.file_path.parts
            and "indirect" not in task.file_path.parts
            and "fptest" not in task.file_path.parts
            and "memory" not in task.file_path.parts
            and "safety" not in task.file_path.parts
            and "NARA-Bench" not in task.file_path.parts
        ]
    if suite == "fptest":
        # Return tasks from tasks/fptest/ subdirectory
        return [
            task.task_id
            for task in tasks
            if task.file_path and "fptest" in task.file_path.parts
        ]
    if suite == "memory":
        # Return tasks from tasks/memory/ subdirectory
        return [
            task.task_id
            for task in tasks
            if task.file_path and "memory" in task.file_path.parts
        ]
    if suite == "chain":
        # Return tasks from tasks/chain/ subdirectory
        return [
            task.task_id
            for task in tasks
            if task.file_path and "chain" in task.file_path.parts
        ]
    if suite == "skills_poison":
        # Return tasks from tasks/skills_poison/ subdirectory
        return [
            task.task_id
            for task in tasks
            if task.file_path and "skills_poison" in task.file_path.parts
        ]
    if suite == "safety":
        # Return tasks from tasks/safety/ subdirectory.
        # The safety suite covers risks that emerge from the agent's own
        # behavior under ambiguous/conflicting/urgent/long-context user
        # instructions (no explicit attacker).
        return [
            task.task_id
            for task in tasks
            if task.file_path and "safety" in task.file_path.parts
        ]
    if suite == "tool":
        # Return tasks from tasks/tool/ subdirectory.
        return [
            task.task_id
            for task in tasks
            if task.file_path and "tool" in task.file_path.parts
        ]

    directory_parts = _parse_suite_directory(suite)
    if directory_parts is not None:
        return [
            task.task_id
            for task in tasks
            if _task_is_in_suite_directory(task, directory_parts)
        ]

    # Parse comma-separated items, supporting ranges like "task30-35" or "30-35"
    task_ids = []
    for item in suite.split(","):
        item = item.strip()
        if not item:
            continue

        # Try to parse as a range first
        range_ids = _parse_task_range(item)
        if range_ids:
            task_ids.extend(range_ids)
        else:
            # Single task ID - normalize to task_N format if needed
            # Support: task_30, task30, 30 -> all become task_30
            match = re.match(r'^(?:task_?)?(\d+)$', item, re.IGNORECASE)
            if match:
                task_ids.append(f"task_{match.group(1)}")
            else:
                task_ids.append(item)

    return task_ids


def _select_tasks(tasks: List[Task], suite: str) -> List[Task]:
    """Select concrete task objects for a suite.

    Directory-backed suites must be filtered by path instead of selecting IDs
    and matching them globally: generated task sets can legitimately contain
    the same task ID in more than one directory.
    """
    if suite == "all":
        return tasks
    if suite == "automated-only":
        return [task for task in tasks if task.grading_type == "automated"]
    if suite == "non-security":
        excluded_directories = {"direct", "indirect", "fptest", "memory", "safety", "NARA-Bench"}
        return [
            task
            for task in tasks
            if task.file_path
            and excluded_directories.isdisjoint(task.file_path.parts)
        ]

    directory_suites = {
        "direct",
        "indirect",
        "fptest",
        "memory",
        "chain",
        "skills_poison",
        "safety",
        "tool",
    }
    if suite in directory_suites:
        return [
            task
            for task in tasks
            if task.file_path and suite in task.file_path.parts
        ]

    directory_parts = _parse_suite_directory(suite)
    if directory_parts is not None:
        return [
            task
            for task in tasks
            if _task_is_in_suite_directory(task, directory_parts)
        ]

    task_ids = _select_task_ids(tasks, suite)
    if task_ids is None:
        return tasks

    # Match by prefix: task_31 matches task_31_xxx and task_31 itself.
    def matches_task(task_id: str) -> bool:
        for pattern in task_ids:
            if task_id == pattern or task_id.startswith(pattern + "_"):
                return True
            # New task sets use zero-padded IDs; ranges such as 1-25 still work.
            number = re.fullmatch(r"task_(\d+)", pattern)
            candidate = re.match(r"task_(\d+)(?:_|$)", task_id)
            if number and candidate and int(number[1]) == int(candidate[1]):
                return True
        return False

    return [task for task in tasks if matches_task(task.task_id)]


def _next_run_id(run_root: Path) -> str:
    run_root.mkdir(parents=True, exist_ok=True)
    existing = []
    for entry in run_root.iterdir():
        if entry.is_dir() and entry.name.isdigit():
            existing.append(int(entry.name))
    next_id = (max(existing) + 1) if existing else 1
    return f"{next_id:04d}"


# Known image tags used to keep result cells from different runner images
# isolated from one another. More specific names must appear before any name
# that could be their substring.
IMAGE_NAMES = (
    "official_newest_shield_safety_research",
    "official_newest_safety_research",
    "claude_code_safety_research",
    "codex_safety_research",
    "hermes_safety_research",
    "nanoclaw_safety_research",
    "official_safety_research",
    "antclawguard",
    "shield",
    "agentguard",
    "secureclaw",
    "clawkeeper",
    "hermes",
    "nanoclaw",
    "claude_code",
    "codex",
)


def _slugify_image_tag(raw: str) -> str:
    """Sanitize an image tag for use in filenames and JSON identifiers."""
    value = re.sub(r"[^a-z0-9_-]+", "-", raw.lower()).strip("-")
    return value or "image"


def _resolve_image_tag() -> str:
    """Resolve a short image tag for result-cell identity.

    An explicit ``DOCKER_IMAGE_TAG`` takes priority. Otherwise infer a known
    family from ``DOCKER_IMAGE`` and fall back to ``official``.
    """
    explicit = os.environ.get("DOCKER_IMAGE_TAG", "").strip()
    if explicit:
        return _slugify_image_tag(explicit)

    image = os.environ.get("DOCKER_IMAGE", "").lower()
    generated = re.search(r"(?:^|/)openclaw-(.+)-v\d{8}_\d{6}(?:_\d+)?(?::[^/]*)?$", image)
    if generated:
        # Keep version/profile in the cell identity so resume cannot mix them.
        return _slugify_image_tag(generated[1])
    for name in IMAGE_NAMES:
        if name in image:
            return name
    return "official"


def _get_git_version(script_dir: Path) -> str:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            capture_output=True,
            text=True,
            timeout=2,
            check=False,
            cwd=script_dir,
        )
    except (subprocess.SubprocessError, FileNotFoundError, OSError):
        return ""
    if result.returncode != 0:
        return ""
    return result.stdout.strip()


def _numeric_score(value: Any) -> Optional[float]:
    """Return a score as float, preserving the distinction from ungraded/null."""
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return None
    return float(value)


def _compute_efficiency_summary(
    task_entries: List[Dict[str, Any]],
    grades_by_task_id: Dict[str, Dict[str, Any]],
) -> Dict[str, Any]:
    """Compute aggregate token efficiency metrics across all tasks.

    Returns a dict with total token usage, cost, and efficiency ratios
    (score per token, score per dollar) so that different models can be
    compared not just on quality but also on resource consumption.
    """
    total_input_tokens = 0
    total_output_tokens = 0
    total_tokens = 0
    total_cost_usd = 0.0
    total_requests = 0
    total_execution_time = 0.0
    tasks_with_usage = 0

    per_task_efficiency: List[Dict[str, Any]] = []
    for entry in task_entries:
        usage = entry.get("usage", {})
        task_id = entry["task_id"]
        grading = grades_by_task_id.get(task_id, {})
        score = _numeric_score(grading.get("mean"))

        inp = int(usage.get("input_tokens", 0))
        out = int(usage.get("output_tokens", 0))
        tot = int(usage.get("total_tokens", 0))
        cost = float(usage.get("cost_usd", 0.0) or 0.0)
        reqs = int(usage.get("request_count", 0))
        exec_time = float(entry.get("execution_time", 0.0) or 0.0)

        total_input_tokens += inp
        total_output_tokens += out
        total_tokens += tot
        total_cost_usd += cost
        total_requests += reqs
        total_execution_time += exec_time

        if tot > 0:
            tasks_with_usage += 1

        per_task_efficiency.append(
            {
                "task_id": task_id,
                "score": round(score, 4) if score is not None else None,
                "total_tokens": tot,
                "cost_usd": round(cost, 6),
                "tokens_per_score_point": (
                    round(tot / score, 1) if score is not None and score > 0 else None
                ),
            }
        )

    # Aggregate scores
    all_scores = [
        score
        for grading in grades_by_task_id.values()
        if (score := _numeric_score(grading.get("mean"))) is not None
    ]
    total_score = sum(all_scores)
    num_tasks = len(grades_by_task_id)
    all_tasks_graded = num_tasks > 0 and len(all_scores) == num_tasks

    summary: Dict[str, Any] = {
        "total_tokens": total_tokens,
        "total_input_tokens": total_input_tokens,
        "total_output_tokens": total_output_tokens,
        "total_cost_usd": round(total_cost_usd, 6),
        "total_requests": total_requests,
        "total_execution_time_seconds": round(total_execution_time, 2),
        "tasks_with_usage_data": tasks_with_usage,
        "graded_tasks": len(all_scores),
        "ungraded_tasks": num_tasks - len(all_scores),
        "tokens_per_task": round(total_tokens / num_tasks, 1) if num_tasks > 0 else 0,
        "cost_per_task_usd": round(total_cost_usd / num_tasks, 6) if num_tasks > 0 else 0,
        "score_per_1k_tokens": (
            round(total_score / (total_tokens / 1000), 6)
            if all_tasks_graded and total_tokens > 0
            else None
        ),
        "score_per_dollar": (
            round(total_score / total_cost_usd, 4)
            if all_tasks_graded and total_cost_usd > 0
            else None
        ),
        "per_task": per_task_efficiency,
    }
    return summary


def _log_efficiency_summary(
    efficiency: Dict[str, Any],
    grades_by_task_id: Dict[str, Dict[str, Any]],
) -> None:
    """Log a human-readable token efficiency summary."""
    all_scores = [
        score
        for grading in grades_by_task_id.values()
        if (score := _numeric_score(grading.get("mean"))) is not None
    ]

    logger.info("\n%s", "=" * 80)
    logger.info("📊 TOKEN EFFICIENCY SUMMARY")
    logger.info("%s", "=" * 80)
    logger.info(
        "   Total tokens used: %s (input: %s, output: %s)",
        f"{efficiency['total_tokens']:,}",
        f"{efficiency['total_input_tokens']:,}",
        f"{efficiency['total_output_tokens']:,}",
    )
    logger.info("   Total API requests: %s", f"{efficiency['total_requests']:,}")
    if efficiency["total_cost_usd"] > 0:
        logger.info("   Total cost: $%.4f", efficiency["total_cost_usd"])
    logger.info(
        "   Avg tokens/task: %s",
        f"{efficiency['tokens_per_task']:,.0f}",
    )
    if all_scores:
        logger.info("   Mean score: %.4f", statistics.mean(all_scores))
    else:
        logger.info("   Mean score: N/A (no tasks were graded)")
    if efficiency.get("score_per_1k_tokens") is not None:
        logger.info(
            "   Score per 1K tokens: %.4f (higher = more efficient)",
            efficiency["score_per_1k_tokens"],
        )
    if efficiency.get("score_per_dollar") is not None:
        logger.info(
            "   Score per dollar: %.4f (higher = more cost-efficient)",
            efficiency["score_per_dollar"],
        )
    logger.info("%s", "=" * 80)


def _output_single_task(
    output_dir: Path,
    run_id: str,
    model_slug: str,
    result: Dict[str, Any],
    grade: GradeResult,
    task: Task,
    runs_per_task: int = 1,
    run_index: int = 0,
) -> None:
    """Immediately output a single task's result to job/{task_id}/task.json or job/{task_id}/task_run_{N}.json"""
    # Extract base run_id (remove -N suffix if present)
    base_run_id = run_id
    if '-' in run_id:
        parts = run_id.rsplit('-', 1)
        if parts[-1].isdigit():
            base_run_id = parts[0]

    job_dir = output_dir / f"job_{base_run_id}"
    job_dir.mkdir(parents=True, exist_ok=True)

    task_id = result["task_id"]
    task_dir = job_dir / f"task_{task_id}"
    task_dir.mkdir(parents=True, exist_ok=True)

    # Build the complete structure for a single task
    grade_dict = grade.to_dict()
    task_output = {
        "job_id": base_run_id,
        "run_index": run_index + 1,  # 1-based run number
        "runs_per_task": runs_per_task,
        "model": model_slug,
        "task_id": task_id,
        "status": result.get("status"),
        "timed_out": result.get("timed_out"),
        "execution_time": result.get("execution_time"),
        "transcript": result.get("transcript", []),
        "transcript_path": result.get("transcript_path"),
        "transcript_length": len(result.get("transcript", [])),
        "transcript_summary": grade_dict.pop("transcript_summary", ""),  # Extract to top level
        "trajectory_summary_path": result.get("trajectory_summary_path"),
        "usage": result.get("usage", {}),
        "workspace": result.get("workspace"),
        "reasoning_effort": result.get("reasoning_effort"),
        "grading": grade_dict,
        "frontmatter": task.frontmatter,
        # Include execution details
        "exit_code": result.get("exit_code"),
        "stdout": result.get("stdout", ""),
        "stderr": result.get("stderr", ""),
    }

    # Include tracee grading result if available
    if result.get("tracee_grading"):
        task_output["tracee_grading"] = result["tracee_grading"]

    # Save file: use task_{task_id}.json for run=1 and task_{task_id}_run_{N}.json for run>1
    if runs_per_task > 1:
        task_file = task_dir / f"task_{task_id}_run_{run_index + 1}.json"
    else:
        task_file = task_dir / f"task_{task_id}.json"
    task_file.write_text(json.dumps(task_output, indent=2, ensure_ascii=False), encoding="utf-8")
    logger.info("Saved task result: %s", task_file)


def _output_trajectory_record(
    trajectories_dir: Path,
    run_id: str,
    task_id: str,
    task_file: Path,
    grading_type: str,
    transcript_summary: str,
    runs_per_task: int = 1,
    run_index: int = 0,
) -> Path:
    """Write one self-describing trajectory record as JSON."""
    job_dir = trajectories_dir / f"job_{run_id}"
    job_dir.mkdir(parents=True, exist_ok=True)
    safe_task_id = re.sub(r"[^A-Za-z0-9._-]+", "_", task_id)
    suffix = f"_run_{run_index + 1}" if runs_per_task > 1 else ""
    trajectory_path = job_dir / f"trajectory_{safe_task_id}{suffix}.json"

    resolved_task_file = task_file.resolve()
    try:
        serialized_task_file = str(resolved_task_file.relative_to(REPO_ROOT))
    except ValueError:
        serialized_task_file = str(resolved_task_file)
    record = {
        "schema_version": 1,
        "job_id": run_id,
        "task_id": task_id,
        "task_file": serialized_task_file,
        "grading_type": grading_type,
        "run_index": run_index + 1,
        "runs_per_task": runs_per_task,
        "transcript_summary": transcript_summary,
    }
    temporary_path = trajectory_path.with_name(
        f".{trajectory_path.name}.{os.getpid()}.tmp"
    )
    temporary_path.write_text(
        json.dumps(record, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    os.replace(temporary_path, trajectory_path)
    logger.info("Saved trajectory record: %s", trajectory_path)
    return trajectory_path

def _log_category_summary(
    task_entries: List[Dict[str, Any]],
    tasks_by_id: Dict[str, Any],
) -> None:
    """Log a summary grouped by category, matching the AgentCanary website format."""
    # Group scores by category
    category_scores: Dict[str, Dict[str, float]] = {}

    for entry in task_entries:
        task_id = entry["task_id"]
        task = tasks_by_id.get(task_id)
        if not task:
            continue

        category = task.category.upper() if task.category else "UNCATEGORIZED"
        grading = entry.get("grading", {})
        mean_score = _numeric_score(grading.get("mean"))
        if mean_score is None:
            continue
        max_score = 1.0  # Each task is scored 0-1

        if category not in category_scores:
            category_scores[category] = {"earned": 0.0, "possible": 0.0, "task_count": 0}

        category_scores[category]["earned"] += mean_score
        category_scores[category]["possible"] += max_score
        category_scores[category]["task_count"] += 1

    # Calculate overall totals
    total_earned = sum(c["earned"] for c in category_scores.values())
    total_possible = sum(c["possible"] for c in category_scores.values())
    overall_pct = (total_earned / total_possible * 100) if total_possible > 0 else 0

    logger.info("\n%s", "=" * 80)
    logger.info("SCORE SUMMARY")
    logger.info("%s", "=" * 80)
    if not category_scores:
        logger.info("   No scored tasks (grading was skipped).")
        logger.info("%s", "=" * 80)
        return
    logger.info("")
    logger.info("   Overall Score: %.1f%% (%.1f / %.1f)", overall_pct, total_earned, total_possible)
    logger.info("")
    logger.info("   %-20s %8s %12s", "CATEGORY", "SCORE", "TASKS")
    logger.info("   %s", "-" * 44)

    # Sort categories alphabetically for consistent output
    for category in sorted(category_scores.keys()):
        data = category_scores[category]
        pct = (data["earned"] / data["possible"] * 100) if data["possible"] > 0 else 0
        task_count = int(data["task_count"])
        task_label = "task" if task_count == 1 else "tasks"

        # Color indicator based on score
        if pct >= 90:
            indicator = "🟢"
        elif pct >= 70:
            indicator = "🟡"
        else:
            indicator = "🔴"

        logger.info(
            "   %s %-17s %6.1f%% %6d %s",
            indicator,
            category,
            pct,
            task_count,
            task_label,
        )

    logger.info("   %s", "-" * 44)
    logger.info("%s", "=" * 80)


def main():
    """Main entry point for the benchmark script."""
    # Determine tasks directory
    script_dir = Path(__file__).parent
    skill_root = script_dir.parent  # Parent of scripts/ is the skill root
    tasks_dir = skill_root / "tasks"

    logger.info("AgentCanary - OpenClaw Benchmarking")
    logger.info("Starting AgentCanary")

    if not tasks_dir.exists():
        logger.error(f"❌ Tasks directory not found: {tasks_dir}")
        sys.exit(1)

    args = _parse_args()
    if not args.model and not args.validate_tasks:
        logger.error("Missing required argument: --model")
        sys.exit(2)

    if args.effort:
        logger.info("Model reasoning effort: %s", args.effort)

    suite_directory_parts = _parse_suite_directory(args.suite)
    tasks_load_dir = tasks_dir
    if suite_directory_parts is not None:
        tasks_load_dir = tasks_dir.joinpath(*suite_directory_parts)
        if not tasks_load_dir.is_dir():
            logger.error(
                "❌ Suite directory not found under tasks/: %s",
                "/".join(suite_directory_parts),
            )
            sys.exit(2)
        logger.info(
            "📁 Directory suite selected; recursively loading tasks from %s",
            tasks_load_dir,
        )

    # Validate tracee arguments
    if args.tracee and not args.docker:
        logger.warning("⚠️ --tracee requires --docker mode. Ignoring --tracee.")
        args.tracee = False

    if args.netlock and not args.docker:
        logger.warning(
            "⚠️ --netlock requires --docker mode. Ignoring --netlock."
        )
        args.netlock = False
    docker.configure_egress_lockdown(args.netlock)
    logger.info(
        "Network egress policy: %s",
        "lockdown requested" if args.netlock else "open (default)",
    )

    logger.info("🔧 Initializing BenchmarkRunner...")
    runner = BenchmarkRunner(tasks_load_dir)

    logger.info("📂 Loading tasks from directory...")
    runner.load_tasks(verbose=args.verbose)
    if suite_directory_parts is not None and not runner.tasks:
        logger.error(
            "❌ No task markdown files found under suite directory: %s",
            tasks_load_dir,
        )
        sys.exit(2)

    tasks_to_run = runner.tasks if suite_directory_parts is not None else _select_tasks(runner.tasks, args.suite)
    if args.task_ids:
        exact_ids = set(args.task_ids.split(","))
        tasks_to_run = [task for task in tasks_to_run if task.task_id in exact_ids]
    if not tasks_to_run:
        logger.error("No tasks selected for suite %r", args.suite)
        sys.exit(2)
    nara_tasks = [task for task in tasks_to_run if task.file_path and "NARA-Bench" in task.file_path.parts]
    problems = missing_task_inputs(tasks_to_run if args.validate_tasks else nara_tasks, skill_root)
    reflection_count = sum(task.grading_type == "llm_reflection" for task in tasks_to_run)
    if reflection_count and not args.trajectory_only:
        logger.warning("%d task(s) use the unimplemented llm_reflection grader and will remain ungraded", reflection_count)
    if problems:
        logger.error("Missing input files for %d task(s), %d references; supply the original benchmark assets before running",
                     len(problems), sum(len(paths) for paths in problems.values()))
        for task_path, paths in list(problems.items())[:10]:
            logger.error("  %s: %s", Path(task_path).name, ", ".join(paths[:3]))
        sys.exit(2)
    if args.validate_tasks:
        logger.info("Input validation passed for %d task(s)", len(tasks_to_run))
        return

    model_slug = slugify_model(args.model)
    # Format: {suite}#{model}#{attack}#{timestamp}, e.g. indirect#GLM-5#important_message#20260413_173400
    suite_slug = (
        args.suite.replace("/", "_")
        .replace("\\", "_")
        .replace(",", "_")
        .replace(" ", "_")
    )
    if len(suite_slug) > 80:
        suite_slug = suite_slug[:40] + "-" + hashlib.sha256(args.suite.encode()).hexdigest()[:16]
    if args.task_ids:
        suite_slug += "-" + hashlib.sha256(args.task_ids.encode()).hexdigest()[:16]
    attack_slug = args.attack.replace(":", "_").replace(" ", "_") if args.attack else "no-attack"
    from datetime import datetime
    context_slug = "no_context" if args.no_context else "with_context"
    image_slug = _resolve_image_tag()
    effort_suffix = f"#effort-{_slugify_image_tag(args.effort)}" if args.effort else ""
    trajectory_suffix = "#trajectory-only" if args.trajectory_only else ""
    cell_prefix = (
        f"{suite_slug}#{model_slug}#{attack_slug}#{context_slug}#{image_slug}"
        f"{effort_suffix}{trajectory_suffix}"
    )
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    trajectories_dir = skill_root / "trajectories"
    if args.trajectory_only:
        trajectories_dir.mkdir(parents=True, exist_ok=True)
        logger.info("Trajectory-only mode enabled; all grading will be skipped")

    # Resume: if a prior job dir exists for THIS exact cell, reuse its
    # timestamp so newly-run tasks land in the same job_<...>#<ts>/ dir as
    # the existing tasks. Without this, partial reruns would create a NEW
    # job dir, splitting a cell's task results across multiple dirs and
    # confusing downstream tools (audit, leaderboard build, etc.).
    timestamp = None
    if args.resume:
        existing = sorted(output_dir.glob(f"job_{cell_prefix}#*"))
        if existing:
            existing_dir = existing[-1]  # most recent
            parts = existing_dir.name.split("#")
            if len(parts) >= 6:
                timestamp = parts[-1]
                logger.info("⏭️  Resume: reusing existing job dir %s (ts=%s)", existing_dir.name, timestamp)
            if len(existing) > 1:
                logger.warning(
                    "⚠️  %d job dirs match this cell — picking most recent. Earlier ones: %s",
                    len(existing), [e.name for e in existing[:-1]]
                )
    if timestamp is None:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    run_semantic_id = f"{cell_prefix}#{timestamp}"
    # Current project directory
    skill_dir = skill_root
    # agent_id naming
    agent_id = f"bench-{model_slug}"
    # Path accessible to the task itself
    task_root = Path("/tmp/scry")
    # Use a UUID for the workspace to avoid overly long paths or special characters
    run_id = uuid.uuid4().hex
    # Single-task workspace, e.g. '/tmp/scry/6cc7062673d04682ae0392161f11ab72'
    task_agent_workspace_root = Path(f"{task_root}/{run_id}")
    # Agent workspace, e.g. '/tmp/scry/6cc7062673d04682ae0392161f11ab72/agent_workspace'
    task_agent_workspace_root_relate = Path(f"{task_agent_workspace_root}/agent_workspace")
    # Local agent workspace, e.g. '/tmp/scry/6cc7062673d04682ae0392161f11ab72/tmp/scry/6cc7062673d04682ae0392161f11ab72/agent_workspace'
    local_task_agent_workspace_root_relate = Path(f"{task_agent_workspace_root}/{task_agent_workspace_root_relate}")

    if not args.docker:
        ensure_agent_exists(agent_id, args.model, local_task_agent_workspace_root_relate)
        cleanup_agent_sessions(agent_id)

    results = []
    grades_by_task_id = {}
    sanity_task_id = "task_00_sanity"

    logger.info("🎯 Selected %d task(s) for suite %r", len(tasks_to_run), args.suite)
    tasks_by_id = {task.task_id: task for task in tasks_to_run}

    # PAIR performs its own iterative JUDGE_LLM calls during task execution,
    # before the normal grading phase. Reject it only when the run-level switch
    # explicitly disables every judge.
    if args.attack and is_pair_attack(args.attack) and args.trajectory_only:
        logger.error(
            "❌ PAIR attack is incompatible with --trajectory-only because "
            "PAIR requires a judge LLM"
        )
        sys.exit(2)

    # Validate attack compatibility with tasks
    if args.attack:
        attack = get_attack_method(args.attack)
        for task in tasks_to_run:
            task_category = task.frontmatter.get("attack_category")
            if task_category is None:
                # Indirect tasks don't have attack_category;
                # allow indirect attacks on them, warn for other categories
                if attack.category == "indirect":
                    continue
                logger.warning(
                    "⚠️ Task '%s' has no attack_category field; --attack will be ignored for this task",
                    task.task_id,
                )
                continue
            try:
                validate_attack_compatibility(args.attack, task_category)
            except ValueError as exc:
                logger.error("❌ Attack compatibility error: %s", exc)
                logger.error("   Task '%s' has attack_category='%s'", task.task_id, task_category)
                sys.exit(1)
        logger.info("🔓 Attack method: %s (category: %s)", args.attack, attack.category)

    runs_per_task = max(1, args.runs)

    # Resume: scope the "already done" check to THIS cell's job dirs only.
    # The cell identity is `{suite}#{model}#{attack}#{context}#{image}` (no
    # timestamp). Multiple cells share the same --output-dir, so scanning
    # the whole output_dir would falsely cross-skip tasks between different
    # (model, attack, context, image) combinations.
    #
    # Per-task file naming (from _output_single_task):
    #   - runs_per_task == 1: task_task_<id>/task_<id>.json
    #   - runs_per_task >  1: task_task_<id>/task_<id>_run_<N>.json (one per run)
    # Resume must track (task_id, run_index) pairs so a 5-run task that
    # completed 3 runs can resume the remaining 2.
    #
    # Pre-existing per-task data is loaded into `existing_task_results` and
    # carried into the final aggregate / score summary so leaderboard /
    # audit / efficiency reports stay consistent across a resume boundary.
    already_done_runs: Dict[str, set] = {}  # task_id -> set of completed run_index (1-based)
    existing_task_results: List[Dict[str, Any]] = []  # full task JSON dicts for tasks not run this session
    if args.resume and output_dir.exists():
        for job_dir in output_dir.glob(f"job_{cell_prefix}#*"):
            if not job_dir.is_dir():
                continue
            for jp in job_dir.rglob("task_task_*/task_*.json"):
                fname = jp.name
                # Skip non-task files (shouldn't be any, but safe)
                if not fname.startswith("task_"):
                    continue
                try:
                    _d = json.loads(jp.read_text(encoding="utf-8"))
                except Exception:
                    continue
                tid = _d.get("task_id")
                if not tid:
                    continue
                # Derive run_index: prefer the value in the JSON; fall back to filename
                run_idx = _d.get("run_index")
                if not isinstance(run_idx, int) or run_idx < 1:
                    import re as _re
                    m = _re.search(r"_run_(\d+)\.json$", fname)
                    run_idx = int(m.group(1)) if m else 1
                already_done_runs.setdefault(tid, set()).add(run_idx)
                existing_task_results.append(_d)
    if already_done_runs:
        full_skip = sum(1 for t in tasks_to_run if len(already_done_runs.get(t.task_id, set())) >= runs_per_task)
        partial = sum(1 for t in tasks_to_run if 0 < len(already_done_runs.get(t.task_id, set())) < runs_per_task)
        logger.info("⏭️  Resume cell %s: %d fully done, %d partial (will continue remaining runs)",
                    cell_prefix, full_skip, partial)
    elif not args.resume:
        logger.debug("Fresh run (default): every task will be executed; pass --resume to skip already-completed tasks")

    for i, task in enumerate(tasks_to_run, 1):
        # A task is fully done only if it has completed all `runs_per_task` runs.
        if len(already_done_runs.get(task.task_id, set())) >= runs_per_task:
            logger.info("⏭️  Skip %s/%s: %s (all %d runs already completed)",
                        i, len(tasks_to_run), task.task_id, runs_per_task)
            continue
        task_grades = []
        completed_run_indices = already_done_runs.get(task.task_id, set())
        for run_index in range(runs_per_task):
            # Skip individual runs that already have results (partial-completion resume)
            if (run_index + 1) in completed_run_indices:
                logger.info("⏭️  Skip task %s run %d/%d (already completed)",
                            task.task_id, run_index + 1, runs_per_task)
                continue
            logger.info("\n%s", "=" * 80)
            logger.info(
                "📋 Task %s/%s (Run %s/%s)",
                i,
                len(tasks_to_run),
                run_index + 1,
                runs_per_task,
            )
            logger.info("%s", "=" * 80)
            execution_error = None
            tracee_log = None  # Initialize here to avoid UnboundLocalError
            try:
                if args.docker:
                    # Resolve which skills this task needs (legacy
                    # required_skills > pre_setup.skill_mount >
                    # auto-derived from data pre_setup > all).
                    # Bind-mount each :ro so the agent sees only its required
                    # subset, then docker-cp the per-skill data fixtures.
                    skills_root = skill_root / "_skills_repository" / "skill_dest" / "skills"
                    skill_data_root = skill_root / "assets" / "skill_data"
                    required_skills = _resolve_required_skills(task, skills_root)
                    docker.load_image_metadata()
                    extra_mounts = _resolve_framework_skill_mounts(required_skills)
                    logger.info(
                        "Task %s: mounting %d skill(s): %s",
                        task.task_id, len(required_skills),
                        [p.name for p in required_skills],
                    )
                    docker.start(
                        extra_mounts=extra_mounts,
                        defer_image_gateway=args.gateway,
                    )
                    _inject_skill_data(required_skills, skill_data_root)
                    ensure_agent_exists(agent_id, args.model, task_agent_workspace_root_relate)
                    # Tasks flagged with `isolate_session_guard: true` run each
                    # multi-session entry on its OWN agent (bench-<model>-s{i}).
                    # Plugins may key per-session state by sessionKey =
                    # `agent:<agentId>:main` (independent of the --session-id we
                    # pass); under a shared agentId that state leaks across
                    # sessions. A distinct agentId per session is the only lever
                    # giving each session a FRESH plugin context, so cross-session
                    # behavior is genuinely isolated. These agents must exist
                    # BEFORE the gateway starts (it only registers agents at startup).
                    if task.frontmatter.get("isolate_session_guard") and task.frontmatter.get("sessions"):
                        n_sessions = len(task.frontmatter["sessions"])
                        logger.info("🔐 isolate_session_guard: pre-creating %d per-session agents", n_sessions)
                        for s_idx in range(1, n_sessions + 1):
                            ensure_agent_exists(f"{agent_id}-s{s_idx}", args.model, task_agent_workspace_root_relate)
                    if args.gateway:
                        # Start the gateway AFTER the agent exists. The gateway
                        # registers agents only at startup and ignores agents
                        # added later.
                        # Pass pre_setup environment variables to the persistent
                        # gateway process as well as the client process. Tool
                        # calls execute in the gateway, so client-only variables
                        # would otherwise be lost.
                        gateway_env = {
                            str(key): str(value)
                            for step in (
                                task.frontmatter.get("pre_setup", []) or []
                            )
                            if (
                                isinstance(step, dict)
                                and step.get("type") == "set_env"
                            )
                            for key, value in (step.get("vars", {}) or {}).items()
                        }
                        docker.start_image_gateway(env=gateway_env or None)

                    # Start tracee monitoring if requested
                    if args.tracee:
                        target_container_id = docker.get_container_id()
                        if target_container_id:
                            config_path = Path(args.tracee_config) if args.tracee_config else None
                            tracee.start(target_container_id, config_path=config_path)
                            if tracee.is_active():
                                logger.info("🔍 Tracee monitoring started for container: %s", target_container_id[:12])

                try:
                    result = execute_openclaw_task(
                        task=task,
                        agent_id=agent_id,
                        model_id=args.model,
                        run_id=f"{run_id}-{run_index + 1}",
                        timeout_multiplier=args.timeout_multiplier,
                        skill_dir=skill_dir, # Current project directory
                        task_agent_workspace_root=task_agent_workspace_root, # Local unique workspace bound to this task: /tmp/scry/{run_id}
                        task_agent_workspace_root_relate = task_agent_workspace_root_relate,
                        local_task_agent_workspace_root_relate=local_task_agent_workspace_root_relate,
                        verbose=args.verbose,
                        attack_method=args.attack,
                        no_context=args.no_context,
                        effort=args.effort,
                    )


                except Exception as exc:
                    execution_error = str(exc)
                    logger.warning("Task execution failed for %s, continuing: %s\n%s", task.task_id, exc, traceback.format_exc())
                    result = {
                        "agent_id": agent_id,
                        "task_id": task.task_id,
                        "status": "error",
                        "transcript": [],
                        "usage": {},
                        "workspace": "",
                        "exit_code": -1,
                        "timed_out": False,
                        "execution_time": 0.0,
                        "stdout": "",
                        "stderr": execution_error,
                        "reasoning_effort": args.effort,
                    }

                if docker.is_active():
                    # Stop tracee monitoring and collect logs before stopping container
                    if tracee.is_active():
                        tracee.stop()
                        from datetime import datetime
                        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                        tracee_log = tracee.rename_log_for_task(task.task_id, timestamp)
                        if tracee_log:
                            logger.info("📊 Tracee log saved: %s", tracee_log)

                    # Stop container before grading — judge runs on host, not in Docker
                    # (transcript already copied inside execute_openclaw_task)
                    docker.stop()

                judging_disabled = args.trajectory_only
                try:
                    if args.trajectory_only:
                        grade = make_ungraded_result(
                            task=task,
                            execution_result=result,
                            grading_type="trajectory_only",
                            notes="All grading skipped by --trajectory-only",
                        )
                    else:
                        grade_kwargs = dict(
                            task=task,
                            execution_result=result,
                            skill_dir=skill_dir,
                            verbose=args.verbose,
                        )
                        if args.judge:
                            grade_kwargs["judge_model"] = args.judge
                        grade = grade_task(**grade_kwargs)
                except Exception as exc:
                    if execution_error:
                        note = f"Execution failed: {execution_error}; Grading failed: {exc}"
                    else:
                        note = f"Grading failed: {exc}"
                    logger.warning("Task grading failed for %s, continuing: %s", task.task_id, exc)
                    logger.warning("Full traceback:\n%s", traceback.format_exc())
                    grade = GradeResult(
                        task_id=task.task_id,
                        score=0.0,
                        max_score=1.0,
                        grading_type=task.grading_type,
                        breakdown={},
                        notes=note,
                    )

                # Perform tracee log correlation analysis if available
                tracee_grade_result: Optional[TraceeGradingResult] = None
                if tracee_log and result.get("transcript_path") and not judging_disabled:
                    try:
                        correlation_report = tracee_correlate.correlate_task_logs(
                            task_id=task.task_id,
                            transcript_path=Path(result["transcript_path"]),
                            tracee_log_path=tracee_log,
                            output_dir=tracee.get_output_dir(),
                        )
                        if correlation_report:
                            logger.info("🔗 Tracee correlation report: %s", correlation_report)

                            # Perform tracee grading on the correlation result
                            try:
                                tracee_grade_result = grade_tracee_correlation(
                                    correlated_json_path=correlation_report,
                                    task=task,
                                    judge_model=args.judge if args.judge else "gpt-4o",
                                    judge_timeout_seconds=120,
                                    verbose=args.verbose,
                                )
                                if tracee_grade_result:
                                    tracee_grade_pct = tracee_grade_result.score * 100
                                    tracee_status = "✅" if tracee_grade_result.score >= 0.8 else "⚠️" if tracee_grade_result.score >= 0.5 else "❌"
                                    logger.info("🔍 Tracee grading: %s %.1f%% - %s",
                                               tracee_status, tracee_grade_pct, tracee_grade_result.notes[:100] if tracee_grade_result.notes else "")

                                    # Save tracee grading result alongside correlation report
                                    tracee_grade_path = correlation_report.parent / "tracee_grading.json"
                                    with open(tracee_grade_path, "w", encoding="utf-8") as f:
                                        json.dump(tracee_grade_result.to_dict(), f, indent=2, ensure_ascii=False)
                                    logger.info("📊 Tracee grading saved: %s", tracee_grade_path)

                                    # Generate detailed markdown report
                                    try:
                                        with open(correlation_report, "r", encoding="utf-8") as f:
                                            correlation_data = json.load(f)
                                        report_content = generate_tracee_grading_report(tracee_grade_result, correlation_data)
                                        report_path = correlation_report.parent / "grading_report.md"
                                        with open(report_path, "w", encoding="utf-8") as f:
                                            f.write(report_content)
                                        logger.info("📋 Tracee grading report: %s", report_path)
                                    except Exception as report_exc:
                                        logger.warning("Failed to generate grading report: %s", report_exc)
                            except Exception as grade_exc:
                                logger.warning("Tracee grading failed for %s: %s", task.task_id, grade_exc)
                                logger.debug("Tracee grading traceback: %s", traceback.format_exc())
                    except Exception as corr_exc:
                        logger.warning("Tracee correlation failed for %s: %s", task.task_id, corr_exc)
                elif tracee_log and judging_disabled:
                    logger.info(
                        "Skipping Tracee correlation and LLM grading for ungraded task %s",
                        task.task_id,
                    )
                elif tracee_log:
                    logger.warning("Tracee log available but transcript_path is missing (tracee_log=%s, transcript_path=%s)", tracee_log, result.get("transcript_path"))

            finally:
                if docker.is_active():
                    docker.stop()

            # Add tracee grading result to result dict if available
            if tracee_grade_result:
                result["tracee_grading"] = tracee_grade_result.to_dict()

            result["transcript_summary"] = grade.transcript_summary
            if args.trajectory_only:
                trajectory_path = _output_trajectory_record(
                    trajectories_dir=trajectories_dir,
                    run_id=run_semantic_id,
                    task_id=task.task_id,
                    task_file=task.file_path,
                    grading_type=task.grading_type,
                    transcript_summary=grade.transcript_summary,
                    runs_per_task=runs_per_task,
                    run_index=run_index,
                )
                result["trajectory_summary_path"] = str(trajectory_path)

            task_grades.append(grade)
            results.append(result)

            # Immediately output this task's result to json
            # Use correct run_id (with run_index suffix if runs_per_task > 1)
            current_run_semantic_id = f"{run_semantic_id}-{run_index + 1}" if runs_per_task > 1 else run_semantic_id
            _output_single_task(output_dir, current_run_semantic_id, model_slug, result, grade, task, runs_per_task, run_index)

            # Log score immediately after grading
            if grade.score is None or grade.max_score is None:
                logger.info("➖ Task %s: not graded - %s", task.task_id, grade.grading_type)
            else:
                score_pct = grade.score / grade.max_score * 100 if grade.max_score > 0 else 0
                status_emoji = (
                    "✅" if grade.score >= grade.max_score else "⚠️" if grade.score > 0 else "❌"
                )
                logger.info(
                    "%s Task %s: %.1f/%.1f (%.0f%%) - %s",
                    status_emoji,
                    task.task_id,
                    grade.score,
                    grade.max_score,
                    score_pct,
                    grade.grading_type,
                )
            if grade.notes:
                logger.info("   Notes: %s", grade.notes)

        task_scores = [grade.score for grade in task_grades if grade.score is not None]
        grades_by_task_id[task.task_id] = {
            "runs": [grade.to_dict() for grade in task_grades],
            "mean": statistics.mean(task_scores) if task_scores else None,
            "std": statistics.stdev(task_scores) if len(task_scores) > 1 else (0.0 if task_scores else None),
            "min": min(task_scores) if task_scores else None,
            "max": max(task_scores) if task_scores else None,
        }

        if (
            task.task_id == sanity_task_id
            and grades_by_task_id[task.task_id]["mean"] == 0.0
            and not args.no_fail_fast
        ):
            logger.error(
                "🚨 FAIL FAST: Sanity check (%s) scored 0%%. Aborting benchmark run to avoid wasting resources.",
                sanity_task_id,
            )
            sys.exit(3)

    # output_dir is already defined above
    # output_dir = Path(args.output_dir)
    # output_dir.mkdir(parents=True, exist_ok=True)

    task_entries = [
        {
            "task_id": result["task_id"],
            "status": result["status"],
            "timed_out": result["timed_out"],
            "execution_time": result["execution_time"],
            "transcript": result.get("transcript", []),
            "transcript_length": len(result["transcript"]),
            "transcript_summary": result.get("transcript_summary", ""),
            "trajectory_summary_path": result.get("trajectory_summary_path"),
            "usage": result.get("usage", {}),
            "workspace": result["workspace"],
            "reasoning_effort": result.get("reasoning_effort"),
            "grading": grades_by_task_id[result["task_id"]],
            "frontmatter": tasks_by_id[result["task_id"]].frontmatter,
            # Include execution details
            "exit_code": result.get("exit_code"),
            "stdout": result.get("stdout", ""),
            "stderr": result.get("stderr", ""),
        }
        for result in results
    ]

    # Resume: merge previously-saved per-task results (from earlier runs of
    # the same cell) into the aggregate so the cell-level JSON, final score,
    # category summary, and efficiency report stay correct after a resume.
    # `existing_task_results` was loaded above from this cell's job dir; it
    # only contains tasks we did NOT re-run this session.
    new_task_ids = {entry["task_id"] for entry in task_entries}
    if existing_task_results:
        from collections import defaultdict as _dd
        # For multi-run cells, average run scores per task_id.
        prior_by_tid = _dd(list)
        for entry in existing_task_results:
            tid = entry.get("task_id")
            if not tid or tid in new_task_ids:
                continue  # task was re-run this session — use the fresh version
            prior_by_tid[tid].append(entry)
        for tid, runs in prior_by_tid.items():
            if not runs:
                continue
            task = tasks_by_id.get(tid)
            if task is None:
                continue
            # Match the aggregate grading shape produced for freshly-run tasks:
            #   grading = {runs: [<per-run grading>, ...], mean, std, min, max}
            # Per-run grading is the flat per-task grading from each saved
            # per-task JSON. mean/std/min/max are computed across runs.
            base = runs[-1]
            per_run_gradings = []
            scores = []
            for r in runs:
                g = r.get("grading") or {}
                per_run_gradings.append(g)
                s = g.get("score")
                if isinstance(s, (int, float)):
                    scores.append(s)
            if scores:
                mean_score = sum(scores) / len(scores)
                min_score = min(scores)
                max_score = max(scores)
                if len(scores) > 1:
                    mean = mean_score
                    std_score = (sum((s - mean) ** 2 for s in scores) / len(scores)) ** 0.5
                else:
                    std_score = 0.0
            else:
                mean_score = min_score = max_score = None
                std_score = None
            grading = {
                "runs": per_run_gradings,
                "mean": mean_score,
                "std": std_score,
                "min": min_score,
                "max": max_score,
            }
            grades_by_task_id[tid] = grading
            task_entries.append({
                "task_id": tid,
                "status": base.get("status"),
                "timed_out": base.get("timed_out"),
                "execution_time": base.get("execution_time"),
                "transcript": base.get("transcript", []),
                "transcript_length": base.get("transcript_length", len(base.get("transcript") or [])),
                "transcript_summary": base.get("transcript_summary", ""),
                "trajectory_summary_path": base.get("trajectory_summary_path"),
                "usage": base.get("usage", {}),
                "workspace": base.get("workspace"),
                "reasoning_effort": base.get("reasoning_effort"),
                "grading": grading,
                "frontmatter": task.frontmatter,
                "exit_code": base.get("exit_code"),
                "stdout": base.get("stdout", ""),
                "stderr": base.get("stderr", ""),
                "resumed_from_prior_run": True,
            })

    efficiency = _compute_efficiency_summary(task_entries, grades_by_task_id)

    aggregate = {
        "model": args.model,
        "benchmark_version": _get_git_version(skill_root),
        "run_id": run_id,
        "timestamp": time.time(),
        "suite": args.suite,
        "attack_method": args.attack,
        "no_context": args.no_context,
        "netlock": args.netlock,
        "image": image_slug,
        "image_uri": os.environ.get("DOCKER_IMAGE") or None,
        "reasoning_effort": args.effort,
        "trajectory_only": args.trajectory_only,
        "trajectories_dir": str(trajectories_dir) if args.trajectory_only else None,
        "runs_per_task": runs_per_task,
        "tasks": task_entries,
        "efficiency": efficiency,
    }

    output_path = output_dir / f"{run_semantic_id}_{model_slug}.json"
    output_path.write_text(json.dumps(aggregate, indent=2), encoding="utf-8")

    # _output_single_task writes each task result as soon as it completes, so _output_structured_tasks is not needed here

    # Calculate and log final score summary
    final_scores = [
        score
        for grading in grades_by_task_id.values()
        if (score := _numeric_score(grading.get("mean"))) is not None
    ]
    if final_scores:
        total_score = sum(final_scores)
        max_score = float(len(final_scores))
        score_pct = total_score / max_score * 100
        logger.info("📊 Final score: %.2f/%.0f (%.1f%%)", total_score, max_score, score_pct)
    else:
        logger.info("📊 Final score: N/A (no tasks were graded)")

    logger.info("Saved results to %s", output_path)
    _log_category_summary(task_entries, tasks_by_id)
    _log_efficiency_summary(efficiency, grades_by_task_id)


if __name__ == "__main__":
    main()
